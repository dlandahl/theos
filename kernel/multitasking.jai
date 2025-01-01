
#import "Bucket_Array";

Task_Info :: struct {

    // These fields must match the task switch assembly routine
    rsp: *void;
    cr3: u64;
    xsave: Xsave_Area #align 16;

    user_stack:   *void;
    kernel_stack: *void;

    id: int;

    sleeping: bool;
    sleeping_until: Apollo_Time;
    next_sleeping: *Task_Info;
}

TASK_SWITCH_GATE :: 64;

Scheduler :: struct {
    current_task: [..] *Task_Info;

    sleeping_queue: *Task_Info;

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

    queue_reserve(*scheduler.waiting_to_run, 256);
}

core_begin_multitasking :: () {
    using kernel_globals;

    Scoped_Acquire(*scheduler.spinlock);

    locator, main_task := bucket_array_add(*scheduler.tasks, .{});

    main_task.cr3 = cast(u64) *page_tables.pml4 - DIRECT_MAPPING_BASE;
    main_task.id  = scheduler.next_id;

    mxcsr := *main_task.xsave.mxcsr;
    #asm { stmxcsr [mxcsr]; }

    scheduler.next_id += 1;

    core := get_current_core();
    scheduler.current_task[core.id] = main_task;

    {
        // Enable Local APIC timer interrupts
        lapic_timer_gate := allocate_interrupt_gate();
        register_interrupt_gate(int__local_apic_timer_interrupt, lapic_timer_gate);

        spurious := read_apic_register(.SPURIOUS_INTERRUPT);
        write_apic_register(.SPURIOUS_INTERRUPT, spurious | 0x1ff);
        register_interrupt_gate(int__spurious_interrupt, 0xff);

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

        queue := scheduler.sleeping_queue;
        previous: *Task_Info;

        if !queue {
            scheduler.sleeping_queue = task;
            task.next_sleeping = null;
        } else while (true) {
            if !queue || queue.sleeping_until > time {

                if queue == scheduler.sleeping_queue {
                    scheduler.sleeping_queue = task;
                }

                if previous previous.next_sleeping = task;
                task.next_sleeping = queue;

                break;
            }

            previous = queue;
            queue = queue.next_sleeping;
        }
    }

    yield();
}

wake_sleeping_task :: () -> bool {
    using kernel_globals;

    time := get_monotonic_system_time();

    Scoped_Acquire(*scheduler.spinlock);

    queue := scheduler.sleeping_queue;

    if queue {
        if queue.sleeping_until < time {
            scheduler.sleeping_queue = queue.next_sleeping;

            queue_push(*scheduler.waiting_to_run, queue);
            queue.sleeping = false;
            queue.next_sleeping = null;

            return true;
        }
    }

    return false;
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
                    #asm { sti; hlt; }
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

sleep_from_user_mode :: (time: Apollo_Time) #no_context {
    syscall_number := 3;

    #asm SYSCALL_SYSRET {
        syscall_number === a;
        mov low:  gpr === b, [*time + 0];
        mov high: gpr === d, [*time + 8];

        syscall c:, _11:, low, high, syscall_number;
    }
}

#program_export
syscall_handler :: (data: *Syscall_Stack) #c_call {
    if data.rax == 1 {
        yield();
    } else if data.rax == 2 {
        data.rax = cast(u64) get_current_core();
    } else if data.rax == 3 {
        t: Apollo_Time;
        t.low  = data.rbx;
        t.high = cast(s64) data.rdx;

        c: Context;
        push_context c {
            time := get_monotonic_system_time();
            sleep_until(time + t);
        }
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

    // c: Context;
    // push_context c {
    //     while true {
    //         time := get_monotonic_system_time();
    //         print("Kernel mode thread going to sleep on core %\n", core.id);
    //         sleep_until(time + milliseconds_to_apollo(1500));
    //     }
    // }

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

#program_export
spurious_interrupt :: (stack: Interrupt_Stack()) #c_call {
    write_string("Spurious...\n");
} @InterruptRoutine


// For the "sleeping" and "waiting for mutex" queues I need to be able to insert and
// remove from the middle. Using a linked list would be better for that.

Queue :: struct (Item_Type: Type) {
    // Using a resizeable array to hold the underlying data  to get the resizing logic from Basic/Array.jai. It means we need to keep saying items.count = items.allocated.
    items: [..] Item_Type;
    head: int;
    tail: int;
}

queue_push :: (using queue: *Queue) -> *queue.Item_Type {

    item := *items[tail];
    tail += 1;

    if tail >= items.count {
        tail = 0;
    }

    if tail == head {
        old_count := items.allocated;

        items.count += 1;
        maybe_grow(*queue.items);
        items.count = items.allocated;

        memcpy(items.data + items.count - head - 1, items.data + head, (old_count - head + 1) * size_of(Item_Type));

        tail = old_count;
        item = *items[tail-1];
    }

    return item;
}

queue_pop :: (using queue: *Queue) -> queue.Item_Type {
    assert(tail != head);

    item := items[head];
    head += 1;

    if head >= items.count {
        head = 0;
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
    if tail > head return tail - head;

    return tail + items.count - head;
}

queue_is_empty :: (using queue: Queue) -> bool {
    return tail == head;
}
