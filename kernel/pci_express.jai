
Acpi_MCFG :: struct {
    using header: Acpi_Table_Header;
    reserved: u64 #align 4;
}

find_all_pci_devices :: () {
    mcfg := cast(*Acpi_MCFG) find_acpi_table("MCFG");
    if !mcfg {
        log_error("ACPI MCFG table not found.");
        bluescreen();
    }

    total_length := mcfg.length;
    ecam_base := cast(u64) mcfg + size_of(Acpi_MCFG);
    ecam_length_bytes := total_length - size_of(Acpi_MCFG);

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
                header := read_device_configuration_space(it.base_address, bus, device, 0);
                if !header continue;

                if header.header_type & 0x80 == 0 {
                    // Device is not multi-function.
                    continue;
                }

                for function: 1..7 {
                    read_device_configuration_space(it.base_address, bus, device, function);
                }
            }
        }
    }
}

pci_devices: [..] struct {
    configuration_space: *Pci_Configuration_Space_Header;
};

read_device_configuration_space :: (base_address: u64, bus: int, device: int, function: int) -> *Pci_Configuration_Space_Header {
    device_offset := cast(u64) (bus * 256 + device * 8 + function);
    address := base_address + device_offset * PCI_CONFIGURATION_SPACE_SIZE;

    header := cast(*Pci_Configuration_Space_Header) (address + DIRECT_MAPPING_BASE);

    if header.vendor_id == PCI_VENDOR_ID_NO_DEVICE {
        return null;
    }

    if header.class_code == .UNCLASSIFIED {
        return null;
    }

    array_add(*pci_devices, .{header});

    return header;
}

PCI_VENDOR_ID_NO_DEVICE :: 0xffff;
PCI_CONFIGURATION_SPACE_SIZE :: 4096;

Pci_Configuration_Space_Header :: struct {
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
