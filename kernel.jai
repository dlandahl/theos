
#load "boot_data.jai";
#import,file "bootloader_modules/Lil_Uefi.jai";

Framebuffer :: struct {
    buffer: *u32;
    x_resolution: int;
    y_resolution: int;
    stride: int;
}

#add_context framebuffer: Framebuffer;

Page_Mapper :: struct {
    page_table: [0x200] u64;
    pages_mapped: int;
    virtual_base: *void;

    PHYSICAL_POOL : u64 : 0x80_0000;
    physical_pool_pages_used: u64;
}

page_mapper: Page_Mapper #align 4096;

#program_export
kernel_entry :: () #no_context {
    boot_data := cast(*Boot_Data) 0x10_0000;

    c: Context;
    c.framebuffer.buffer = cast(*u32) boot_data.framebuffer;
    c.framebuffer.x_resolution = boot_data.x_resolution;
    c.framebuffer.y_resolution = boot_data.y_resolution;
    c.framebuffer.stride = boot_data.stride;


    pm := *page_mapper;
    page_table_physical_address := (cast(u64) pm.page_table.data - 0xffff_ffff_8000_0000) + Boot_Data.KERNEL_PHYS_BASE;

    boot_data.page_tables.pd[boot_data.page_directories_used] = page_table_physical_address | PAGE_PRESENT | PAGE_READ_WRITE;
    pm.virtual_base = cast(*void) 0xffff_ffff_8000_0000 + boot_data.page_directories_used*0x20_0000;

    c.allocator.proc = allocator_proc;

    push_context c {
        fb := context.framebuffer;

        for y: 0..fb.y_resolution-1 {
            red := cast(int) (0xff * (1.0 / fb.y_resolution) * y);

            for x: 0..fb.x_resolution-1 {
                green := cast(int) (0xff * (1.0 / fb.x_resolution) * x);
                fb.buffer[x + y * fb.stride] = cast(u32) ((red << 16) | (green << 8));
            }
        }

        acpi_memory_type_id :: 9;
        buddy: Buddy_Allocator;
        buddy_buffer: [500] u8;

        for 0..boot_data.memory_map_entries_used-1 {
            entry := boot_data.memory_map[it];

            // if entry.type == acpi_memory_type_id {
            //     map_pages(xx entry.pages, entry.address);
            // }

            ti := type_info(EFI_MEMORY_TYPE);
            index: int = 1;

            for ti.values if it == cast(int) entry.type {
                index = it_index;
                break;
            }

            enum_name := ti.names[index];

            serial_out(enum_name);
            serial_out(": ");
            serial_write_int(entry.pages);

            if entry.type == .EfiConventionalMemory && entry.pages >= 0x1000 {
                buddy = make_buddy(entry.address, 0x1000 * 4096, buddy_buffer.data);
                break;
            }

            if it == boot_data.memory_map_entries_used-1 {
                serial_out("Not enough usable contiguous physical memory found.\n");
                bluescreen();
            }
        }

        rsdp := cast(*Acpi_RSDP__Root_System_Description_Pointer) boot_data.acpi_rsdp;

        phys := cast(u64) rsdp.rsdt_address;
        if rsdp.revision >= 2  phys = rsdp.xsdt_address;

        offset_in_page := phys % 4096;
        virt := map_pages(4, phys);

        rsdt: *Acpi_Table_Header = virt + offset_in_page;

        // if rsdp.revision < 2 {
        //     bluescreen();
        // }
    }

    #asm { cli; hlt; }
}

bluescreen :: () {
    using context.framebuffer;

    for y: 0..y_resolution-1 for x: 0..x_resolution-1 {
        buffer[x + y * stride] = cast(u32) (0xff0000ff);
    }

    #asm { cli; hlt; }
}

USE_POOL :: cast,no_check(u64) -1;
map_pages :: (count: int, _physical_base: u64) -> *void {
    using page_mapper;

    physical_base := ifx _physical_base == USE_POOL then (PHYSICAL_POOL + physical_pool_pages_used * 4096) else _physical_base;

    for 0..count-1 {
        physical_address := physical_base + 4096 * cast(u64) it;
        page_table[pages_mapped] = physical_address | PAGE_PRESENT | PAGE_READ_WRITE;

        pages_mapped += 1;
        if pages_mapped >= 0x200 {
            bluescreen();
        }
    }

    if _physical_base == USE_POOL {
        physical_pool_pages_used += xx count;
    }
    return virtual_base + (pages_mapped - count) * 4096;
}

