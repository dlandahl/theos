
#import "Basic";

#load "boot_data.jai";
#load "acpi.jai";

Framebuffer :: struct {
    buffer: *u32;
    x_resolution: int;
    y_resolution: int;
    stride: int;
}

Kernel_Globals :: struct {
    framebuffer: Framebuffer;
    boot_data: *Boot_Data;
    page_frames: *Page_Frame_Desc;

    physical_page_pool: Physical_Page_Pool;
    physical_block_allocator: Block_Allocator;
    virtual_block_allocator: Block_Allocator;

    root_acpi_table: *Acpi_Table_Header;
    acpi_version: int;

    interrupt_descriptor_table: [256] Interrupt_Gate_Desc #align 16; // Hardware requires 16 byte alignment on IDT
    global_descriptor_table: Global_Descriptor_Table #align 64; // Align to cache block so no extra memory accesses are required on context switch

    apic: *void;
}

using kernel_globals: Kernel_Globals;

Interrupts :: #library,no_dll ".build/interrupts";

X64_Flags :: enum_flags u64 {
    CF__carry  :: 0x1;
    PF__parity :: 0x4;
    AF__adjust :: 0x10;
    ZF__zero   :: 0x40;
    SF__sign   :: 0x80;
    TF__trap   :: 0x100;
    IF__interrupt :: 0x200;
    DF__direction :: 0x400;
    OF__overflow  :: 0x800;
    RF__resume    :: 0x10000;
}

Interrupt_Stack_Frame :: struct (with_error_code: bool) {
#if with_error_code {
    error_code: u64;
}
    ip:    u64;
    cs:    u64;
    flags: X64_Flags;
    sp:    u64;
    ss:    u64;
}

Interrupt_Data :: struct (with_error_code: bool) {
    r15:  u64;
    r14:  u64;
    r13:  u64;
    r12:  u64;
    r11:  u64;
    r10:  u64;
    r9 :  u64;
    r8 :  u64;
    rbp:  u64;
    rdi:  u64;
    rsi:  u64;
    rdx:  u64;
    rcx:  u64;
    rbx:  u64;
    rax:  u64;
    using interrupt_frame: Interrupt_Stack_Frame(with_error_code);
}

Interrupt_Gate_Desc :: struct {
    offset_1: u16;
    selector: u16;
    ist:      u8;
    flags:    u8;
    offset_2: u16;
    offset_3: u32;
    reserved: u32;
}

register_interrupt_gate :: (handler: *void, vector_number: int) {
    desc := *interrupt_descriptor_table[vector_number];
    address := cast(u64) handler;

    desc.offset_1  = xx  address        & 0xffff;
    desc.offset_2  = xx (address >> 16) & 0xffff;
    desc.offset_3  = xx (address >> 32) & 0xffffffff;
    desc.selector  = 0x8;
    desc.ist       = 0x0;
    desc.flags     = 0x8e;
    desc.reserved  = 0x0;
}

Global_Descriptor_Table :: struct {
    null_entry: u64;
    ring0_code: Gdt_Entry_Flags;
    ring0_data: Gdt_Entry_Flags;
    ring3_code: Gdt_Entry_Flags;
    ring3_data: Gdt_Entry_Flags;
    terminator: u64;
}

Gdt_Entry_Flags :: enum u64 {
    AVAILABLE       :: 0x01 << 52;
    LONG_MODE_CODE  :: 0x02 << 52;
    SIZE            :: 0x04 << 52;
    GRANULARITY     :: 0x08 << 52;
    ACCESSED        :: 0x01 << 40;
    READ_WRITE      :: 0x02 << 40;
    DIRECTION       :: 0x04 << 40;
    EXECUTABLE      :: 0x08 << 40;
    DESCRIPTOR_TYPE :: 0x10 << 40;
    PRIVILEGE0      :: 0x20 << 40;
    PRIVILEGE1      :: 0x40 << 40;
    PRESENT         :: 0x80 << 40;
}

Ia32_Model_Specific_Register :: enum {
    APIC_BASE__Apic_Base      :: 0x0000_001b;
    PAT__Page_Attribute_Table :: 0x0000_0277;
    EFER__Extended_Features   :: 0xc000_0080;
    STAR__Syscall_Segment     :: 0xc000_0081;
    LSTAR__Syscall_Address    :: 0xc000_0082;
    FMASK__Syscall_Flags      :: 0xc000_0084;
}

