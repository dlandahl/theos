
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

                new_device := array_add(*pci_devices);
                new_device.configuration_space = header;

                if header.header_type & 0x80 == 0 {
                    // Device is not multi-function.
                    continue;
                }

                for function: 1..7 {
                    header = read_configuration_space(it.base_address, bus, device, function);

                    new_device := array_add(*pci_devices);
                    new_device.configuration_space = header;
                }
            }
        }
    }
}

pci_devices: [..] Pci_Device;

Pci_Device :: struct {
    using configuration_space: *Pci_Configuration_Space;

#place configuration_space;
    registers: *u32;

    union {
        msi: *Pci_Capability_Msi;
        msi64: *Pci_Capability_Msi64;
    }

    msi_64bit_address: bool;
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
    start_marker: void;

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

#place start_marker;
    offset: [0x34] u8;
    capability_pointer: u32;
}

Pci_Capability :: struct {
    id: enum u8 {
        NULL;
        POWER_MANAGEMENT_INTERFACE;
        ACCELERATED_GRAPHICS_PORT;
        VITAL_PRODUCT_DATA;
        SLOT_ID;
        MESSAGE_SIGNALLED_INTERRUPT;

        // More of these IDs listed at https://pcisig.com/sites/default/files/files/PCI_Code-ID_r_1_11__v24_Jan_2019.pdf
    };

    next: u8;
}

Msi_Control_Flags :: enum_flags u16 {
    ENABLE  :: 0x1;
    _64_BIT :: 0x80;
}

Pci_Capability_Msi :: struct {
    #as cap: Pci_Capability;

    control: Msi_Control_Flags;
    address: u32;
    data: u16;
}

Pci_Capability_Msi64 :: struct {
    #as cap: Pci_Capability;

    control: Msi_Control_Flags;
    address: u64 #align 1;
    data: u16;
}

parse_pci_capability_list :: (device: *Pci_Device) {
    capability: *Pci_Capability = cast(*void) device.configuration_space + device.capability_pointer;

    while true {
        log("Found capability %.", capability.id);

        if capability.id == .MESSAGE_SIGNALLED_INTERRUPT {
            device.msi = cast(*Pci_Capability_Msi) capability;
            device.msi_64bit_address = device.msi.control & ._64_BIT > 0;
        }

        if !capability.next {
            break;
        }

        capability = cast(*void) device.configuration_space + capability.next;
    }
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
    ahci: *Ahci_Memory_Region;
}

#program_export
ahci_interrupt :: (data: *void) {
    write_string("Handling AHCI Interrupt.\n");
} @InterruptRoutine

