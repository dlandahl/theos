
Acpi_Mcfg :: struct {
    using header: Acpi_Table_Header;
    reserved: u64 #align 4;
}

find_all_pci_devices :: () {
    mcfg := cast(*Acpi_Mcfg) find_acpi_table("MCFG");
    if !mcfg {
        log_error("ACPI MCFG table not found.");
        bluescreen();
    }

    total_length := mcfg.length;
    ecam_base := cast(u64) mcfg + size_of(Acpi_Mcfg);
    ecam_length_bytes := total_length - size_of(Acpi_Mcfg);

    Ecam_Entry :: struct {
        base_address: u64;
        segment_group: u16;
        start_bus: u8;
        end_bus: u8;
        reserved: u32;
    }

    ecam: [] Ecam_Entry;
    ecam.data = cast(*Ecam_Entry) ecam_base;
    ecam.count = ecam_length_bytes / size_of(Ecam_Entry);

    for ecam {
        for bus: it.start_bus..it.end_bus {
            for device: 0..255 {
                header := read_configuration_space(it.base_address, bus, device, 0);
                if !header continue;

                array_add(*pci_devices, .{header});

                if header.header_type & 0x80 == 0 {
                    // Device is not multi-function.
                    continue;
                }

                for function: 1..7 {
                    header = read_configuration_space(it.base_address, bus, device, function);
                    array_add(*pci_devices, .{header});
                }
            }
        }
    }
}

pci_devices: [..] Pci_Device;

Pci_Device :: union {
    using configuration_space: *Pci_Configuration_Space;
    registers: *u32;
};

read_configuration_space :: (base_address: u64, bus: int, device: int, function: int) -> *Pci_Configuration_Space {
    device_offset := cast(u64, bus * 256 + device * 8 + function);
    address := base_address + device_offset * PCI_CONFIGURATION_SPACE_SIZE;

    header := cast(*Pci_Configuration_Space, address + DIRECT_MAPPING_BASE);

    if header.vendor_id == PCI_VENDOR_ID_NO_DEVICE {
        return null;
    }

    if header.class_code == .UNCLASSIFIED {
        return null;
    }

    return header;
}

Pci_Configuration_Space :: struct {
    vendor_id:       u16;
    device_id:       u16;
    status:          u16;
    command:         u16;
    revision_id:     u8;
    prog_if:         u8;
    subclass:        u8;
    class_code:      Pci_Class_Code;
    cache_line_size: u8;
    latency_timer:   u8;
    header_type:     u8;
    bist:            u8;
}

PCI_VENDOR_ID_NO_DEVICE :: 0xffff;
PCI_CONFIGURATION_SPACE_SIZE :: 4096;

Pci_Bar :: struct {
    base: u64;
    limit: u32;
}

read_base_address_register :: (device: Pci_Device, bar_index: int) -> Pci_Bar {
    bar := device.registers[0x4 + bar_index];

    if bar & 0b001 {
        log_error("IO-space base address registers are not supported. Device: %", device.configuration_space.*);
        bluescreen();
    }

    _64bit := cast(bool, bar & 0b100);

    mask: u64 = 0xfffffff0;
    base: u64 = bar & mask;

    if _64bit {
        bar1 := device.registers[0x4 + bar_index + 1];
        base |= bar1 << 32;
    }

    device.registers[0x4 + bar_index] = 0xffffffff;
    limit := device.registers[0x4 + bar_index];

    device.registers[0x4 + bar_index] = bar;

    limit = cast(u32) ~(limit & mask) + 1;
    return .{base, limit};
}

map_base_address_register :: (bar: Pci_Bar) -> *void {
    using Page_Flags;
    uncacheable_flags := READ_WRITE | PRESENT | CACHE_DISABLE;

    if bar.base & 0xfff {
        // Doesn't currently handle BARs with unaligned base addresses.
        bluescreen();
    }

    virtual := alloc_block(*kernel_globals.virtual_block_allocator, bar.limit);

    for 0..(bar.limit-1) / 4096 {
        offset := it * 4096;
        map_page(virtual + offset, bar.base + offset, uncacheable_flags);
    }

    return cast(*void) virtual;
}