write_msr :: (msr: Ia32_Model_Specific_Register, value: u64) {
    high := value >> 32;
    low := value & 0xffff_ffff;

    #asm {
        msr === c;
        high === d;
        low  === a;

        wrmsr high, low, msr;
    }
}

read_msr :: (msr: Ia32_Model_Specific_Register) -> u64 {
    low: u64;
    high: u64;

    #asm {
        msr === c;
        high === d;
        low === a;

        rdmsr high, low, msr;
    }

    return low | (high << 32);
}

// To get the stack trace after a fault
main_thread_context: *Context;

init_segment_registers :: () #foreign Interrupts;

#program_export
kernel_entry :: () #no_context {

    boot_data = cast(*Boot_Data) 0x10_0000;
    page_frames = boot_data.page_frames.data;

    framebuffer.buffer = cast(*u32) boot_data.framebuffer;
    framebuffer.x_resolution = boot_data.x_resolution;
    framebuffer.y_resolution = boot_data.y_resolution;
    framebuffer.stride = boot_data.stride;

    c: Context;
    c.assertion_failed = (location: Source_Code_Location, message: string) -> bool {
        if message.count {
            serial_out("Assertion failure: ");
            serial_out(message);
            serial_out("\n");
        }

        bluescreen();
        return true;
    };

    c.logger = (message: string, data: *void, info: Log_Info) {
        serial_out(message);
        if message[message.count-1] != #char "\n" {
            serial_out("\n");
        }
    };

    c.print_style.default_format_struct.use_long_form_if_more_than_this_many_members = 2;
    c.print_style.default_format_struct.use_newlines_if_long_form = true;

    push_context c {
        main_thread_context = *context;

        fb := framebuffer;

        for y: 0..fb.y_resolution-1 {
            red := cast(int) (0xff * (1.0 / fb.y_resolution) * y);

            for x: 0..fb.x_resolution-1 {
                green := cast(int) (0xff * (1.0 / fb.x_resolution) * x);
                fb.buffer[x + y * fb.stride] = cast(u32) ((red << 16) | (green << 8));
            }
        }

        // Init memory allocation
        pool_initted := false;
        for 0..boot_data.memory_map_entries_used-1 {
            entry := boot_data.memory_map[it];

            print("Free region at % (% KB)\n", formatInt(entry.address, base=16), entry.pages * 4);

            if entry.pages >= 1024 {
                if !pool_initted {
                    init_physical_page_pool(entry);
                    pool_initted = true;
                } else {
                    init_block_allocator(*kernel_globals.physical_block_allocator, xx entry.address / 4096, xx entry.pages);
                    break;
                }
            }

            if it == boot_data.memory_map_entries_used-1 {
                print("Not enough usable contiguous physical memory found.\n");
                bluescreen();
            }
        }

        context.allocator.proc = (mode: Allocator_Mode, size: s64, old_size: s64, old_memory: *void, allocator_data: *void) -> *void {
            if mode == .ALLOCATE || mode == .RESIZE {
                physical: u64;

                // Minimum allocation size is a page, avoid small allocations
                if size <= 4096 {
                    page := get_page_frame();
                    physical = get_physical_address(page);
                } else {
                    physical = alloc_block(*kernel_globals.physical_block_allocator, size);
                    // Todo: fallback path if a contiguous physical block can't be found
                }

                new := cast(*void) physical + DIRECT_MAPPING_BASE;

                if old_size {
                    memcpy(new, old_memory, old_size);
                }

                page := *page_frames[physical / 4096];
                page.flags |= ifx size <= 4096 then .ALLOCATOR_TAG_SINGLE_PAGE else .ALLOCATOR_TAG_BLOCK;

                return new;
            }

            if mode == .FREE {
                phys := cast(u64) old_memory - DIRECT_MAPPING_BASE;
                index := phys / 4096;

                page := *page_frames[index];

                if page.flags & .ALLOCATOR_TAG_BLOCK {
                    free_block(*kernel_globals.physical_block_allocator, phys);
                } else if page.flags & .ALLOCATOR_TAG_SINGLE_PAGE {
                    release_page_frame(page);
                } else {
                    bluescreen();
                }

                page.flags &= ~(Page_Frame_Desc.Flags.ALLOCATOR_TAG_SINGLE_PAGE | .ALLOCATOR_TAG_BLOCK);
            }

            if mode == .CAPS {
                return cast(*void) Allocator_Caps.FREE | .ACTUALLY_RESIZE | .HINT_I_AM_A_GENERAL_HEAP_ALLOCATOR;
            }

            return null;
        };

        {
            // Put a virtual memory heap after the direct mapping
            GB :: 0x4000_0000;
            direct_mapping_size := boot_data.page_tables.direct_pd.count * GB;

            heap_base := DIRECT_MAPPING_BASE + direct_mapping_size;
            heap_size := 64 * GB;

            init_block_allocator(*virtual_block_allocator, heap_base / 4096, heap_size / 4096);
        }

        ts_buffer := alloc(0x1_0000);
        ts: Temporary_Storage;

        set_initial_data(*ts, 0x1_0000, ts_buffer);
        context.temporary_storage = *ts;

        {
            // Global descriptor table boilerplate
            using Gdt_Entry_Flags;

            global_descriptor_table = Global_Descriptor_Table.{
                0x0,
                READ_WRITE|PRESENT|DESCRIPTOR_TYPE|LONG_MODE_CODE|EXECUTABLE,
                READ_WRITE|PRESENT|DESCRIPTOR_TYPE,
                READ_WRITE|PRESENT|DESCRIPTOR_TYPE|PRIVILEGE0|PRIVILEGE1|LONG_MODE_CODE|EXECUTABLE,
                READ_WRITE|PRESENT|DESCRIPTOR_TYPE|PRIVILEGE0|PRIVILEGE1,
                0xffff_ffff,
            };

            gdt_desc: struct {
                limit: u16;
                base: *Global_Descriptor_Table #align 2;
            }

            gdt_desc.limit = size_of(Global_Descriptor_Table);
            gdt_desc.base = *global_descriptor_table;
            pointer := *gdt_desc;
            #asm { lgdt [pointer]; }

            print("Initting segments\n");
            init_segment_registers();
            print("Initted segments\n");
        }

        {
            // Interrupt descriptor table
            idt_desc: struct {
                limit: u16;
                base: *Interrupt_Gate_Desc #align 2;
            }

            idt_desc.limit = size_of(type_of(interrupt_descriptor_table));
            idt_desc.base = interrupt_descriptor_table.data;

            pointer := *idt_desc;
            #asm { lidt [pointer]; }
        }

        rsdp := cast(*Acpi_RSDP__Root_System_Description_Pointer) boot_data.acpi_rsdp;
        acpi_version = rsdp.revision;

        assert(acpi_version == 0 || acpi_version == 2);

        if acpi_version >= 2 {
            root_acpi_table = xx (rsdp.xsdt_address + DIRECT_MAPPING_BASE);
        } else {
            root_acpi_table = xx (rsdp.rsdt_address + DIRECT_MAPPING_BASE);
        }

        print("Finding facp\n");
        print("FADT: %\n", find_acpi_table("FACP"));

        apic_stuff();
    }

    while true #asm { cli; hlt; }
}

