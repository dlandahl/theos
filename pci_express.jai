
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
    ecam_address_list_base := cast(u64) mcfg + size_of(Acpi_MCFG);
    ecam_address_list_length_bytes := total_length - size_of(Acpi_MCFG);

    Ecam_Bus_Address :: struct {
        base_address: u64;
        segment_group: u16;
        start_bus: u8;
        end_bus: u8;
        reserved: u32;
    }

    ecam_bus_addresses: [] Ecam_Bus_Address;
    ecam_bus_addresses.data = cast(*Ecam_Bus_Address) ecam_address_list_base;
    ecam_bus_addresses.count = ecam_address_list_length_bytes / size_of(Ecam_Bus_Address);

    for ecam_bus_addresses {
        CONFIG_SPACE_SIZE :: 4096;

        for bus_index: it.start_bus..it.end_bus {
            for device_index: 0..255 {
                for function_index: 0..7 {

                    device_offset := cast(u64) (bus_index * 256 + device_index * 8 + function_index);
                    address := it.base_address + device_offset * CONFIG_SPACE_SIZE;

                    header := cast(*Pci_Configuration_Space_Header) (address + DIRECT_MAPPING_BASE);

                    if header.vendor_id == PCI_VENDOR_NO_DEVICE continue;
                    if header.class == .UNCLASSIFIED continue;

                    print("PCIe device class: %\n", header.class_code);
                }
            }
        }
    }
}

PCI_VENDOR_NO_DEVICE :: 0xffff;

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