Ahci_Controller :: struct {
    command_list: [] Ahci_Command_Header;
    command_table: [32] *Ahci_Command_Table;

    received_fis: *Ahci_Received_Fis;
    port: *Ahci_Port;
}

init_ahci_controller :: (device: Pci_Device) -> Ahci_Controller {
    device.registers[1] |= cast(u32) Pci_Command.BUS_MASTER | .MEMORY_SPACE;

    bar := read_base_address_register(device, bar_index = 5);
    if !bar.base {
        log_error("AHCI controller has no base address set");
        return .{};
    }

    ahci := cast(*Ahci_Memory_Region) map_base_address_register(bar);

    ahci.GHC__global_host_control |= .AE__ahci_enable;

    if ahci.CAP__host_capabilities & .S64A__64bit_addressing == 0 {
        log_error("AHCI controller without 64-bit addressing not supported");
        return .{};
    }

    if (ahci.CAP__host_capabilities & .SAM__supports_ahci_only) == 0 {
        ahci.GHC__global_host_control |= .HR__hba_reset;
    }

    // Todo bitfield
    num_ports          := cast(int,  ahci.CAP__host_capabilities       & 0b11111) + 1;
    command_slot_count := cast(int, (ahci.CAP__host_capabilities >> 8) & 0b11111) + 1;

    max_ports := 32;

    for 0..max_ports-1 {
        if ahci.PI__ports_implemented & (1 << it) == 0 {
            continue;
        }

        port := *ahci.ports[it];

        if ahci_port_is_running(port) {
            port.CMD__command_status &= ~.ST__start;
            Timeout(#code {
                if port.CMD__command_status & .CR__command_list_running == 0 break;
            }, "AHCI port not idle timeout (command list running)");

            port.CMD__command_status &= ~.FRE__fis_receive_enable;
            Timeout(#code {
                if port.CMD__command_status & .FR__receive_running == 0 break;
            }, "AHCI port not idle timeout (receive running)");
        }
    }

    for 0..max_ports - 1 {
        if ahci.PI__ports_implemented & (1 << it) == 0 continue;

        port := *ahci.ports[it];
        if port.CMD__command_status & .SUD__spin_up_device == 0 {
            log_error("AHCI port not spun up");
            return .{};
        }

        // if ahci.CAP__host_capabilities & .STAGGERED_SPIN_UP > 0 {
        // }

        detection := port.SSTS__sata_status & .DET_MASK;
        if detection != .DET_ESTABLISHED continue;

        ipm := port.SSTS__sata_status & .IPM_MASK;
        if ipm != .IPM_ACTIVE {
            log_error("AHCI port power management interface state is not active. See 3.3.10 (PxSSTS)");
            return .{};
        }

        if port.SIG__signature != .ATA {
            log_error("AHCI We only handle the \"ATA\" device signature");
            return .{};
        }

        // Need a better allocator for cache-disabled memory
        list_size := align(4096, size_of(Ahci_Command_Header) * command_slot_count);
        fis_size  := align(4096, size_of(Ahci_Received_Fis));

        memory_needed := cast(u64, list_size + fis_size + command_slot_count * 4096 + 4096);

        using kernel_globals;
        virtual  := cast(*void) alloc_block(*virtual_block_allocator,  memory_needed);
        physical :=             alloc_block(*physical_block_allocator, memory_needed);

        // The virtual memory gets aligned by the allocator
        physical = xx align(4096, xx physical);

        page_flags := Page_Flags.READ_WRITE | .PRESENT | .CACHE_DISABLE;
        pages_needed := memory_needed / 4096;

        for 0..pages_needed-1 {
            offset := cast(u64) it * 4096;
            map_page(virtual + offset, physical + offset, page_flags);
        }

        controller: Ahci_Controller;
        controller.command_list.count = command_slot_count;

        controller.command_list.data = virtual;
        controller.received_fis      = virtual + list_size;

        port.CLB__command_list_base  = physical;
        port.FB__fis_base            = physical + cast(u64) list_size;

        controller.port = port;

        for *controller.command_list {
            offset := list_size + fis_size + it_index * 4096;
            controller.command_table[it_index] = virtual + offset;

            it.CTBA__command_table_base = physical + cast(u64) offset;
        }


        port.CMD__command_status |= .FRE__fis_receive_enable;

        Timeout(#code {
            if port.CMD__command_status.FR__receive_running break;
        }, "AHCI port idle timeout (receive running)");


        port.CMD__command_status |= .ST__start;

        Timeout(#code {
            if port.CMD__command_status.CR__command_list_running break;
        }, "AHCI port idle timeout (command list running)");

        return controller;
    }

    bluescreen();
    return .{};
}

