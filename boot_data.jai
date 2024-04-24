
// Shared between bootloader and kernel

Page_Tables :: struct {
    pml4: [0x200] u64;
    pdpt: [0x200] u64;
    pd:   [0x200] u64;

    boot_pdpt: [0x200] u64;
    boot_pd:   [0x200] u64;
}

Boot_Data :: struct {
    page_tables: Page_Tables;

    kernel_load_buffer: [0x10_0000] u8;

    framebuffer: *u32;
    x_resolution: u32;
    y_resolution: u32;
    stride: u32;
}
