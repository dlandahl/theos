
#import "Basic";
#import "Machine_X64";

#import "Bitfield";
set :: bitfield_set;

#load "../boot_data.jai";

#load "apic.jai";
#load "x64.jai";
#load "journal.jai";
#load "pci_express.jai";
#load "multitasking.jai";
#load "time.jai";

X64_Core :: struct {
    // It might make sense to #add_context this because there's one per core, but many procedures are called from interrupt routines so you would have to always manually set it.

    task_state_segment: Tss_With_Iopb #align 0x80;

    // Align to cache block so no extra memory accesses are required on context switch
    global_descriptor_table: Global_Descriptor_Table #align 64;

    local_apic_id: u32;
    id: int;

    scheduler: Scheduler;
}

Kernel_Globals :: struct {
    using boot_data: *Boot_Data;

    physical_page_pool: Physical_Page_Pool;
    physical_block_allocator: Block_Allocator;
    virtual_block_allocator: Block_Allocator;

    root_acpi_table: *Acpi_Table_Header;
    acpi_version: int;
    fadt: *acpi_fadt;

    // Hardware requires 16 byte alignment on IDT
    interrupt_descriptor_table: [256] Interrupt_Gate_Descriptor #align 16;
    next_free_interrupt_gate: int;

    // It's not good how we're using resizable arrays in various places that get reallocated and make behavior less consistent and predictable. Better to use something like the Bucket_Array
    processor_cores: [..] X64_Core;

    apic: *void;
    io_apic: *u32;
    local_apic_timer_interrupt_gate: int;

    high_precision_timer: HPET;

    main_thread_context: #Context;

    memory_spinlock: Spinlock;

    tasks: Bucket_Array(Task_Info, 256, always_iterate_by_pointer=true);
    next_task_id: int;
    add_task_info_struct_spinlock: Spinlock;

    boot_time: Apollo_Time;
    rtc_format_is_bcd: bool;
}

kernel_globals: Kernel_Globals;

Interrupts :: #library,no_dll "../.build/interrupts";

