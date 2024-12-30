
#import "Bucket_Array";

Task_Info :: struct {

    using cpu_context: struct {
        // These fields must match the task switch assembly routine
        rsp: *void;
        cr3: u64;
        xsave: Xsave_Area;
    };

    user_stack:   *void;
    kernel_stack: *void;

    id: int;

    sleeping: bool;
    sleeping_until: Apollo_Time;
}

TASK_SWITCH_GATE :: 64;

Scheduler :: struct {
    current_task: [..] *Task_Info;

    sleeping:       [..] *Task_Info;
    waiting_to_run: Queue(*Task_Info);

    tasks: Bucket_Array(Task_Info, 256, always_iterate_by_pointer=true);
    next_id: int;

    spinlock: Spinlock;
}

Xsave_Area :: struct {
    // Warning: this struct requires 16-byte alignment to be accessed by fxsave64 etc.
    fpu: [512] u8;

#place fpu;
    pad: [24] u8;
    mxcsr: Mxcsr;
}

initialize_scheduler :: () {
    task_switch :: () #foreign Interrupts;
    register_interrupt_gate(task_switch, TASK_SWITCH_GATE);

    using kernel_globals;
    scheduler = .{};

    scheduler.tasks.allocator = context.allocator;
    scheduler.next_id = 1;
    array_resize(*scheduler.current_task, processor_cores.count);

    array_reserve(*scheduler.sleeping, 256);
    queue_reserve(*scheduler.waiting_to_run, 256);
}

core_begin_multitasking :: () {
    using kernel_globals;

    Scoped_Acquire(*scheduler.spinlock);

    locator, main_task := bucket_array_add(*scheduler.tasks, .{});

    main_task.cr3 = cast(u64) *page_tables.pml4 - DIRECT_MAPPING_BASE;
    main_task.id  = scheduler.next_id;

    scheduler.next_id += 1;

    core := get_current_core();
    scheduler.current_task[core.id] = main_task;

    {
        // Enable Local APIC timer interrupts
        lapic_timer_gate := allocate_interrupt_gate();
        register_interrupt_gate(int__local_apic_timer_interrupt, lapic_timer_gate);

        spurious := read_apic_register(.SPURIOUS_INTERRUPT);
        write_apic_register(.SPURIOUS_INTERRUPT, spurious | 0x1ff);

        write_apic_register(.TIC__TIMER_INITIAL, 0x0400_0000);

        lvtt: Apic_Local_Vector_Table_Entry;
        lvtt.vector = cast(u8) lapic_timer_gate;
        lvtt.flags &= ~.M__mask;
        lvtt.flags |= .TMM__timer_mode;
        write_apic_register(.LVT__TIMER, << cast(*u32) *lvtt);
    }
}

create_task :: () -> *Task_Info {
    using kernel_globals;

    // Scoped_Acquire(*scheduler.spinlock);

    locator, new_task := bucket_array_add(*scheduler.tasks, .{});
    new_task.cr3 = cast(u64) *page_tables.pml4 - DIRECT_MAPPING_BASE;

    new_task.user_stack   = alloc(0x1_0000) + 0x1_0000;
    new_task.kernel_stack = alloc(0x1_0000) + 0x1_0000;

    stack := cast(*Interrupt_Stack) new_task.kernel_stack - 1;
    stack.flags = .IF__interrupt;
    stack.cs = .RING0_CODE;
    stack.ss = .RING0_DATA;
    stack.ip = cast(*void) task_do_work;
    stack.sp = new_task.kernel_stack;

    new_task.rsp = cast(*void) stack;
    new_task.id = scheduler.next_id;
    scheduler.next_id += 1;

    // For now, copy FP exception settings from the parent thread
    mxcsr := *new_task.xsave.mxcsr;
    #asm { stmxcsr [mxcsr]; }

    return new_task;
}

sleep_until :: (time: Apollo_Time) {
    using kernel_globals;

    core := get_current_core();
    task := scheduler.current_task[core.id];

    {
        Scoped_Acquire(*scheduler.spinlock);

        task.sleeping = true;
        task.sleeping_until = time;

        array_add(*scheduler.sleeping, task);
    }

    yield();
}

wake_sleeping_task :: () -> bool {
    using kernel_globals;

    // Is it better to program an interrupt to do this?
    if !scheduler.sleeping.count return false;

    time := get_monotonic_system_time();

    Scoped_Acquire(*scheduler.spinlock);
    for scheduler.sleeping {

        // If we keep these ordered by time then we wouldn't have to iterate.
        if it.sleeping_until < time {
            it.sleeping = false;

            // Todo: ensure this is not an allocation. For now we reserved 256 slots, preventing it from allocating for current practical purposes.
            queue_push(*scheduler.waiting_to_run, it);

            array_unordered_remove_by_index(*scheduler.sleeping, it_index);
            break;
        }
    }

    return true;
}