init_ahci_controller :: (device: Pci_Device) -> c: Ahci_Controller = .{}, success: bool {
    device.registers[1] |= cast(u32) Pci_Command.BUS_MASTER | .MEMORY_SPACE;
    device.registers[1] &= cast(u32) ~Pci_Command.INTERRUPT_DISABLE;

    parse_pci_capability_list(*device);

    if device.msi {
        gate := allocate_interrupt_gate();
        register_interrupt_gate(int__ahci_interrupt, gate);

        write_string("Device has MSI.\n");

        device.msi.control |= .ENABLE;
        device.msi.address = 0xfee0_0000;

        // core := get_current_core();
        // device.msi.address |= core.local_apic_id << 12;

        if device.msi.control & ._64_BIT {
            device.msi64.data = xx gate;
        } else {
            device.msi.data = xx gate;
        }
    }

    bar := read_base_address_register(device, bar_index = 5);
    if !bar.base {
        log_error("AHCI controller has no base address set");
        return success = false;
    }

    ahci := cast(*Ahci_Memory_Region) map_base_address_register(bar);

    log("Interrupt status is %.\n", ahci.IS__interrupt_status);

    ahci.GHC__global_host_control |= .AE__ahci_enable | .IE__interrupt_enable;

    if !(ahci.CAP__host_capabilities & .S64A__64bit_addressing) {
        log_error("AHCI controller without 64-bit addressing not supported");
        return success = false;
    }

    if !(ahci.CAP__host_capabilities & .SAM__supports_ahci_only) {
        ahci.GHC__global_host_control |= .HR__hba_reset;
    }

    // Todo bitfield
    num_ports          := cast(int,  ahci.CAP__host_capabilities       & 0b11111) + 1;
    command_slot_count := cast(int, (ahci.CAP__host_capabilities >> 8) & 0b11111) + 1;

    max_ports := 32;

    for 0..max_ports-1 {
        if !(ahci.PI__ports_implemented & (1 << it)) {
            continue;
        }

        port := *ahci.ports[it];

        if ahci_port_is_running(port) {
            port.CMD__command_status &= ~.ST__start;

            Timeout(
                !(port.CMD__command_status & .CR__command_list_running),
                "AHCI port not idle timeout (command list running)"
            );

            port.CMD__command_status &= ~.FRE__fis_receive_enable;

            Timeout(
                !(port.CMD__command_status & .FR__receive_running),
                "AHCI port not idle timeout (receive running)"
            );
        }
    }

    for 0..max_ports - 1 {
        if !(ahci.PI__ports_implemented & (1 << it)) continue;

        port := *ahci.ports[it];
        if !(port.CMD__command_status & .SUD__spin_up_device) {
            log_error("AHCI port not spun up");
            return success = false;
        }

        // if ahci.CAP__host_capabilities & .STAGGERED_SPIN_UP {
        // }

        detection := port.SSTS__sata_status & .DET_MASK;
        if detection != .DET_ESTABLISHED continue;

        ipm := port.SSTS__sata_status & .IPM_MASK;
        if ipm != .IPM_ACTIVE {
            log_error("AHCI port power management interface state is not active. See 3.3.10 (PxSSTS)");
            return success = false;
        }

        if port.SIG__signature != .ATA {
            log_error("AHCI We only handle the \"ATA\" device signature");
            return success = false;
        }

        log("Interrupt status (port) is %.\n", port.IS__interrupt_status);

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

        for* controller.command_list {
            offset := list_size + fis_size + it_index * 4096;
            controller.command_table[it_index] = virtual + offset;

            it.CTBA__command_table_base = physical + cast(u64) offset;
        }

        port.IE__interrupt_enable |= 1 << 5;

        port.CMD__command_status |= .FRE__fis_receive_enable;

        Timeout(
            port.CMD__command_status & .FR__receive_running,
            "AHCI port idle timeout (receive running)"
        );

        port.CMD__command_status |= .ST__start;

        Timeout(
            port.CMD__command_status & .CR__command_list_running,
            "AHCI port idle timeout (command list running)"
        );

        controller.ahci = ahci;
        return controller, true;
    }

    bluescreen();
    return success = false;
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
    controller.command_list[0].PRDBC__prd_byte_count = 0;
    controller.command_list[0].flags = size_of(Ahci_Command_Fis) / 4;

    if direction == .WRITE {
        controller.command_list[0].flags |= .WRITE;
    }

    prdt := *table.PRDT__physical_region_descriptor_table[0];
    prdt.DBA__data_base_address = physical;
    prdt.DBC__data_byte_count = cast(u16) sector_count * 0x200 - 1;
    prdt.I__interrupt_on_completion = .YES;

    context.print_style.default_format_int.base = 16;
    log("PRDT: %\n", prdt.*);

    Timeout_Block(#code {
        if controller.port.SACT__sata_active & 1 continue;

        ata_status := cast(u32, Ata_Status.BUSY | .TRANSFER_REQUESTED);

        if controller.port.TFD__task_file_data & ata_status {
            continue;
        }

        break;
    }, "SATA busy timeout");

    assert(!(controller.port.CI__command_issue & 1));
    controller.port.CI__command_issue |= 1;

    Timeout(
        !(controller.port.CI__command_issue & 1),
        "SATA command issue timeout"
    );


    for 1..1_000_000 #asm { pause; }

    log("(Transfer) Interrupt status is %.\n", controller.ahci.IS__interrupt_status);
    log("(Transfer) Interrupt status (port) is %.\n", controller.port.IS__interrupt_status);

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
    flags: enum u16 {
        WRITE :: 0x40;
    }

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
    DBC__data_byte_count: u16;

// #place DBC__data_byte_count;
    I__interrupt_on_completion: enum u16 { NO; YES :: 0x8000; };
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
    IE__interrupt_enable               :: 0x2;
    MRSM__msi_revert_to_single_message :: 0x4;
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





Nvme_Controller :: struct {
    using mmio: *Nvme_Property_Memory_Map;

    admin_submission_queue_tail: int;
    admin_submission_queue: [] Nvme_Submission_Queue_Entry;
}