#program_export
kernel_entry :: () #no_context {
    using kernel_globals;

    // We should avoid using the UEFI identity map because we'll need to get rid of it once we run user processes in low memory.
    boot_data = cast(*Boot_Data) (Boot_Data.BASE_ADDRESS + DIRECT_MAPPING_BASE);

    // Init memory allocation
    pool_initted := false;
    for 0..boot_data.memory_map_entries_used-1 {
        region := boot_data.memory_map[it];
        if region.type != .FREE continue;

        if region.pages >= 1024 {
            if !pool_initted {
                init_physical_page_pool(region);
                pool_initted = true;
            } else {
                init_block_allocator(*physical_block_allocator, xx region.address / 4096, xx region.pages);
                break;
            }
        }

        if it == boot_data.memory_map_entries_used-1 {
            write_string("Not enough usable contiguous physical memory found.\n");
            bluescreen();
        }
    }

    memory_map_index: int;
    for* page, page_index: large_pages {
        base  := page_index * 0x20_0000;
        limit := base       + 0x20_0000;

        for memory_map_index..memory_map_entries_used-1 {

            region_limit := memory_map[it].pages*4096 + memory_map[it].address;

            if region_limit <= cast(u64) base {
                continue;
            }

            if memory_map[it].address >= cast(u64) limit {
                memory_map_index -= 1;
                continue page;
            }

            if memory_map[it].type != .FREE {
                page.type = .RESERVED;
                continue page;
            }

            memory_map_index += 1;
        }
    }

    make_kernel_context(*main_thread_context);

    push_context main_thread_context {

        rtc_init();


        using framebuffer;

        for y: 0..y_resolution-1 {
            for x: 0..x_resolution-1 {
                red   := cast(int) (0xff * (1.0 / y_resolution) * y);
                green := cast(int) (0xff * (1.0 / x_resolution) * x);

                buffer[x + y * stride] = cast(u32) ((red << 16) | (green << 8));
            }
        }


        // Put a virtual memory heap after the direct mapping
        GB :: 0x4000_0000;
        direct_mapping_size := boot_data.page_tables.direct_pd.count * GB;

        heap_base := DIRECT_MAPPING_BASE + direct_mapping_size;
        heap_size := 64 * GB;

        init_block_allocator(*virtual_block_allocator, heap_base / 4096, heap_size / 4096);


        // Sequentially allocating interrupt gates, starting after the ISA exceptions
        memset(interrupt_descriptor_table.data, 0, size_of(type_of(interrupt_descriptor_table)));
        next_free_interrupt_gate = 32;


        rsdp := cast(*Acpi_RSDP__Root_System_Description_Pointer) boot_data.acpi_rsdp;
        acpi_version = rsdp.revision;

        assert(acpi_version == 0 || acpi_version == 2);

        if acpi_version >= 2 {
            root_acpi_table = xx (rsdp.xsdt_address + DIRECT_MAPPING_BASE);
        } else {
            root_acpi_table = xx (rsdp.rsdt_address + DIRECT_MAPPING_BASE);
        }


        initialize_apic();

        initialize_hpet();
        hpet_configure_timer(timer_index = 0, frequency = 10, true);


        task_switch :: () #foreign Interrupts;
        register_interrupt_gate(task_switch, TASK_SWITCH_GATE);

        tasks.allocator = context.allocator;
        next_task_id = 1;

        // uacpi_context_set_log_level(.DEBUG);

        // if uacpi_initialize(0) != .OK bluescreen();

        // fadt = New(acpi_fadt);
        // if uacpi_table_fadt(*fadt) != .OK bluescreen();

        // Get the time at the most recent second. Maybe use an interrupt to detect a more accurate boot time.
        boot_calendar_time := rtc_get_calendar_time();
        // Don't use Basic.calendar_to_apollo, because it's OS specific
        boot_time = native_calendar_to_apollo(boot_calendar_time);

        print_physical_memory_map();

        core_begin_multitasking();

        startup_application_processors();

        core := get_current_core();
        for 1..4 {
            new_task := create_task();
            put_task_on_core(new_task, core);
        }

        size := page_frames.count * size_of(Page_Frame_Desc);
        print("Size of large pages: % kb\n", size / 1024);

        #asm { sti; }

        while true {
            time := get_monotonic_system_time();
            calendar := native_apollo_to_calendar(time);
            print("Time: %\n", calendar_to_string(calendar));

            print("This is thread % running on core %\n", core.scheduler.current_task.id, core.id);
            sleep_until(time + milliseconds_to_apollo(1000));
        }
    }
}


#program_export
simd_floating_point_exception :: (stack: *Interrupt_Stack()) #c_call {

    mxcsr: Mxcsr;
    pmxcsr := *mxcsr;

    #asm {
        stmxcsr [pmxcsr];
    }

    push_context {
        print("Floating point exception: % target: %\n", mxcsr);
    }
} @InterruptRoutine