allocator_proc :: (mode: Allocator_Mode, size: s64, old_size: s64, old_memory: *void, allocator_data: *void) -> *void {
    if mode != .ALLOCATE && mode != .RESIZE return null;

    new := map_pages(size / 4096 + 1, USE_POOL);
    if old_memory != null {
        memcpy(new, old_memory, old_size);
    }

    return new;
}

serial_out :: (data: string) {
    for cast([] u8) data {
        byte := it;
        port := 0x3f8;

        #asm {
            byte === a;
            port === d;
            out.b port, byte;
        }
    }
}

serial_write_int :: (value: u64) {
    hex_chars := "0123456789abcdef";
    result: [16] u8;

    for 0..15 {
        result[it] = hex_chars[(value >> (60 - it * 4)) & 0xF];
    }

    serial_out(cast(string) result);
    serial_out("\n");
}

Acpi_RSDP__Root_System_Description_Pointer :: struct {
    signature: [8] u8;
    checksum: u8;
    oem_id: [6] u8;
    revision: u8;
    rsdt_address: u32;

    length: u32;
    xsdt_address: u64 #align 4;
    checksum_2: u8;
    reserved: [3] u8;
}

Acpi_Table_Header :: struct {
    signature: [4] u8;
    length: u32;
    revision: u8;
    checksum: u8;
    oem_id: [6] u8;
    oem_table_id: [8] u8;
    oem_revision: u32;
    creator_id: u32;
    creator_revision: u32;
} #no_padding

Acpi_MADT__Multiple_Apic_Description_Table :: struct {
    #as header: Acpi_Table_Header;
    local_apic_address: u32;
    flags: u32;
}

Acpi_FADT__Fixed_Description_Table :: struct {
    #as header: Acpi_Table_Header;
    firmware_ctrl: u32;
    dsdt_address: u32;

    // Todo: doesn't handle 64bit dsdt address
    // https://uefi.org/htmlspecs/ACPI_Spec_6_4_html/05_ACPI_Software_Programming_Model/ACPI_Software_Programming_Model.html?highlight=dsdt#fadt-format
}

#program_export __libc_start_main :: () {}



Page :: struct {
    ref_count: int;
}

#import "Bit_Array";
#import "Bit_Operations";

Buddy_Allocator :: struct {
    freelists: [] int;
    FREELIST_TERMINATOR :: -1;
    bitmap: Bit_Array;

    base_address: u64;
}

make_buddy :: (base: u64, size: s64, buffer: *void) -> Buddy_Allocator {
    using buddy: Buddy_Allocator;
    // For now assumes the smallest block size is a page

    // Todo: assert base address is page aligned, size is 2^x, buffer is big enough
    cursor := buffer;
    levels := bit_scan_reverse(size) - 13;

    freelists.data = cursor;
    freelists.count = levels;
    cursor += freelists.count * size_of(int);

    bitmap.count = 2 * (size / 4096);
    bitmap_slots := (bitmap.count + 63) >> 6;
    bitmap.slots.count = bitmap_slots;
    bitmap.slots.data = cursor;
    cursor += bitmap.slots.count * size_of(int);

    memset(buffer, 0, xx (cursor - buffer));
    for *freelists {
        it.* = Buddy_Allocator.FREELIST_TERMINATOR;
    }

    base_address = base;
    return buddy;
}

buddy_alloc :: (buddy: *Buddy_Allocator, bytes: int) -> u64 {

    level := bit_scan_reverse(bytes) - 13 + 1;

    b0 :=      (1 << level) - 1;
    b1 := b0 + (1 << level) - 1;

    address: u64;

    for bit: b0..b1 {
        if buddy.bitmap[bit] continue; // Find a block that's not already allocated

        parent := bit;
        for level-1..0 {
            // Set all the parent bits
            if buddy.bitmap[parent] break;

            set_bit(*buddy.bitmap, parent);
            parent = (parent - 1) / 2;
        }

        recursively_set_children :: (buddy: *Buddy_Allocator, bit: int) {
            left_child := bit * 2 + 1;

            if left_child < buddy.freelists.count {
                recursively_set_children(buddy, left_child);
                recursively_set_children(buddy, left_child + 1);

                set_bit(*buddy.bitmap, bit);
            }
        }

        recursively_set_children(buddy, bit);

        break;
    }
}
