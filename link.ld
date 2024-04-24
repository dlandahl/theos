ENTRY(kernel_entry)

SECTIONS {
    . = 0xffffffff80100000;
    .text   : { * (.text); }
    .rodata : { * (.rodata); }
    .data   : { * (.data); }
    .bss    : { * (.bss); }
}