make_kernel_context :: (c: *#Context) #no_context {
    initializer_of(#Context)(c); 

    c.assertion_failed = (location: Source_Code_Location, message: string) -> bool {
        write_string("Assertion failure");
        if message.count {
            write_strings(": ", message);
        }
        write_string("\n");

        print_stack_trace(context.stack_trace);
        bluescreen(location);
        return true;
    };

    c.logger = (message: string, data: *void, info: Log_Info) {
        write_string(message);
        if message[message.count-1] != #char "\n" {
            write_string("\n");
        }
    };

    c.print_style.default_format_struct.use_long_form_if_more_than_this_many_members = 2;
    c.print_style.default_format_struct.use_newlines_if_long_form = true;

    c.allocator.proc = (mode: Allocator_Mode, size: s64, old_size: s64, old_memory: *void, allocator_data: *void) -> *void {
        Scoped_Acquire(*kernel_globals.memory_spinlock);

        if mode == .ALLOCATE || mode == .RESIZE {
            physical: u64;

            use_block_allocator := size > 4096;

            if use_block_allocator {
                // Todo: attempt to grow existing block in case of resize
                physical = alloc_block(*kernel_globals.physical_block_allocator, size);
            } else {
                page := get_page_frame();
                physical = get_physical_address(page);
            }

            new := cast(*void) physical + DIRECT_MAPPING_BASE;

            if mode == .RESIZE {
                memcpy(new, old_memory, old_size);
                // #this(.FREE, old_size, 0, old_memory, null);
            }

            page := *kernel_globals.page_frames[physical / 4096];
            page.flags |= ifx use_block_allocator then .ALLOCATOR_TAG_BLOCK else .ALLOCATOR_TAG_SINGLE_PAGE;

            return new;
        }

        if mode == .FREE {
            if old_memory == null {
                return null;
            }

            phys := cast(u64) old_memory - DIRECT_MAPPING_BASE;
            index := phys / 4096;

            page := *kernel_globals.page_frames[index];

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
            return cast(*void) Allocator_Caps.FREE | .HINT_I_AM_A_GENERAL_HEAP_ALLOCATOR;
        }

        return null;
    };

    if true {
        acquire(*kernel_globals.memory_spinlock);
        ts_buffer_block := alloc_block(*kernel_globals.physical_block_allocator, 0x2000);
        c.temporary_storage = cast(*Temporary_Storage) get_virtual_address(get_page_frame());
        release(*kernel_globals.memory_spinlock);

        ts_buffer := cast(*void) ts_buffer_block + DIRECT_MAPPING_BASE;

        set_initial_data(c.temporary_storage, 0x2000, ts_buffer);

        c.temporary_storage.overflow_allocator = c.allocator;
    }
}

init_processor_core :: () #no_context {
    core: *X64_Core;

    enable_cpu_features();

    {
        my_local_apic_id := read_apic_register(.APIC_ID) >> 24;

        for* kernel_globals.processor_cores {
            if it.local_apic_id == my_local_apic_id {
                core = it;
                break;
            }
        }
        if !core bluescreen();

        #asm FSGSBASE { wrgsbase core; }
    }

    {
        // Global descriptor table

        // Use the IO Permission Bitmap to give user mode access to all IO ports for now
        memset(core.task_state_segment.bitmap.data, 0, 8192);
        core.task_state_segment.iopb = size_of(Task_State_Segment);

        tss_desc: System_Segment_Descriptor;
        tss_address := cast(u64) *core.task_state_segment;

        tss_desc.segment_limit = size_of(Tss_With_Iopb);
        tss_desc.base_address_0 = cast(u16)  tss_address;
        tss_desc.base_address_1 = cast(u8)  (tss_address >> 16);
        tss_desc.base_address_2 = cast(u8)  (tss_address >> 24);
        tss_desc.base_address_3 = cast(u32) (tss_address >> 32);
        tss_desc.flags_0        = 0b1_00_0_1001; // type=TSS non-busy | PRESENT

        using Gdt_Entry_Flags;

        core.global_descriptor_table = Global_Descriptor_Table.{
            0x0,
            READ_WRITE | PRESENT | DESCRIPTOR_TYPE | LONG_MODE_CODE | EXECUTABLE,
            READ_WRITE | PRESENT | DESCRIPTOR_TYPE,
            READ_WRITE | PRESENT | DESCRIPTOR_TYPE | PRIVILEGE0 | PRIVILEGE1,
            READ_WRITE | PRESENT | DESCRIPTOR_TYPE | PRIVILEGE0 | PRIVILEGE1 | LONG_MODE_CODE | EXECUTABLE,
            tss_desc,
            0xffff_ffff,
        };

        gdt_desc: struct {
            limit: u16;
            base: *Global_Descriptor_Table #align 2;
        }

        gdt_desc.limit = size_of(Global_Descriptor_Table);
        gdt_desc.base = *core.global_descriptor_table;
        pointer := *gdt_desc;
        #asm { lgdt [pointer]; }

        #bytes .[
            0x66, 0xb8, 0x28, 0x00, // mov ax, 0x28
            0x0f, 0x00, 0xd8        // ltr ax
        ];

        init_segment_registers :: () #foreign Interrupts;
        init_segment_registers();
    }

    {
        // Interrupt descriptor table
        idt_desc: struct {
            limit: u16;
            base: *Interrupt_Gate_Descriptor #align 2;
        }

        idt_desc.limit = size_of(type_of(kernel_globals.interrupt_descriptor_table));
        idt_desc.base = kernel_globals.interrupt_descriptor_table.data;

        pointer := *idt_desc;
        #asm { lidt [pointer]; }
    }

    {
        // Enable syscalls

        // According to https://www.felixcloutier.com/x86/sysret, sysret sets the privilege bits in the stack segment selector automatically, but this does not seem to happen in VirtualBox.
        star := (cast(u64) Segment_Selector.RING0_DATA | 3) << 48;
        star |= (cast(u64) Segment_Selector.RING0_CODE)     << 32;
        write_msr(.STAR__syscall_segment, star);
        write_msr(.SFMASK__syscall_flags, 0);

        syscall_entry :: () #foreign Interrupts;
        write_msr(.LSTAR__syscall_address, cast(u64) cast(*void) syscall_entry);

        EFER_SCE__syscall_enable :: 1;

        efer := read_msr(.EFER__extended_features);
        efer |= EFER_SCE__syscall_enable;
        write_msr(.EFER__extended_features, efer);
    }
}

