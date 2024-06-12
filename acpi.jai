
Acpi_RSDP__Root_System_Description_Pointer :: struct {
    signature: [8] u8;
    checksum: u8;
    oem_id: [6] u8;
    revision: u8;
    rsdt_address: u32;

    length: u32;
    xsdt_address: u64 #align 4;
    checksum_2: u8;
    reserved: [3] u8;
}

Acpi_Table_Header :: struct {
    signature: [4] u8;
    length: u32;
    revision: u8;
    checksum: u8;
    oem_id: [6] u8;
    oem_table_id: [8] u8;
    oem_revision: u32;
    creator_id: u32;
    creator_revision: u32;
} #no_padding

Acpi_MADT__Multiple_Apic_Description_Table :: struct {
    #as header: Acpi_Table_Header;
    local_apic_address: u32;
    flags: u32;
}

Acpi_FADT__Fixed_Description_Table :: struct {
    #as header: Acpi_Table_Header;
    firmware_ctrl: u32;
    dsdt_address: u32;

    // Todo: doesn't handle 64bit dsdt address
    // https://uefi.org/htmlspecs/ACPI_Spec_6_4_html/05_ACPI_Software_Programming_Model/ACPI_Software_Programming_Model.html?highlight=dsdt#fadt-format
}

acpi_get_table_by_signature :: (signature: string) -> *Acpi_Table_Header {
    table_size := root_acpi_table.length - size_of(Acpi_Table_Header);

    pointer_size := cast(u64) (ifx acpi_version then 8 else 4);
    pointer_count := table_size / pointer_size;

    table_base := cast(u64) (root_acpi_table + 1);

    for table_index: 0..pointer_count - 1 {
        offset := table_index * pointer_size + table_base;

        phys := ifx acpi_version {
            << cast(*u64) offset;
        } else {
            cast(u64) << cast(*u32) offset;
        }

        header := cast(*Acpi_Table_Header) (phys + DIRECT_MAPPING_BASE);

        for 0..3 if header.signature[it] != signature[it] {
            continue table_index;
        }

        return header;
    }

    return null;
}
