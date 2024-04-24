
#import "Process";
#import "Compiler";

#run {
    set_build_options_dc(.{ do_output = false });

    command := break_command_into_strings("qemu-system-x86_64 -bios OVMF.fd -drive format=raw,file=disk_image.img -d int -D ./log.txt");
    run_command(.. command);
}

#run {
    // Handy page table calculator
    x := cast(u64) 0x8000_0000;

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