Nvme_Property_Memory_Map :: struct {
    start_marker: void;

    CAP__capabilities:            Nvme_Controller_Capabilities;
    VS__version:                  Nvme_Specification_Version_Descriptor;
    INTMS:                        u32;
    INTMC:                        u32;
    CC__controller_config:        Nvme_Controller_Configuration;
    __reserved__:                 u32;
    CSTS__controller_status:      Nvme_Controller_Status;
    NSSR:                         u32;
    AQA__admin_queue_attributes:  Nvme_Admin_Queue_Attributes;
    ASQ__admin_submission_queue:  u64;
    ACQ__admin_completion_queue:  u64;

    // Would be nice to be able to give a constant to #place
#place start_marker;
    offset_for_transport_specific_properties: [0x1000] u8;

    SQ0TDBL__submission_queue_0_tail_doorbell: u32;
    CQ0HDBL__completion_queue_0_head_doorbell: u32;
}

Nvme_Controller_Capabilities :: enum u64 {
    MQES__maximum_queue_entries          :: 16;
    CQR__contiguous_queue_entries        :: 1;
    AMS__arbitration_mechanism_supported :: 2;
    __reserved__                         :: 5;
    TO__timeout                          :: 8;
    DSTRD__doorbell_stride               :: 4;
    NSSRS__nvm_subsystem_reset           :: 1;
    NCSS__nvm_command_set_support        :: 1;
    __reserved__2                        :: 5;
    IOCSS__io_command_set_support        :: 1;
    NOIOCSS__no_io_command_set_support   :: 1;

    BPS    :: 1;
    CPS    :: 2;
    MPSMIN :: 4;
    MPSMAX :: 4;
    PMRS   :: 1;
    CMBS   :: 1;
    NSSS   :: 1;
    CRMS   :: 2;
    NSSES  :: 1;
    __reserved__3 :: 2;
} @Bitfield

Nvme_Specification_Version_Descriptor :: struct {
    ter__teritary: u8;
    mnr__minor:    u8;
    mjr__major:    u16;
}

Nvme_Controller_Configuration :: enum u32 {
    EN__enable                   :: 1;
    __reserved__                 :: 3;
    CSS__io_command_set          :: 3;
    MPS__memory_page_size        :: 4;
    AMS__arbitration_mechanism   :: 3;

    __rest_of_the_bits :: 18;
} @Bitfield

Nvme_Controller_Status :: enum_flags u32 {
    RDY__READY :: 0x1;
}

Nvme_Admin_Queue_Attributes :: struct {
    ASQS__submission_queue_size: u16;
    ACQS__completion_queue_size: u16;
}

Nvme_Submission_Queue_Entry :: struct {
    OPC__opcode: Nvme_Admin_Opcode;
    FUSE_and_PSDT: u8;
    CID__command_identifier: u16;
    NSID__namespace_identifier: u32;

    CDW2__command_dword_2: u32;
    CDW3__command_dword_3: u32;

    MPTR__metadata_pointer: u64;
    DPTR__data_pointer:     [2] u64;

    union {
        CDW__command_dwords_10_to_15: [6] u32;

        // For IDENTIFY commands:
        CNS__controller_or_namespace: Nvme_Controller_Or_Namespace_Structure;
    }
}

Nvme_Admin_Opcode :: enum u8 {
    DELETE_IO_SUBMISSION_QUEUE :: 0x0;
    CREATE_IO_SUBMISSION_QUEUE :: 0x1;
    GET_LOG_PAGE               :: 0x2;
    DELETE_IO_COMPLETION_QUEUE :: 0x4;
    CREATE_IO_COMPLETION_QUEUE :: 0x5;
    IDENTIFY                   :: 0x6;
    ABORT                      :: 0x8;
}

Nvme_Controller_Or_Namespace_Structure :: enum u8 {
    IDENTIFY_NAMESPACE       :: 0x0;
    IDENTIFY_CONTROLLER      :: 0x1;
    ACTIVE_NAMESPACE_ID_LIST :: 0x2;
}

Nvme_Identify_Controller_Structure :: struct {
    VID__pci_vendor_id: u16;
    SSVID__pci_subsystem_vendor_id: u16;
    SN__serial_number: [20] u8;
    MN__model_number:  [40] u8;
}

#assert size_of(Nvme_Submission_Queue_Entry) == 64;