ahci_port_is_running :: (port: *Ahci_Port) -> bool {
    return (port.CMD__command_status & .ST__start)
        || (port.CMD__command_status & .CR__command_list_running)
        || (port.CMD__command_status & .FRE__fis_receive_enable)
        || (port.CMD__command_status & .FR__receive_running);
}

Transfer_Direction :: enum {
    READ;
    WRITE;
}

ahci_transfer :: (controller: *Ahci_Controller, direction: Transfer_Direction, memory_address: u64, number_of_bytes: u64, disk_address: u64) {
    assert(cast(u64) memory_address % 0x200 == 0);

    sector_count : u64 = (number_of_bytes + 0x1ff) / 0x200;
    lba          : u64 = (disk_address    + 0x1ff) / 0x200;

    if sector_count == 0 return;

    // DMA hardware does not support memory accesses that cross a 64k boundary in physical memory.
    // This code splits the operation into 64k blocks.

    first_sector_count := (0x1_0000 - memory_address % 0x1_0000) / 0x200;
    if first_sector_count > sector_count first_sector_count = sector_count;
    sector_count -= first_sector_count;

    ahci_transfer_sectors(controller, direction, memory_address, cast(u32) lba, xx first_sector_count);
    lba += first_sector_count;
    memory_address += first_sector_count * 0x200;

    while sector_count > 128 {
        ahci_transfer_sectors(controller, direction, memory_address, cast(u32) lba, 128);
        memory_address += 0x1_0000;
        lba += 128;
        sector_count -= 128;
    }

    if sector_count {
        ahci_transfer_sectors(controller, direction, memory_address, xx lba, xx sector_count);
    }
}

ahci_transfer_sectors :: (controller: *Ahci_Controller, direction: Transfer_Direction, physical: u64, lba: u64, sector_count: int) {
    fis: Ahci_Command_Fis;
    fis.flags = .IS_COMMAND;
    fis.command = ifx direction == .READ then Ata_Command.READ_DMA_EX else .WRITE_DMA_EX;
    fis.device = 1 << 6; // Todo magic number

    fis.sectors_low  = cast(u8, sector_count);
    fis.sectors_high = cast(u8, sector_count >> 8);

    fis.lba_0 = cast(u8, lba);
    fis.lba_1 = cast(u8, lba >> 8);
    fis.lba_2 = cast(u8, lba >> 16);
    fis.lba_3 = cast(u8, lba >> 24);
    fis.lba_4 = cast(u8, lba >> 32);
    fis.lba_5 = cast(u8, lba >> 40);

    table := controller.command_table[0];
    table.CFIS__command_fis = fis;

    // Todo: This driver uses only one physical region at a time, in one command list entry at a time, on one port.
    // It needs to be generalised to access drives on any port, and should dynamically allocate command lists that
    // contain more physical region descriptors, to reduce software overhead of disk access.
    controller.command_list[0].PRDTL__prd_table_length = 1;
    controller.command_list[0].PRDBC__prd_byte_count = size_of(Ahci_Physical_Region_Descriptor);
    controller.command_list[0].flags = size_of(Ahci_Command_Fis) / 4;

    if direction == .WRITE {
        controller.command_list[0].flags |= 0x40; // Todo magic number
    }

    prdt := *table.PRDT__physical_region_descriptor_table[0];
    prdt.DBA__data_base_address = physical;
    prdt.DBC__data_byte_count = cast(u32) sector_count * 0x200 - 1;
    // prdt.I__interrupt_on_completion = .NO;

    Timeout(#code {
        if controller.port.SACT__sata_active & 1 > 0 continue;

        ata_status := cast(u32, Ata_Status.BUSY | .TRANSFER_REQUESTED);

        if controller.port.TFD__task_file_data & ata_status > 0 {
            continue;
        }

        break;
    }, "SATA busy timeout");

    assert(controller.port.CI__command_issue & 1 == 0);
    controller.port.CI__command_issue |= 1;

    Timeout(#code {
        if !(controller.port.CI__command_issue & 1) break;
    }, "SATA command issue timeout");
}

