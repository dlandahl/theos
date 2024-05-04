
#load "boot_data.jai";

Framebuffer :: struct {
    buffer: *u32;
    x_resolution: int;
    y_resolution: int;
    stride: int;
}

#add_context framebuffer: Framebuffer;

#program_export
kernel_entry :: () #no_context {
    boot_data := cast(*Boot_Data) 0x10_0000;

    c: Context;
    c.framebuffer.buffer = cast(*u32) boot_data.framebuffer;
    c.framebuffer.x_resolution = boot_data.x_resolution;
    c.framebuffer.y_resolution = boot_data.y_resolution;
    c.framebuffer.stride = boot_data.stride;

    push_context c {
        fb := context.framebuffer;

        for y: 0..fb.y_resolution-1 {
            red := cast(int) (0xff * ((1.0 / fb.y_resolution) * y));

            for x: 0..fb.x_resolution-1 {
                green := cast(int) (0xff * ((1.0 / fb.x_resolution) * x));

                fb.buffer[x + y * fb.stride] = cast(u32) ((red << 16) | (green << 8));
            }
        }

        {
            page_table_physical_address := (cast(u64) page_table.data - 0xffff_ffff_8000_0000) + Boot_Data.KERNEL_PHYS_BASE;

            serial_int(cast(u64) page_table.data);
            serial_int(cast(u64) page_table_physical_address); 

            boot_data.page_tables.pd[boot_data.page_directories_used] = page_table_physical_address | PAGE_PRESENT | PAGE_READ_WRITE;
            virtual_base = cast(*void) 0xffff_ffff_8000_0000 + boot_data.page_directories_used*0x20_0000;
        }

        

        // fb_size := fb.y_resolution * fb.stride;
        // c.framebuffer.buffer = cast(*u32) map_pages(fb_size / 4096 + 1, cast(u64) fb.buffer);
    }

    #asm { cli; hlt; }
}

bluescreen :: () {
    using context.framebuffer;

    for y: 0..y_resolution-1 for x: 0..x_resolution-1 {
        buffer[x + y * stride] = cast(u32) (0xff0000ff);
    }

    #asm { cli; hlt; }
}

pages_mapped: int;
page_table: [0x200] u64 #align 4096;
virtual_base: *void;

map_pages :: (count: int, physical_base: u64) -> *void {
    for 0..count-1 {
        physical_address := physical_base + 4096 * cast(u64) it;
        page_table[pages_mapped] = physical_address | PAGE_PRESENT | PAGE_READ_WRITE;

        pages_mapped += 1;
        if pages_mapped >= 0x200 {
            bluescreen();
        }
    }

    return virtual_base + (pages_mapped - count) * 4096;
}

serial_string :: (message: string) {
    for cast([] u8) message {
        byte := it;
        port := 0x3f8;

        #asm {
            byte === a;
            port === d;
            out.b port, byte;
        }
    }
}

serial_int :: (value: u64) {
    hex_chars := "0123456789abcdef";
    result: [16] u8;

    for 0..15 {
        result[it] = hex_chars[(value >> (60 - it * 4)) & 0xF];
    }

    serial_string(cast(string) result);
    serial_string("\n");
}

Madt_Acpi_Table :: struct {
    #as header: Acpi_Table_Header;
    local_apic_address: u32;
    flags: u32;
}

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
