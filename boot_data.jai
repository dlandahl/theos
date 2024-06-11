
// Stuff that's shared between bootloader and kernel

Page_Tables :: struct {
    pml4: [0x200] u64;

    // Page tables which cover near the top of virtual memory where the kernel executable runs. Framebuffer is also put here.
    pdpt: [0x200] u64;
    pd:   [0x200] u64;

    // Page tables which cover the beginning of the upper half of virtual memory
    direct_pdpt:   [0x200] u64;
    direct_pd: [64][0x200] u64;

    // Page tables for low memory so the bootloader can keep running after we switch from the UEFI mapping to this one
    boot_pdpt: [0x200] u64;
    boot_pd:   [0x200] u64;
}

DIRECT_MAPPING_BASE :: 0xffff_8000_0000_0000; // All physical memory will be mapped into virtual at this address (address 0 in physical memory gets mapped to DIRECT_MAPPING_BASE and so on.)

Boot_Data :: struct {
    page_tables: Page_Tables;

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

    page_frames: *Page_Frame_Desc;
}

Page_Frame_Desc :: struct {
    // We want to keep this thing as small as possible because there's one for each physical memory page in the device
    freelist: s32;
    FREELIST_TAIL :: -1;

    // Linux puts information in here that lets you find all page tables that map this page.
    // https://www.kernel.org/doc/gorman/html/understand/understand006.html#toc27
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
