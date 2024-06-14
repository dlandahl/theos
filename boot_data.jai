
// Stuff that's shared between bootloader and kernel

Page_Tables :: struct {
    pml4: [0x200] u64;

    // Page tables for the kernel executable, at the top of virtual memory
    pdpt: [0x200] u64;
    pd:   [0x200] u64;

    // Page tables for the direct mapping
    direct_pdpt:   [0x200] u64;
    direct_pd: [64][0x200] u64;

    // Page tables for low memory so the bootloader can keep running
    boot_pdpt: [0x200] u64;
    boot_pd:   [0x200] u64;
}

DIRECT_MAPPING_BASE :: 0xffff_8000_0000_0000;

Boot_Data :: struct {
    page_tables: Page_Tables; // This should be the first field to ensure alignment of page tables to a page boundary

    page_directories_used: int;
    KERNEL_PHYS_BASE :: 0x600_0000; // Random choice, really this needs to be dynamically chosen to avoid writing over firmware stuff

    framebuffer: *u32;
    x_resolution: u32;
    y_resolution: u32;
    stride: u32;

    acpi_rsdp: *void;

    // For now we don't report memory that the OS can't immediately use
    Usable_Memory_Region :: struct {
        address: u64;
        pages: u64;
    };

    Memory_Region :: Usable_Memory_Region;

    memory_map: [100] Usable_Memory_Region;
    memory_map_entries_used: int;

    page_frames: [] Page_Frame_Desc;
}

Page_Frame_Desc :: struct {
    // We want to keep this struct as small as possible because there's one for each physical memory page in the device
    freelist: s32;
    FREELIST_TAIL :: -1;

    flags: Flags;

    Flags :: enum_flags u8 {
        ALLOCATOR_TAG_SINGLE_PAGE;
        ALLOCATOR_TAG_BLOCK;
        ALLOCATOR_TAG_BUDDY;
    };
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