bluescreen :: (loc := #caller_location) #no_context {
    using kernel_globals.framebuffer;

    for y: 0..y_resolution-1 for x: 0..x_resolution-1 {
        buffer[x + y * stride] = cast(u32) (0xff0000ff);
    }

    write_string("Bluescreen!\nSource code location:\n");
    write_loc(loc);

    while true #asm {
        cli;
        hlt;
    }
}

// A physical memory allocator that finds discontiguous physical pages. Discontiguous pages are more likely to be available and it doesn't usually
// matter that they're discontiguous. However it's slower for large allocations, not only because the pages need to be found individually, but they
// also need to be manually mapped so that the virtual memory is contiguous. For physically contiguous memory, there's already corresponding
// contiguous virtual memory in the direct mapping.

Physical_Page_Pool :: struct {
    start: int; // Page frame index
    page_count: int;
    high_watermark: int;

    freelist: s32 = FREELIST_TAIL;
    FREELIST_TAIL :: Page_Frame_Desc.FREELIST_TAIL;
}

init_physical_page_pool :: (memory: Boot_Data.Memory_Region) #no_context {
    using kernel_globals.physical_page_pool;

    start = cast(int) (memory.address / 4096);
    page_count = cast(int) memory.pages;
    high_watermark = 0;
    freelist = FREELIST_TAIL;
}

get_page_frame :: () -> *Page_Frame_Desc, int #no_context {
    using kernel_globals.physical_page_pool;

    if freelist != FREELIST_TAIL {
        page := *kernel_globals.page_frames[freelist];
        index := freelist;

        freelist = page.freelist;

        return page, index;
    }

    if high_watermark >= page_count {
        bluescreen();
    }

    index := start + high_watermark;
    page := *kernel_globals.page_frames[index];

    high_watermark += 1;

    return page, index;
}

release_page_frame :: (address: u64) {
    release_page_frame(cast(int) (address / 4096));
}

release_page_frame :: (index: int) {
    using kernel_globals.physical_page_pool;

    page_frame := *kernel_globals.page_frames[index];
    page_frame.freelist = freelist;
    freelist = xx index;
}

