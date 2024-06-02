
// Shared between bootloader and kernel

Page_Tables :: struct {
    pml4: [0x200] u64;
    pdpt: [0x200] u64;
    pd:   [0x200] u64;

    boot_pdpt: [0x200] u64;
    boot_pd:   [0x200] u64;
}

PAGE_PRESENT    : u64 : 0x1;
PAGE_READ_WRITE : u64 : 0x2;
PAGE_SIZE       : u64 : 0x80;

Boot_Data :: struct {
    page_tables: Page_Tables;

    kernel_load_buffer: [0x5_0000] u8;

    page_directories_used: int;
    KERNEL_PHYS_BASE :: 0x100_0000; // Random choice, really this needs to be dynamically chosen to avoid writing over firmware stuff

    framebuffer: *u32;
    x_resolution: u32;
    y_resolution: u32;
    stride: u32;

    acpi_rsdp: *void;

    Memory_Usability :: enum {
        RESERVED;
        USABLE;
    };

    Memory_Region :: struct {
        address: u64;
        pages: u64;
        usability: Memory_Usability;
    };

    memory_map: [100] Memory_Region;
    memory_map_entries_used: int;
}

#program_export
memset :: (target: *void, value: u8, count: s64) -> *void #c_call {
    #asm {
        cld;

        count  === c;
        target === di;
        value  === a;
        rep_stos.b target, value, count;
    }

    return target;
}

#program_export
memcpy :: (dst: *void, src: *void, count: s64) -> *void #c_call {
    #asm {
        cld;

        src   === si;
        dst   === di;
        count === c;
        rep_movs.b dst, src, count;
    }

    return dst;
}

_memcmp :: (a: *u8, b: *u8, count: u64) -> s16 #c_call {
    start := a;

    #asm {
        cld;
        
        count === c;
        a === si;
        b === di;
        repe_cmps.b b, a, count;
    }

    if start + count == a {
        return 0;
    }

    return cast(s16) (*(a-1) - *(b-1));
}
