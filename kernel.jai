
#load "boot_data.jai";
#import,file "bootloader_modules/Lil_Uefi.jai";

Framebuffer :: struct {
    buffer: *u32;
    x_resolution: int;
    y_resolution: int;
    stride: int;
}

#add_context framebuffer: Framebuffer;
#add_context boot_data: *Boot_Data;

#program_export
kernel_entry :: () #no_context {
    boot_data := cast(*Boot_Data) 0x10_0000;
    page_frames := boot_data.page_frames;

    c: Context;
    c.framebuffer.buffer = cast(*u32) boot_data.framebuffer;
    c.framebuffer.x_resolution = boot_data.x_resolution;
    c.framebuffer.y_resolution = boot_data.y_resolution;
    c.framebuffer.stride = boot_data.stride;

    c.boot_data = boot_data;
    c.assertion_failed = (location: Source_Code_Location, message: string) -> bool {
        bluescreen();
        return true;
    };

    // page_table_physical_address := (cast(u64) pm.page_table.data - 0xffff_ffff_8000_0000) + Boot_Data.KERNEL_PHYS_BASE;

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

        for 0..boot_data.memory_map_entries_used-1 {
            entry := boot_data.memory_map[it];

            /*
                serial_out("Free region at ");
                serial_write_int(entry.address);
                serial_out("Bytes:\n");
                serial_write_int(entry.pages * 4096);
            */

            if entry.pages >= 1024 {
                pool := *context.physical_page_pool;

                pool.start = cast(int) (entry.address / 4096);
                pool.page_count = cast(int) entry.pages;
                pool.high_watermark = 0;
                pool.freelist = pool.FREELIST_TAIL;

                break;
            }

            if it == boot_data.memory_map_entries_used-1 {
                serial_out("Not enough usable contiguous physical memory found.\n");
                bluescreen();
            }
        }

        a := get_page_frame();
        b := get_page_frame();
        c := get_page_frame();

        serial_write_int(frame_physical_address(a));
        serial_write_int(frame_physical_address(b));
        serial_write_int(frame_physical_address(c));

        release_page_frame(c);
        release_page_frame(b);
        b = get_page_frame();
        serial_write_int(frame_physical_address(b));

        rsdp := cast(*Acpi_RSDP__Root_System_Description_Pointer) boot_data.acpi_rsdp;

        phys: u64;
        if rsdp.revision >= 2 {
            phys = rsdp.xsdt_address;
        } else {
            phys = cast(u64) rsdp.rsdt_address;
        }
    }

    while true #asm { cli; hlt; }
}

bluescreen :: () {
    using context.framebuffer;

    for y: 0..y_resolution-1 for x: 0..x_resolution-1 {
        buffer[x + y * stride] = cast(u32) (0xff0000ff);
    }

    while true #asm { cli; hlt; }
}

get_page_frame :: () -> *Page_Frame_Desc, int {
    using context.physical_page_pool;

    if freelist != FREELIST_TAIL {
        page := *context.boot_data.page_frames[freelist];
        index := freelist;

        freelist = page.freelist;

        return page, index;
    }

    if high_watermark >= page_count {
        bluescreen();
    }

    index := start + high_watermark;
    page := *context.boot_data.page_frames[index];

    high_watermark += 1;

    return page, index;
}

release_page_frame :: (index: int) {
    using context.physical_page_pool;

    page_frame := *context.boot_data.page_frames[index];
    page_frame.freelist = freelist;
    freelist = xx index;
}

release_page_frame :: (page_frame: *Page_Frame_Desc) {
    using context.physical_page_pool;

    page_frame.freelist = freelist;
    freelist = index(page_frame);
}

frame_physical_address :: (page_frame: *Page_Frame_Desc) -> u64 {
    return cast(u64) index(page_frame) * 4096;
}

index :: (page_frame: *Page_Frame_Desc) -> s32 {
    index := (cast(u64) page_frame - cast(u64) context.boot_data.page_frames) / size_of(Page_Frame_Desc);
    return xx index;
}

Physical_Page_Pool :: struct {
    start: int;
    page_count: int;
    high_watermark: int;

    freelist: s32 = FREELIST_TAIL;
    FREELIST_TAIL :: Page_Frame_Desc.FREELIST_TAIL;
}

// I think it won't make sense in the future for this to be in the context, because it'll be used from syscall handlers
#add_context physical_page_pool: Physical_Page_Pool;

