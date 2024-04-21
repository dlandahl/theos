
#program_export
main :: () #no_context {

    vga := cast(*u8) 0xb8000;

    for cast([] u8) "Hello sailor!" {
        vga[it_index*2] = it;
        vga[it_index*2+1] = 0x0f;
    }

    #asm {
        cli;
        hlt;
    }
}

#program_export memset :: () {};
#program_export memcpy :: () {};
#program_export __libc_start_main :: () {};
