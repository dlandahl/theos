
#import "Process";
#import "Compiler";

#run {
    set_build_options_dc(.{ do_output = false });

    command := break_command_into_strings("qemu-system-x86_64 -bios OVMF.fd -drive format=raw,file=disk_image.img");
    run_command(.. command);
}