bluescreen :: () {
    using framebuffer;

    for y: 0..y_resolution-1 for x: 0..x_resolution-1 {
        buffer[x + y * stride] = cast(u32) (0xff0000ff);
    }

    serial_out("\nStack trace:\n");
    print_stack_trace(context.stack_trace);

    while true #asm {
        cli;
        hlt;
    }
}

static_to_physical :: (object: *void) -> u64 {
    return cast(u64) object - 0xffff_ffff_8000_0000 + Boot_Data.KERNEL_PHYS_BASE;
}

// A physical memory allocator that finds discontiguous physical pages. Discontiguous pages are more likely to be available and it doesn't usually matter that they're discontiguous. However it's slower for large allocations, not only because the pages need to be found individually, but they also need to be manually mapped so that the virtual memory is contiguous. For physically contiguous memory, there's already corresponding contiguous virtual memory in the direct mapping.

Physical_Page_Pool :: struct {
    start: int; // Page frame index
    page_count: int;
    high_watermark: int;

    freelist: s32 = FREELIST_TAIL;
    FREELIST_TAIL :: Page_Frame_Desc.FREELIST_TAIL;
}

init_physical_page_pool :: (memory: Boot_Data.Memory_Region) {
    using physical_page_pool;

    start = cast(int) (memory.address / 4096);
    page_count = cast(int) memory.pages;
    high_watermark = 0;
    freelist = FREELIST_TAIL;
}

