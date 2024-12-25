
#import "Basic";
#import "Machine_X64";

#load "../boot_data.jai";

#load "acpi.jai";
#load "x64.jai";
#load "journal.jai";
#load "pci_express.jai";
#load "multitasking.jai";

Kernel_Globals :: struct {
    using boot_data: *Boot_Data;

    physical_page_pool: Physical_Page_Pool;
    physical_block_allocator: Block_Allocator;
    virtual_block_allocator: Block_Allocator;

    root_acpi_table: *Acpi_Table_Header;
    acpi_version: int;

    interrupt_descriptor_table: [256] Interrupt_Gate_Desc #align 16; // Hardware requires 16 byte alignment on IDT
    global_descriptor_table: Global_Descriptor_Table #align 64; // Align to cache block so no extra memory accesses are required on context switch
    task_state_segment: Tss_With_Iopb #align 0x80;

    next_free_interrupt_gate: int;

    apic: *void;
    io_apic: *u32;

    high_precision_timer: HPET;

    temporary_storage: Temporary_Storage;
    temporary_storage_buffer: [TEMPORARY_STORAGE_SIZE] u8 #align 64;

    main_thread_context: Context;
    scheduler: Scheduler;
}

kernel_globals: Kernel_Globals;

Interrupts :: #library,no_dll "../.build/interrupts";
init_segment_registers :: () #foreign Interrupts;

