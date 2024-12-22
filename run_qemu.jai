
#import "Process";
#import "Compiler";
#import "File";

#run {
    set_build_options_dc(.{ do_output = false });

    make_directory_if_it_does_not_exist("logs");

    command := break_command_into_strings(#string QEMU_CMD
        qemu-system-x86_64
            -bios OVMF.fd
            -drive format=raw,file=disk_image.img
            -chardev stdio,id=char0,logfile=logs/qemu_serial.txt,signal=off
            -serial chardev:char0
            -m 256M 
            -smp 8 
    QEMU_CMD);

    run_command(.. command);
}

#run {
    // Handy page table calculator
    x := cast(u64) 256 * 1024 * 1024;

    mask: u64 = 0b111111111;

    #import "Basic";
    pml4_offset := (x >> 39) & mask;
    pdpt_offset := (x >> 30) & mask;
    pd\ _offset := (x >> 21) & mask;
    pt\ _offset := (x >> 12) & mask;
    page_offset := x & 0xfff;

    print("PML4: %, PDPT: %, PD: %, PT: %, offset in page: %",
          pml4_offset,
          pdpt_offset,
          pd\ _offset,
          pt\ _offset,
          page_offset);

    return;
}