Ata_Command :: enum u8 {
    READ_PIO  :: 0x20;
    READ_DMA  :: 0xc8;
    READ_DMA_EX :: 0x25;
    WRITE_PIO :: 0x30;
    WRITE_DMA :: 0xca;
    WRITE_DMA_EX :: 0x35;
    IDENTIFY  :: 0xec;
}

Ata_Status :: enum_flags u8 {
    NONE                :: 0x0;
    ERROR               :: 0x1;
    INDEX               :: 0x2;
    CORRECTED_DATA      :: 0x4;
    TRANSFER_REQUESTED  :: 0x8;
    SEEK_COMPLETE       :: 0x10;
    DEVICE_FAULT        :: 0x20;
    READY               :: 0x40;
    BUSY                :: 0x80;
}

Ahci_Command_Header :: struct {
    flags: u16;
    PRDTL__prd_table_length: u16;
    PRDBC__prd_byte_count: u32;
    CTBA__command_table_base: u64;

    reserved: [4] u32;
}

Ahci_Command_Table :: struct {
    CFIS__command_fis:   Ahci_Command_Fis;
    RSV0__reserved:      [44] u8;
    ACMD__atapi_command: [16] u8;
    RSV1__reserved:      [48] u8;

    PRDT__physical_region_descriptor_table: [1] Ahci_Physical_Region_Descriptor;
}

Ahci_Physical_Region_Descriptor :: struct {
    DBA__data_base_address: u64;
    reserved: u32;
    DBC__data_byte_count: u32;

#place DBC__data_byte_count;
    I__interrupt_on_completion: enum u32 { NO; YES :: 0x8000_0000; };
}

Fis_Type :: enum u8 {
    INVALID      :: 0x0;
    REGISTER_H2D :: 0x27;
    REGISTER_D2H :: 0x34;
    DMA_ACTIVATE :: 0x39;
    DMA_SETUP    :: 0x41;
    DATA         :: 0x46;
    BIST         :: 0x58;
    PIO_SETUP    :: 0x5f;
    DEV_BITS     :: 0xa1;
}

Ahci_Received_Fis :: struct {
    DSFIS__dma_setup: [32] u8;
    PSFIS__pio_setup: [32] u8;
    RFIS__d2h_register: Ahci_Command_Fis = .{ fis_type = .REGISTER_D2H };
    SDBFIS__set_device_bits: u64;
    UFIS__unknown: [64] u8;

    reserved: [96] u8;
}

Ahci_Command_Fis :: struct {
    fis_type := Fis_Type.REGISTER_H2D;
    flags: enum u8 { NONE :: 0x0; IS_COMMAND :: 0x80; };
    command: Ata_Command;
    features0: u8;

    lba_0: u8;
    lba_1: u8;
    lba_2: u8;
    device: u8;

    lba_3: u8;
    lba_4: u8;
    lba_5: u8;
    features1: u8;

    sectors_low: u8;
    sectors_high: u8;
    icc: u8;
    control: u8;

    reserved: u32;
}

