
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

Acpi_FADT__Fixed_Description_Table :: struct {
    #as header: Acpi_Table_Header;
    firmware_ctrl: u32;
    dsdt_address: u32;

    // Todo: doesn't handle 64bit dsdt address
    // https://uefi.org/htmlspecs/ACPI_Spec_6_4_html/05_ACPI_Software_Programming_Model/ACPI_Software_Programming_Model.html?highlight=dsdt#fadt-format
}

find_acpi_table :: (signature: string) -> *Acpi_Table_Header {
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



Acpi_MADT :: struct {
    using #as header: Acpi_Table_Header;

    local_apic_address: u32;
    flags: u32;

    Interrupt_Controller_Structure :: struct {
        type: Type;
        length: u8;

        Type :: enum u8 {
            LOCAL_APIC                :: 0x0;
            INTERRUPT_SOURCE_OVERRIDE :: 0x1;
            NON_MASKABLE_INTERRUPT    :: 0x4;
            MULTIPROCESSOR_WAKEUP     :: 0x10;
        }
    }

    Ics_Local_Apic :: struct {
        using ics: Interrupt_Controller_Structure;

        acpi_processor_uid: u8;
        apic_id: u8;

        flags: enum u32 {
            enabled;
            online_capable;
        };
    }

    Ics_Source_Override :: struct {
        using ics: Interrupt_Controller_Structure;

        bus: u8;
        source: u8;
        global_system_interrupt: u32;
        flags: u16;
    }

    Ics_Non_Maskable_Interrupt :: struct {
        using ics: Interrupt_Controller_Structure;

        processor_uid: u8;
        flags: u16 #align 1;
        lapic_lint: u8;
    }
}

apic_stuff :: () {
    acpi_header := cast(*Acpi_MADT) find_acpi_table("APIC");

    cursor := cast(u32) acpi_header + size_of(Acpi_MADT);

    while cursor < cast(u32) acpi_header + acpi_header.length {
        ics := cast(*Acpi_MADT.Interrupt_Controller_Structure) cursor;

        if ics.type == {
          case .LOCAL_APIC;
            lapic := cast(*Acpi_MADT.Ics_Local_Apic) ics;
            print("Found Local APIC: %\n", << lapic);
          case;
            print("ICS type %\n", cast(u8) ics.type);
        }

        cursor += ics.length;
    }

    Apic_Base_Flags :: enum_flags {
        BSC__Boot_Strap_Core :: 1 << 8;
        EXTD__2xApic_Mode    :: 1 << 10;
        AE__Apic_Enable      :: 1 << 11;
    }

    apic_base := << cast(*Apic_Base_Flags) *read_msr(.APIC_BASE__Apic_Base);
    assert(apic_base & .BSC__Boot_Strap_Core > 0);

    apic_base |= .AE__Apic_Enable;
    write_msr(.APIC_BASE__Apic_Base, cast(u64) apic_base);

    physical := cast(u64) apic_base & ~0xfff;
    assert(0xfee0_0000 == physical);
    assert(acpi_header.local_apic_address == cast(u32) physical);

    virtual := alloc_block(*kernel_globals.virtual_block_allocator, 4096);
    map_page(virtual, physical, Page_Flags.READ_WRITE | .PRESENT | .CACHE_DISABLE);

    apic = cast(*void) virtual;
    version := << cast(*u32) (apic + cast(u64) APIC_Register_Offset.APIC_VERSION);

    print("Did APIC stuff. Version: %\n", formatInt(version, base=16));
}
