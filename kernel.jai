
#load "boot_data.jai";

#program_export
kernel_entry :: () #no_context {
    boot_data := cast(*Boot_Data) 0x10_0000;

    framebuffer: [] u32;
    framebuffer.data = cast(*u32) boot_data.framebuffer;
    framebuffer.count = cast(s64) boot_data.x_resolution * boot_data.y_resolution;

    x_res := boot_data.x_resolution;
    y_res := boot_data.y_resolution;

    for y: 0..y_res-1 {
        r := cast(int) (0xff * ((1.0 / y_res) * y));

        for x: 0..x_res-1 {
            g := cast(int) (0xff * ((1.0 / x_res) * x));

            framebuffer[x + y * boot_data.stride] = cast(u32) ((r<<16) | (g<<8));
        }
    }

    {
        using boot_data;

        page_table_physical_address := 0xffff_ffff_8000_0000 - cast(u64) page_table.data + KERNEL_PHYS_BASE;
        page_tables.pd[page_directories_used] = page_table_physical_address | PAGE_PRESENT | PAGE_READ_WRITE;
    }

    #asm { cli; hlt; }
}



pages_mapped: int;
page_table: [0x200] u64 #align 4096;

map_pages :: (count: int, physical_base: u64) -> *void {
    for 0..count-1 {
        physical_address := physical_base + 4096 * cast(u64) it;
        page_table[it + pages_mapped] = physical_address | PAGE_PRESENT | PAGE_READ_WRITE;

        pages_mapped += 1;
        if pages_mapped >= 0x200 {
            #asm { cli; hlt; }
        }
    }
}



Madt_Acpi_Table :: struct {
    #as header: Acpi_Table_Header;
    local_apic_address: u32;
    flags: u32;
}

Acpi_Root_Pointer :: struct {
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

#assert (size_of(Acpi_Root_Pointer) == 36);

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

Acpi_Fixed_Description_Table :: struct {
    #as header: Acpi_Table_Header;
    firmware_ctrl: u32;
    dsdt_address: u32;

    // Does not handle 64bit dsdt address
    // https://uefi.org/htmlspecs/ACPI_Spec_6_4_html/05_ACPI_Software_Programming_Model/ACPI_Software_Programming_Model.html?highlight=dsdt#fadt-format
}

X64_Flags :: enum_flags u64 {
    CF__carry  :: 0x1;
    PF__parity :: 0x4;
    AF__adjust :: 0x10;
    ZF__zero   :: 0x40;
    SF__sign   :: 0x80;
    TF__trap   :: 0x100;
    IF__interrupt :: 0x200;
    DF__direction :: 0x400;
    OF__overflow  :: 0x800;
    RF__resume    :: 0x10000;
}

#program_export __libc_start_main :: () {}