#program_export
kernel_entry :: () #no_context {
    using kernel_globals;

    // We should avoid using the UEFI identity map because we'll need to get rid of it once we run user processes in low memory.
    boot_data = cast(*Boot_Data) (Boot_Data.BASE_ADDRESS + DIRECT_MAPPING_BASE);

    main_thread_context.assertion_failed = (location: Source_Code_Location, message: string) -> bool {
        write_string("Assertion failure");
        if message.count {
            write_strings(": ", message);
        }
        write_string("\n");

        bluescreen(location);
        return true;
    };

    main_thread_context.logger = (message: string, data: *void, info: Log_Info) {
        write_string(message);
        if message[message.count-1] != #char "\n" {
            write_string("\n");
        }
    };

    set_initial_data(*temporary_storage, TEMPORARY_STORAGE_SIZE, temporary_storage_buffer.data);
    main_thread_context.temporary_storage = *temporary_storage;

    main_thread_context.print_style.default_format_struct.use_long_form_if_more_than_this_many_members = 2;
    main_thread_context.print_style.default_format_struct.use_newlines_if_long_form = true;

    push_context main_thread_context {

        using framebuffer;

        for y: 0..y_resolution-1 {
            for x: 0..x_resolution-1 {
                red   := cast(int) (0xff * (1.0 / y_resolution) * y);
                green := cast(int) (0xff * (1.0 / x_resolution) * x);

                buffer[x + y * stride] = cast(u32) ((red << 16) | (green << 8));
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

                use_block_allocator := size > 4096;

                if use_block_allocator {
                    // Todo: attempt to grow existing block in case of resize
                    physical = alloc_block(*kernel_globals.physical_block_allocator, size);
                } else {
                    page := get_page_frame();
                    physical = get_physical_address(page);
                }

                new := cast(*void) physical + DIRECT_MAPPING_BASE;

                if old_size {
                    memcpy(new, old_memory, old_size);
                    #this(.FREE, old_size, 0, old_memory, null);
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

        {
            // Put a virtual memory heap after the direct mapping
            GB :: 0x4000_0000;
            direct_mapping_size := boot_data.page_tables.direct_pd.count * GB;

            heap_base := DIRECT_MAPPING_BASE + direct_mapping_size;
            heap_size := 64 * GB;

            init_block_allocator(*virtual_block_allocator, heap_base / 4096, heap_size / 4096);
        }

        {
            // Global descriptor table

            // Use IOPB to give user mode access to IO ports for now
            memset(task_state_segment.bitmap.data, 0, 8192);
            task_state_segment.iopb = size_of(Task_State_Segment);

            tss_desc: System_Segment_Descriptor;
            tss_address := cast(u64) *task_state_segment;

            tss_desc.segment_limit = size_of(Tss_With_Iopb);
            tss_desc.base_address_0 = cast(u16)  tss_address;
            tss_desc.base_address_1 = cast(u8)  (tss_address >> 16);
            tss_desc.base_address_2 = cast(u8)  (tss_address >> 24);
            tss_desc.base_address_3 = cast(u32) (tss_address >> 32);
            tss_desc.flags_0        = 0b1_00_0_1001; // type=TSS non-busy | PRESENT

            using Gdt_Entry_Flags;

            global_descriptor_table = Global_Descriptor_Table.{
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
            gdt_desc.base = *global_descriptor_table;
            pointer := *gdt_desc;
            #asm { lgdt [pointer]; }

            #bytes .[
                0x66, 0xb8, 0x28, 0x00, // mov ax, 0x28
                0x0f, 0x00, 0xd8        // ltr ax
            ];

            init_segment_registers();
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

            next_free_interrupt_gate = 32; // Sequentially allocating interrupt gates, starting after the ISA exceptions
        }

        rsdp := cast(*Acpi_RSDP__Root_System_Description_Pointer) boot_data.acpi_rsdp;
        acpi_version = rsdp.revision;

        assert(acpi_version == 0 || acpi_version == 2);

        if acpi_version >= 2 {
            root_acpi_table = xx (rsdp.xsdt_address + DIRECT_MAPPING_BASE);
        } else {
            root_acpi_table = xx (rsdp.rsdt_address + DIRECT_MAPPING_BASE);
        }

        apic_stuff();
        initialize_hpet();

        for 1..10 {
            // Calibrate Local APIC timer using HPET
            hpet_configure_timer(timer_index = 1, frequency = 10, periodic = false);
            hpet_restart();

            write_apic_register(.TIC__TIMER_INITIAL, 0xffff_ffff);
            write_apic_register(.DV__TIMER_DIVIDE, 0b011);

            while kernel_globals.high_precision_timer.counters[1] == 0 {
                #asm { hlt; }
            }

            apic_ticks_elapsed := 0xffff_ffff - read_apic_register(.TCC__TIMER_CURRENT);
            print("APIC ticks in 100ms: %\n", apic_ticks_elapsed);
        }

        // uacpi_context_set_log_level(.DEBUG);
        // 
        // acpi_init_result := uacpi_initialize(0);
        // if acpi_init_result != .OK {
        //     log_error("uACPI initalize failed with status \"%\"", acpi_init_result);
        // }

        enable_cpu_features();

        find_all_pci_devices();

        for pci_devices {
            print("Device at 0x%, %\n", cast(*void) it.configuration_space, it.configuration_space.class_code);
        }

        // Enable syscalls

        star := (cast(u64) Segment_Selector.RING0_DATA) << 48;
        star |= (cast(u64) Segment_Selector.RING0_CODE) << 32;
        write_msr(.STAR__syscall_segment, star);
        write_msr(.SFMASK__syscall_flags, ~0);

        syscall_entry :: () #foreign Interrupts;
        write_msr(.LSTAR__syscall_address, cast(u64) cast(*void) syscall_entry);

        EFER_SCE__syscall_enable :: 1;

        efer := read_msr(.EFER__extended_features);
        efer |= EFER_SCE__syscall_enable;
        write_msr(.EFER__extended_features, efer);

        start_multitasking();
    }

    while true #asm {
        hlt;
    }
}

bluescreen :: (loc := #caller_location) #no_context {
    using kernel_globals.framebuffer;

    for y: 0..y_resolution-1 for x: 0..x_resolution-1 {
        buffer[x + y * stride] = cast(u32) (0xff0000ff);
    }

    write_string("\nSource code location:\n");
    write_loc(loc);
    // print_stack_trace(context.stack_trace);

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

init_physical_page_pool :: (memory: Boot_Data.Memory_Region) {
    using kernel_globals.physical_page_pool;

    start = cast(int) (memory.address / 4096);
    page_count = cast(int) memory.pages;
    high_watermark = 0;
    freelist = FREELIST_TAIL;
}

get_page_frame :: () -> *Page_Frame_Desc, int {
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

get_physical_address :: (page_frame: *Page_Frame_Desc) -> u64 {
    return cast(u64) index(page_frame) * 4096;
}

get_virtual_address :: (page_frame: *Page_Frame_Desc) -> *void {
    phys := get_physical_address(page_frame);
    return cast(*void) phys + DIRECT_MAPPING_BASE;
}

index :: (page_frame: *Page_Frame_Desc) -> s32 {
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

map_page :: (virtual_address: u64, physical_address: u64, flags := Page_Flags.PRESENT | .READ_WRITE) {
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

alloc_block :: (using allocator: *Block_Allocator, size_bytes: int) -> address: u64, Block_Desc {

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

    // If we get here then there isn't a free block large enough
    bluescreen();
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



// This is implemented in Runtime_Support, so that write_string can go to serial
// serial_out :: (data: string)



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
}

release :: (lock: *Spinlock) #no_context {
    lock.* = 0;
}

Scoped_Acquire :: (lock: *Spinlock) #expand {
    acquire(lock);
    `defer release(lock);
}


allocate_interrupt_gate :: () -> int {
    using kernel_globals;

    if next_free_interrupt_gate == TASK_SWITCH_GATE {
        // Some gates need to be reserved as constants so they can be used in instruction immediates.
        // In the future we might need to support allocating specific gates anyway.
        next_free_interrupt_gate += 1;
    }

    result := next_free_interrupt_gate;
    next_free_interrupt_gate += 1;
    return result;
}