release_page_frame :: (page_frame: *Page_Frame_Desc) {
    using kernel_globals.physical_page_pool;

    page_frame.freelist = freelist;
    freelist = index(page_frame);
}

get_physical_address :: (page_frame: *Page_Frame_Desc) -> u64 #no_context {
    return cast(u64) index(page_frame) * 4096;
}

get_virtual_address :: (page_frame: *Page_Frame_Desc) -> *void #no_context {
    phys := get_physical_address(page_frame);
    return cast(*void) phys + DIRECT_MAPPING_BASE;
}

index :: (page_frame: *Page_Frame_Desc) -> s32 #no_context {
    index := (cast(u64) page_frame - cast(u64) kernel_globals.page_frames.data) / size_of(Page_Frame_Desc);
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

map_page :: (virtual_address: u64, physical_address: u64, flags := Page_Flags.PRESENT | .READ_WRITE, loc := #caller_location) {
    using Page_Flags;

    mask: u64 = 0b111111111;

    pml4_offset := (virtual_address >> 39) & mask;
    pdpt_offset := (virtual_address >> 30) & mask;
    pd\ _offset := (virtual_address >> 21) & mask;
    pt\ _offset := (virtual_address >> 12) & mask;

    pml4 := kernel_globals.boot_data.page_tables.pml4.data;

    pdpt := get_or_create_page_table(pml4, pml4_offset);
    pd   := get_or_create_page_table(pdpt, pdpt_offset);
    pt   := get_or_create_page_table(pd,   pd_offset);

    if pt[pt_offset] & xx PRESENT {
        bluescreen(loc);
    }

    pt[pt_offset] = physical_address | cast(u64) flags;

    pg := *virtual_address;
    #asm {
        invlpg [pg];
    }
}

Page_Flags :: enum_flags u64 {
    PRESENT         :: 1 << 0 | Page_Flags.USER_SUPERVISOR;
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
// Is being used for both virtual and physical memory.

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

init_block_allocator :: (allocator: *Block_Allocator, start_page: int, total_pages: int) #no_context {
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

alloc_block :: (using allocator: *Block_Allocator, size_bytes: int, loc := #caller_location) -> address: u64, Block_Desc #no_context {

    pages_needed := size_bytes / 4096;
    if size_bytes % 4096 pages_needed += 1;

    for* blocks {
        if !it.used && it.size_pages >= pages_needed {
            it.used = true;

            remaining_pages := it.size_pages - pages_needed;
            it.size_pages = cast(s32) pages_needed;

            if remaining_pages != 0 {
                // We didn't use the whole block, make a new one and move the others over
                if blocks.count >= max_block_descriptors-1 {
                    bluescreen();
                }

                blocks.count += 1;
                for#v2< it_index+2 .. blocks.count-1 {
                    blocks[it] = blocks[it-1];
                }

                blocks[it_index+1].start_page = it.start_page + pages_needed;
                blocks[it_index+1].size_pages = cast(s32) remaining_pages;
                blocks[it_index+1].used = false;
            }

            return cast(u64) (start_page + it.start_page) * 4096, it.*;
        }
    }

    // If we get here then there isn't a free block large enough
    bluescreen(loc);
    return 0, .{};
}

free_block :: (allocator: *Block_Allocator, address: u64) -> bool {
    // Find the block corresponding to that address using linear search
    // Todo hash table

    start_page := cast(int) (address / 4096) - allocator.start_page;

    blocks := allocator.blocks;
    defer allocator.blocks = blocks;

    m := -1;

    for blocks {
        if it.start_page == start_page {
            m = it_index;
            break;
        }
    }

    if m == -1 {
        print_stack_trace(context.stack_trace);
        bluescreen();
        return false;
    }

    block := *blocks[m];
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

    // Note that this is only aligned to 4 bytes, so if you put this in a struct followed by a u64, it will be wrong.
} #no_padding