Ahci_Memory_Region :: struct {
    CAP__host_capabilities:            HBA_CAP__Ahci_Capabilities;
    GHC__global_host_control:          HBA_GHC__Ahci_Global_Host_Control;
    IS__interrupt_status:              u32;
    PI__ports_implemented:             u32;
    VS__version:                       u32;
    CCC_CTL__cmd_coalescing_control:   u32;
    CCC_PTS__cmd_coalescing_ports:     u32;
    EM_LOC__enclosure_mgmt_location:   u32;
    EM_CTL__enclosure_mgmt_control:    u32;
    CAP2__extended_host_capabilities:  u32;
    BOHC__bios_handoff_control:        u32;

    reserved:                          [116] u8;
    vendor_specific:                   [96] u8;

    ports:                             [32] Ahci_Port;
}

Ahci_Port :: struct {
    CLB__command_list_base:    u64 #align 4;
    FB__fis_base:              u64 #align 4;
    IS__interrupt_status:      u32;
    IE__interrupt_enable:      u32;
    CMD__command_status:       HBA_PxCMD__Ahci_Port_Command_Status;
    RSV0__reserved:            u32;
    TFD__task_file_data:       u32;
    SIG__signature:            HBA_PxSIG__Ahci_Port_Signature;
    SSTS__sata_status:         HBA_PxSSTS__Ahci_Port_Status;
    SCTL__sata_control:        u32;
    SERR__sata_error:          u32;
    SACT__sata_active:         u32;
    CI__command_issue:         u32;
    SNTF__sata_notif:          u32;
    FBS__fis_based_switching:  u32;
    DEVSLP__device_sleep:      u32;
    
    RSV1__reserved:            [40] u8;
    vendor_specific:           [16] u8;
}

#assert size_of(Ahci_Received_Fis)     == 0x100;
#assert size_of(Ahci_Command_Header)   == 0x20;
#assert size_of(Ahci_Command_Table)    == 0x80 + size_of(Ahci_Physical_Region_Descriptor);
#assert size_of(Ahci_Port)             == 0x80;

HBA_GHC__Ahci_Global_Host_Control :: enum_flags u32 {
    HR__hba_reset                      :: 0x1;
    IE__interrrupt_enable              :: 0x2;
    MSRM__msi_revert_to_single_message :: 0x4;
    AE__ahci_enable                    :: 0x8000_0000;
}

HBA_CAP__Ahci_Capabilities :: enum_flags u32 {
    SAM__supports_ahci_only :: 0x4_0000;
    S64A__64bit_addressing  :: 0x8000_0000;
}

HBA_PxSSTS__Ahci_Port_Status :: enum u32 {
    DET_ESTABLISHED :: 0x3;
    IPM_ACTIVE      :: 0x100;

    DET_MASK   :: 0b0000_0000_1111;
    SPD_MASK   :: 0b0000_1111_0000;
    IPM_MASK   :: 0b1111_0000_0000;
}

HBA_PxCMD__Ahci_Port_Command_Status :: enum_flags u32 {
    ST__start                 :: 0x1;
    SUD__spin_up_device       :: 0x2;
    FRE__fis_receive_enable   :: 0x10;
    FR__receive_running       :: 0x4000;
    CR__command_list_running  :: 0x8000;
}

HBA_PxSIG__Ahci_Port_Signature :: enum u32 {
    ATA   :: 0x0000_0101;
    ATAPI :: 0xeb14_0101;
    SEMB  :: 0xc33c_0101;
    PM    :: 0x9669_0101;
}



Pci_Class_Code :: enum u8 {
    UNCLASSIFIED             :: 0x0;
    MASS_STORAGE             :: 0x1;
    NETWORK                  :: 0x2;
    DISPLAY_DEVICE           :: 0x3;
    MULTIMEDIA               :: 0x4;
    MEMORY_CONTROLLER        :: 0x5;
    BRIDGE                   :: 0x6;
    COMMUNICATION            :: 0x7;
    SYSTEM_PERIPHERAL        :: 0x8;
    INPUT_DEVICE             :: 0x9;
    DOCKING_STATION          :: 0xa;
    PROCESSOR                :: 0xb;
    SERIAL_BUS               :: 0xc;
    WIRELESS_CONTROLLER      :: 0xd;
}

