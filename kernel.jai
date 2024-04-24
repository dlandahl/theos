
#load "boot_data.jai";

#program_export
kernel_entry :: () #no_context {
    // #asm { int3; }
    boot_data := cast(*Boot_Data) 0x10_0000;
    // if boot_data.framebuffer == cast(*u32) (0xffff_ffff_8000_0000 + 4*0x20_0000) #asm { int3; }

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

    #asm {
        cli;
        hlt;
    }
}

#program_export memset :: () {};
#program_export memcpy :: () {};
#program_export __libc_start_main :: () {};