yield :: (loc := #caller_location) #no_context {
    using kernel_globals;
    next: *Task_Info;

    core := get_current_core();
    current_task := scheduler.current_task[core.id];

    c: Context;
    push_context c {

        wake_sleeping_task();

        while true {
            while queue_is_empty(scheduler.waiting_to_run) {
                if !wake_sleeping_task() {
                    #asm { hlt; }
                }
            }

            acquire(*scheduler.spinlock);

            if queue_is_empty(scheduler.waiting_to_run) {
                // Another core got there faster.
                release(*scheduler.spinlock);
                continue;
            }

            next = queue_pop(*scheduler.waiting_to_run);

            if next == current_task {
                release(*scheduler.spinlock);
                return;
            }

            if !current_task.sleeping {
                // This should never be an allocation since we just removed.
                queue_push(*scheduler.waiting_to_run, current_task);
            }

            break;
        }
    }

    current := *scheduler.current_task[core.id];
    core.task_state_segment.rsp[0] = next.kernel_stack;

    #asm {
        mov rax: gpr === a, current;
        mov rbx: gpr === b, next;
        int TASK_SWITCH_GATE;
    }

    release(*scheduler.spinlock);
}

yield_from_user_mode :: () #no_context {
    syscall_number := 1;

    #asm SYSCALL_SYSRET {
        syscall_number === a;
        syscall c:, _11:, syscall_number;
    }
}

get_current_core_from_user_mode :: () -> *X64_Core #no_context {
    syscall_number := 2;
    core: *X64_Core;

    #asm SYSCALL_SYSRET {
        rax: gpr === a;
        mov rax, syscall_number;
        syscall c:, _11:, rax;
        mov core, rax;
    }

    return core;
}

#program_export
syscall_handler :: (data: *Syscall_Stack) #c_call {
    if data.rax == 1 {
        yield();
    } else if data.rax == 2 {
        data.rax = cast(u64) get_current_core();
    } else {
        write_string("Invalid syscall parameter.\n");
        bluescreen();
    }
}

#program_export
get_kernel_stack :: () -> *void #c_call {
    core := get_current_core();
    return kernel_globals.scheduler.current_task[core.id].kernel_stack;
}

enter_user_mode :: (entry_point: () #c_call, flags: X64_Flags, user_stack: *void) #foreign Interrupts;



task_do_work :: () #c_call {
    release(*kernel_globals.scheduler.spinlock);

    core := get_current_core();
    user_stack := kernel_globals.scheduler.current_task[core.id].user_stack;
    entry_point := task_do_work_in_ring_3;

    enter_user_mode(entry_point, .IF__interrupt, user_stack);
}

task_do_work_in_ring_3 :: () #c_call {
    c := make_kernel_context();

    push_context c {

        while true {
            core := get_current_core_from_user_mode();
            thread := kernel_globals.scheduler.current_task[core.id];

            print("Thread % doing some work in user mode, on core %.\n", thread.id, core.id);

            for 1..5_000_000 {
                #asm { pause; }
            }
        }
    }
}


#program_export
local_apic_timer_interrupt :: (stack: *Interrupt_Stack()) #c_call {
    write_apic_register(.EOI__END_OF_INTERRUPT, 0x0);

    if stack.cs == .RING0_CODE {
        // Don't preempt the kernel for now.
        return;
    }

    yield();
} @InterruptRoutine



Queue :: struct (Item_Type: Type) {
    items: [..] Item_Type; // Using a resizeable array to hold the underlying data  to get the resizing logic from Basic/Array.jai. It means we need to keep saying items.count = items.allocated.
    head: int;
    tail: int;
}

queue_push :: (using queue: *Queue) -> *queue.Item_Type {

    item := *items[head];
    head += 1;

    if head >= items.count {
        head = 0;
    }

    if head == tail {
        old_count := items.allocated;

        items.count += 1;
        maybe_grow(*queue.items);
        items.count = items.allocated;

        memcpy(items.data + items.count - tail - 1, items.data + tail, (old_count - tail + 1) * size_of(Item_Type));

        head = old_count;
        if head == items.count head = 0;

        item = *items[head-1];
    }

    return item;
}

queue_pop :: (using queue: *Queue) -> queue.Item_Type {
    assert(head != tail);

    item := items[tail];
    tail += 1;

    if tail >= items.count {
        tail = 0;
    }

    return item;
}

queue_push :: (using queue: *Queue, item: queue.Item_Type) {
    queue_push(queue).* = item;
}

queue_reserve :: (using queue: *Queue, capacity: int) {
    array_reserve(*queue.items, capacity);
    queue.items.count = queue.items.allocated;
}

queue_length :: (using queue: Queue) -> int {
    if head > tail return head - tail;

    return head + items.count - tail;
}

queue_is_empty :: (using queue: Queue) -> bool {
    return head == tail;
}