Pci_Command :: enum_flags u16 {
    IO_SPACE                    :: 1 << 0;
    MEMORY_SPACE                :: 1 << 1;
    BUS_MASTER                  :: 1 << 2;
    SPECIAL_CYCLES              :: 1 << 3;
    MEMORY_WRITE_AND_INVALIDATE :: 1 << 4;
    VGA_PALETTE_SNOOP           :: 1 << 5;
    PARITY_ERROR_RESPONSE       :: 1 << 6;
    S_ERR_ENABLE                :: 1 << 8;
    FAST_BACK_TO_BACK_ENABLE    :: 1 << 9;
    INTERRUPT_DISABLE           :: 1 << 10;
}

PCI_SUBCLASSES :: ([] string).[
    .[
        "Non VGA Compatible Unclassified",
        "VGA Compatible Unclassified"
    ],
    .[
        "SCSI Bus Controller",
        "IDE Controller",
        "Floppy Disk Controller",
        "IPI Bus Controller",
        "RAID Controller",
        "ATA Controller",
        "Serial ATA Controller",
        "Serial Attached SCSI Controller",
        "Non-Volatile Memory Controller",
    ],
    .[
        "Ethernet Controller",
        "Token Ring Controller",
        "FFDI Controller",
        "ATM Controller",
        "ISDN Controller",
        "WorldFip Controller",
        "PICMG 2.14 Multi Computing Controller",
        "Infiniband Controller",
        "Fabric Controller",
    ],
    .[
        "VGA Compatible Controller",
        "XGA Controller",
        "3D Controller",
    ],
    .[
        "Multimedia Video Controller",
        "Multimedia Audio Controller",
        "Computer Telephony Device",
        "Audio Device",
    ],
    .[
        "RAM Controller",
        "Flash Controller",
    ],
    .[
        "Host Bridge",
        "ISA Bridge",
        "EISA Bridge",
        "MCA Bridge",
        "PCI-to-PCI Bridge",
        "PCMCIA Bridge",
        "NuBus Bridge",
        "CardBus Bridge",
        "RACEway Bridge",
        "PCI-to-PCI Bridge (Semi Transparent)",
        "InfiniBand-to-PCI Host Bridge",
    ],
    .[
        "Serial Controller",
        "Parallel Controller",
        "Multiport Serial Controller",
        "Modem",
        "IEEE 488.1/2 (GPIB) Controller",
        "Smart Card Controller",
    ],
    .[
        "Programmable Interrupt Controller",
        "DMA Controller",
        "Timer",
        "RTC Controller",
        "PCI Hot-Plug Controller",
        "SD Host Controller",
        "IOMMU",
    ],
    .[
        "Keyboard Controller",
        "Digitizer Pen",
        "Mouse Controller",
        "Scanner Controller",
        "Gameport Controller",
    ],
    .[
        "Generic",
    ],
    .[
        "386 Processor",
        "486 Processor",
        "Pentium",
        "Pentium Pro",
    ],
    .[
        "FireWire (IEEE 1394) Controller",
        "ACCESS Bus Controller",
        "SSA",
        "USB Controller",
        "Fibre Channel",
        "SMBus Controller",
        "InfiniBand Controller",
        "IPMI Interface",
        "SERCOS Interface (IEC 61491)",
        "CANbus Controller",
    ],
    .[
        "iRDA Compatible Controller",
        "Consumer IR Controller",
        "RF Controller",
        "Bluetooth Controller",
        "Broadband Controller",
        "Ethernet Controller (802.1a)",
        "Ethernet Controller (802.1b)",
    ],
    .[
        "I20",
    ],
    .[
        "Satellite TV Controller",
        "Satellite Audio Controller",
        "Satellite Voice Controller",
        "Satellite Data Controller",
    ],
    .[
        "Network and Computing Encryption/Decryption",
    ],
    .[
        "DPIO Modules",
        "Performance Counters",
    ],
];