find_acpi_table :: (signature: string) -> *Acpi_Table_Header {
    table_size := kernel_globals.root_acpi_table.length - size_of(Acpi_Table_Header);

    pointer_size := cast(u64) (ifx kernel_globals.acpi_version then 8 else 4);
    pointer_count := table_size / pointer_size;

    table_base := cast(u64) (kernel_globals.root_acpi_table + 1);

    for table_index: 0..pointer_count - 1 {
        offset := table_index * pointer_size + table_base;

        phys := ifx kernel_globals.acpi_version {
            << cast(*u64) offset;
        } else {
            cast(u64) << cast(*u32) offset;
        }

        header := cast(*Acpi_Table_Header) (phys + DIRECT_MAPPING_BASE);

        for 0..3 if header.signature[it] != signature[it] {
            continue table_index;
        }

        return header;
    }

    return null;
}



// This is implemented in Runtime_Support, so that write_string can go to serial
// serial_out :: (data: string)



load_fence :: () #expand {
    #asm { lfence; }
}

store_fence :: () #expand {
    #asm { sfence; }
}

memory_fence :: () #expand {
    #asm { mfence; }
}



Spinlock :: #type,distinct u32;

acquire :: (lock: *Spinlock) #no_context {
    carry: u8 = 1;

    while carry {
        while lock.* {
            #asm { pause; }
        }

        #asm {
            lock_bts.d [lock], 0;
            setc carry;
        }
    }

    memory_fence();
}

release :: (lock: *Spinlock) #no_context {
    memory_fence();

    if !lock.* bluescreen();
    lock.* = 0;
}

Scoped_Acquire :: (lock: *Spinlock) #expand {
    acquire(lock);
    `defer release(lock);
}



Sequence_Lock :: #type,distinct u32;

sequence_read :: (lock: *Sequence_Lock, body: Code) #expand {
    while true {
        sequence: Sequence_Lock;

        while true {
            sequence = lock.*;

            if (sequence & 1) == 0 break;

            #asm { pause; pause; pause; pause; }
        }
        load_fence();

        #insert body;

        load_fence();
        if lock.* == sequence break;
    }
}

sequence_write :: (lock: *Sequence_Lock, body: Code) #expand {
    lock.* += 1;
    store_fence();

    #insert body;

    store_fence();
    lock.* += 1;
}



allocate_interrupt_gate :: (loc := #caller_location) -> int {
    using kernel_globals;

    if next_free_interrupt_gate == TASK_SWITCH_GATE {
        // Some gates need to be reserved as constants so they can be used in instruction immediates.
        // In the future we might need to support allocating specific gates anyway.
        next_free_interrupt_gate += 1;
    }

    assert(next_free_interrupt_gate < 0xff);

    result := next_free_interrupt_gate;
    next_free_interrupt_gate += 1;
    return result;
}




print_physical_memory_map :: () {
    using kernel_globals;
    context.print_style.default_format_float.trailing_width = 2;

    total_by_type: [5] float;
    for 0..boot_data.memory_map_entries_used-1 {

        region := boot_data.memory_map[it];
        mb := (cast(float) region.pages * 4096) / 0x20_0000;
        print("Region (%) at % (% blocks)\n", region.type, formatInt(region.address, base=16), mb);

        total_by_type[region.type] += cast(int) region.pages;

        if false for 0..cast(int) mb-1 {
            if region.type == {
                case .FREE; print("-");
                case .RESERVED_BY_THE_BOOTLOADER; print("+");
                case .RESERVED_BY_FIRMWARE; print("=");
                case .DONT_KNOW; print("?");
            }
        }
    }

    print("\n\n\n");

    context.print_style.default_format_float.trailing_width = 2;
    for total_by_type {
        print("Total (%) % MB\n=======\n", cast(type_of(Memory_Region.type)) it_index, it / 256);
    }

    for boot_data.large_pages {
        print("[%] %\n", it_index, it.type);
    }
}