init_nvme_controller :: (device: Pci_Device) -> Nvme_Controller {
    if device.class_code != .MASS_STORAGE bluescreen();
    if device.subclass   != 0x8           bluescreen();

    device.registers[1] |= cast(u32) Pci_Command.BUS_MASTER | .MEMORY_SPACE;
    device.registers[1] &= cast(u32) ~Pci_Command.INTERRUPT_DISABLE;

    nvme: Nvme_Controller;

    bar := read_base_address_register(device, bar_index = 0);
    nvme.mmio = map_base_address_register(bar);


    // Reset the controller.
    ready :: nvme => nvme.CSTS__controller_status & .RDY__READY;

    if ready(nvme) {
        set(*nvme.CC__controller_config, .EN__enable, 0);
        Timeout(!ready(nvme), "NVMe reset timeout (RDY is set.)");
    }

    // Initialize admin queues.
    admin_sq := get_4k_page();
    admin_cq := get_4k_page();

    // Subtract one, because the field is zero based.
    queue_size := 4096 / size_of(Nvme_Submission_Queue_Entry) - 1;

    // Don't write these fields individually, since 16-bit access is not necessarily supported on 32-bit registers.
    nvme.AQA__admin_queue_attributes = .{
        cast(u16) queue_size,
        cast(u16) queue_size
    };

    nvme.ASQ__admin_submission_queue = admin_sq;
    nvme.ACQ__admin_completion_queue = admin_cq;

    nvme.admin_submission_queue.data = cast(*Nvme_Submission_Queue_Entry, admin_sq + DIRECT_MAPPING_BASE);
    nvme.admin_submission_queue.count = queue_size;

    NOIOCSS := get(nvme.CAP__capabilities, .NOIOCSS__no_io_command_set_support);
    IOCSS   := get(nvme.CAP__capabilities, .IOCSS__io_command_set_support);
    NCSS    := get(nvme.CAP__capabilities, .NCSS__nvm_command_set_support);

    if NOIOCSS        set(*nvme.CC__controller_config, .CSS__io_command_set, 0b111);
    if IOCSS          set(*nvme.CC__controller_config, .CSS__io_command_set, 0b100);
    if !IOCSS && NCSS set(*nvme.CC__controller_config, .CSS__io_command_set, 0b000);

    set(*nvme.CC__controller_config, .AMS__arbitration_mechanism, 0);
    set(*nvme.CC__controller_config, .MPS__memory_page_size, 0);

    set(*nvme.CC__controller_config, .EN__enable, 1);
    // For some reason this timeout trips on QEMU.
    Timeout(ready(nvme), "NVMe reset timeout (RDY is unset.)");


    // Send IDENTIFY command.
    identify_command: *Nvme_Submission_Queue_Entry = nvme.admin_submission_queue.data;
    identify_command.* = .{};
    identify_command.DPTR__data_pointer[0] = get_4k_page();
    identify_command.CNS__controller_or_namespace = .IDENTIFY_CONTROLLER;
    identify_command.OPC__opcode = .IDENTIFY;

    nvme.admin_submission_queue_tail = 1;
    nvme.SQ0TDBL__submission_queue_0_tail_doorbell = cast(u32) nvme.admin_submission_queue_tail;

    identify_result := identify_command.DPTR__data_pointer[0] + DIRECT_MAPPING_BASE;
    while cast(*u8, identify_result).* == 0 {}

    identify := cast(*Nvme_Identify_Controller_Structure) identify_result;

    sn := cast(string) identify.SN__serial_number;
    mn := cast(string) identify.MN__model_number;
    for sn if it == #char " " { sn.count = it_index; break; }
    for mn if it == #char " " { mn.count = it_index; break; }

    log("Found NVMe controller with serial number '%' and model number '%'.", sn, mn);
    free_4k_page(identify_command.DPTR__data_pointer[0]);


    // Identify active namespace ID list.
    identify_command = nvme.admin_submission_queue.data + 1;
    identify_command.* = .{};
    identify_command.DPTR__data_pointer[0] = get_4k_page();
    identify_command.CNS__controller_or_namespace = .ACTIVE_NAMESPACE_ID_LIST;
    identify_command.OPC__opcode = .IDENTIFY;

    identify_result = identify_command.DPTR__data_pointer[0] + DIRECT_MAPPING_BASE;

    nvme.admin_submission_queue_tail += 1;
    nvme.SQ0TDBL__submission_queue_0_tail_doorbell = cast(u32) nvme.admin_submission_queue_tail;

    while cast(*u8, identify_result).* == 0 {}

    list := cast(*[1024] u32) identify_result;
    for list.* {
        if it == 0 continue;
        log("Found NSID %.\n", it);
    }

    return nvme;
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