get_or_create_page_table :: (table: *u64, entry: u64) -> *u64 {
    using Page_Flags;

    if table[entry] & xx PRESENT {
        phys := table[entry] & (~0xfff);
        return cast(*u64) (phys + 0xffff_8000_0000_0000);
    }

    page := get_page_frame();
    address := frame_physical_address(page);

    table[entry] = address | xx PRESENT | READ_WRITE;

    return cast(*u64) (address + 0xffff_8000_0000_0000);
}

map_page :: (virtual_address: u64, page_frame: *Page_Frame_Desc) {
    using Page_Flags;

    mask: u64 = 0b111111111;

    pml4_offset := (virtual_address >> 39) & mask;
    pdpt_offset := (virtual_address >> 30) & mask;
    pd\ _offset := (virtual_address >> 21) & mask;
    pt\ _offset := (virtual_address >> 12) & mask;

    pml4 := context.boot_data.page_tables.pml4.data;

    pdpt := get_or_create_page_table(pml4, pml4_offset);
    pd   := get_or_create_page_table(pdpt, pdpt_offset);
    pt   := get_or_create_page_table(pd,   pd_offset);

    if pt[pt_offset] & xx PRESENT {
        bluescreen();
    }

    physical_address := frame_physical_address(page_frame);

    pt[pt_offset] = physical_address | cast(u64) PRESENT | READ_WRITE;

    pg := *virtual_address;
    #asm {
        invlpg [pg];
    }
}

Page_Flags :: enum_flags u64 {
    PRESENT         :: 1 << 0;
    READ_WRITE      :: 1 << 1;
    USER_SUPERVISOR :: 1 << 2;
    WRITE_THROUGH   :: 1 << 3;
    CACHE_DISABLE   :: 1 << 4;
    ACCESSED        :: 1 << 5;
    AVAILABLE       :: 1 << 6;
    PAGE_SIZE       :: 1 << 7;
    EXECUTE_DISABLE :: 1 << 63;
}

allocator_proc :: (mode: Allocator_Mode, size: s64, old_size: s64, old_memory: *void, allocator_data: *void) -> *void {
    if mode != .ALLOCATE && mode != .RESIZE return null;

    // new := map_pages(size / 4096 + 1, USE_POOL);
    if old_memory != null {
        // memcpy(new, old_memory, old_size);
    }

    // return new;
    return null;
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

serial_write_int :: (value: $T) {
    v := cast,no_check(u64) value;

    hex_chars := "0123456789abcdef";
    result: [16] u8;

    for 0..15 {
        result[it] = hex_chars[(v >> (60 - it * 4)) & 0xF];
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



#import "Bit_Array";
#import "Bit_Operations";

Buddy_Allocator :: struct {
    freelists: [] int;
    FREELIST_TERMINATOR :: -1;

    bitmap: Bit_Array;

    base_address: u64;
}

serial_write_buddy_bits :: (buddy: *Buddy_Allocator) {
    data: u8;
    bit: string;
    bit.count = 1;
    bit.data = *data;

    for buddy.bitmap {

        if it_index == 1 || it_index == 3 || it_index == 7 || it_index == 15 {
            serial_out("\n");
        }

        data = cast(u8) ifx it then #char "1" else #char "0";
        serial_out(bit);
    }
    serial_out("\n\n");
}

make_buddy :: (base: u64, size: s64, buffer: *void) -> Buddy_Allocator {
    using buddy: Buddy_Allocator;
    // For now assumes the smallest block size is a page

    // Todo: assert base address is page aligned, size is 2^x, buffer is big enough
    cursor := buffer;
    levels := bit_scan_reverse(size) - 13 + 1;

    serial_out("Creating buddy.\n");
    serial_out("Num levels: "); serial_write_int(xx levels);

    freelists.data = cursor;
    freelists.count = levels;
    cursor += freelists.count * size_of(int);

    bitmap.count = 2 * (size / 4096) - 1;
    serial_out("Bitmap bits: "); serial_write_int(xx bitmap.count);
    serial_out("\n\n");

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

    level := buddy.freelists.count - (bit_scan_reverse(bytes) - 13 + 1);

    b0 := (1 << level) - 1;
    b1 := b0 + b0;

    serial_out("Level: "); serial_write_int(xx level);
    serial_out("b0: ");    serial_write_int(xx b0);
    serial_out("b1: ");    serial_write_int(xx b1);

    address: u64;

    for bit: b0..b1 {
        if buddy.bitmap[bit] continue; // Find a block that's not already allocated

        serial_out("Checking bit\n");

        parent := bit;
        for< level-1..0 {
            // Set all parent bits
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

    return b0 * 4096;
}
