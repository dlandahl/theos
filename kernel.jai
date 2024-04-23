
Page_Tables :: struct {
    pml4: [0x200] u64;
    pdpt: [0x200] u64;
    pd:   [0x200] u64;

    boot_pdpt: [0x200] u64;
    boot_pd:   [0x200] u64;
}

Boot_Data :: struct {
    // Stuff handed to us by the bootloader
    page_tables: Page_Tables;

    kernel_load_buffer: [0x10_0000] u8;

    framebuffer: u64;
    x_resolution: u32;
    y_resolution: u32;
}

#program_export
main :: () #no_context {
    boot_data := cast(*Boot_Data) 0x10_0000;

    framebuffer: [] u32;
    framebuffer.data = cast(*u32) boot_data.framebuffer;
    framebuffer.count = cast(s64) boot_data.x_resolution * boot_data.y_resolution;

    for *framebuffer {
        it.* = 0xffffffff;
    }

    #asm {
        cli;
        hlt;
    }
}

#program_export memset :: () {};
#program_export memcpy :: () {};
#program_export __libc_start_main :: () {};