get_page_frame :: () -> *Page_Frame_Desc, int {
    using physical_page_pool;

    if freelist != FREELIST_TAIL {
        page := *page_frames[freelist];
        index := freelist;

        freelist = page.freelist;

        return page, index;
    }

    if high_watermark >= page_count {
        bluescreen();
    }

    index := start + high_watermark;
    page := *page_frames[index];

    high_watermark += 1;

    return page, index;
}

release_page_frame :: (address: u64) {
    release_page_frame(cast(int) (address / 4096));
}

release_page_frame :: (index: int) {
    using physical_page_pool;

    page_frame := *page_frames[index];
    page_frame.freelist = freelist;
    freelist = xx index;
}

release_page_frame :: (page_frame: *Page_Frame_Desc) {
    using physical_page_pool;

    page_frame.freelist = freelist;
    freelist = index(page_frame);
}

get_physical_address :: (page_frame: *Page_Frame_Desc) -> u64 {
    return cast(u64) index(page_frame) * 4096;
}

get_virtual_address :: (page_frame: *Page_Frame_Desc) -> *void {
    phys := get_physical_address(page_frame);
    return cast(*void) phys + DIRECT_MAPPING_BASE;
}

index :: (page_frame: *Page_Frame_Desc) -> s32 {
    index := (cast(u64) page_frame - cast(u64) page_frames) / size_of(Page_Frame_Desc);
    return xx index;
}



get_or_create_page_table :: (table: *u64, entry: u64) -> *u64 {
    using Page_Flags;

    if table[entry] & xx PRESENT {
        physical := table[entry] & (~0xfff);
        return cast(*u64) (physical + DIRECT_MAPPING_BASE);
    }

    page := get_page_frame();
    address := get_physical_address(page);

    table[entry] = address | xx PRESENT | READ_WRITE;

    return cast(*u64) (address + DIRECT_MAPPING_BASE);
}

map_page :: (virtual_address: *void, physical_address: u64, flags := Page_Flags.PRESENT | .READ_WRITE) {
    map_page(cast(u64) virtual_address, physical_address);
}

map_page :: (virtual_address: u64, physical_address: u64, flags := Page_Flags.PRESENT | .READ_WRITE) {
    using Page_Flags;

    mask: u64 = 0b111111111;

    pml4_offset := (virtual_address >> 39) & mask;
    pdpt_offset := (virtual_address >> 30) & mask;
    pd\ _offset := (virtual_address >> 21) & mask;
    pt\ _offset := (virtual_address >> 12) & mask;

    pml4 := boot_data.page_tables.pml4.data;

    pdpt := get_or_create_page_table(pml4, pml4_offset);
    pd   := get_or_create_page_table(pdpt, pdpt_offset);
    pt   := get_or_create_page_table(pd,   pd_offset);

    if pt[pt_offset] & xx PRESENT {
        bluescreen();
    }

    pt[pt_offset] = physical_address | cast(u64) flags;

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



// A block allocator that just linearly scans to find a large enough free block. A block is an integer number of pages.
// Can be used for both virtual and physical memory.

init_block_allocator :: (allocator: *Block_Allocator, start_page: int, total_pages: int) {
    // For bootstrapping, just use a single page to store block descriptors. Todo: fix

    page := get_page_frame();
    allocator.blocks.data = cast(*void) get_physical_address(page) + DIRECT_MAPPING_BASE;
    allocator.max_block_descriptors = 4096 / size_of(Block_Desc);

    allocator.start_page = start_page;
    allocator.total_pages = total_pages;

    allocator.blocks.count = 1;
    allocator.blocks[0] = .{
        start_page = 0,
        size_pages = total_pages,
        used = false,
    };
}

alloc_block :: (using allocator: *Block_Allocator, size_bytes: int) -> u64, Block_Desc {

    pages_needed := size_bytes / 4096;
    if size_bytes % 4096 pages_needed += 1;

    for* blocks {
        if !it.used && it.size_pages >= pages_needed {
            it.used = true;

            remaining_pages := it.size_pages - pages_needed;
            it.size_pages = cast(s32) pages_needed;

            if remaining_pages != 0 {
                // We didn't use the whole block, make a new one and move the others over
                if blocks.count >= max_block_descriptors {
                    bluescreen();
                }

                for< blocks.count .. it_index+2 {
                    blocks[it] = blocks[it-1];
                }
                blocks.count += 1;

                blocks[it_index+1].start_page = it.start_page + pages_needed;
                blocks[it_index+1].size_pages = cast(s32) remaining_pages;
                blocks[it_index+1].used = false;
            }

            return cast(u64) (start_page + it.start_page) * 4096, it.*;
        }
    }

    // If we get here then there wasn't a free block large enough.
    // The system starts with one big block spanning the whole region, and blocks always get coalesced when deallocating, so there's no memory for us.
    bluescreen();
    return 0, .{};
}

free_block :: (allocator: *Block_Allocator, address: u64) -> bool {
    // Find the block corresponding to that address using binary search
    // Todo hash table

    start_page := cast(int) (address / 4096) - allocator.start_page;

    blocks := allocator.blocks;
    defer allocator.blocks = blocks;

    l := 0;
    r := blocks.count - 1;
    m: int;

    while l <= r {
        m = (l + r) / 2;
        page := blocks[m].start_page;

        if page < start_page {
            l = m + 1;
        } else if page > start_page {
            r = m - 1;
        } else break;
    }

    block := *blocks[m];

    if block.start_page != start_page {
        bluescreen();
        return false;
    }

    block.used = false;

    // Coalesce following block
    if blocks.count > m+1 && !blocks[m+1].used {
        block.size_pages += blocks[m+1].size_pages;

        for m+2 .. blocks.count-1 {
            blocks[it-1] = blocks[it];
        }
        blocks.count -= 1;
    }

    // Coalesce preceding block
    if m > 0 && !blocks[m-1].used {
        blocks[m-1].size_pages += block.size_pages;

        for m+1 .. blocks.count-1 {
            blocks[it-1] = blocks[it];
        }
        blocks.count -= 1;
    }

    return true;
}

Block_Desc :: struct {
    start_page: s64; // Relative to the start of the allocator's region
    size_pages: s64;
    used: bool;
}

Block_Allocator :: struct {
    blocks: [] Block_Desc;
    max_block_descriptors: int;

    start_page: int;
    total_pages: int;
}



serial_out :: (data: string) {
    COM1 :: 0x3f8;

    for cast([] u8) data {
        for 1..1_0000 {
            status: u8;
            port := COM1 + 5;

            #asm {
                status === a;
                port   === d;
                in.b status, port;
            }

            if status & 0x20 break;

            #asm { pause; }
        }

        byte := it;
        port := COM1;

        #asm {
            byte === a;
            port === d;
            out.b port, byte;
        }
    }
}

serial_write_hex :: (value: $T) {
    v := cast,no_check(u64) value;

    hex_chars := "0123456789abcdef";
    result: [16] u8;

    for 0..15 {
        result[it] = hex_chars[(v >> (60 - it * 4)) & 0xF];
    }

    serial_out(cast(string) result);
    serial_out("\n");
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
    serial_out("Num levels: "); serial_write_hex(xx levels);

    freelists.data = cursor;
    freelists.count = levels;
    cursor += freelists.count * size_of(int);

    bitmap.count = 2 * (size / 4096) - 1;
    serial_out("Bitmap bits: "); serial_write_hex(xx bitmap.count);
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

    serial_out("Level: "); serial_write_hex(xx level);
    serial_out("b0: ");    serial_write_hex(xx b0);
    serial_out("b1: ");    serial_write_hex(xx b1);

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

    return cast(u64) (b0 * 4096);
}
