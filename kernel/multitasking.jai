
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
    sleep_until: Apollo_Time;
    next_sleeping: *Task_Info;

    on_core: int;

    cpu_time: Apollo_Time;
}

TASK_SWITCH_GATE :: 64;

Scheduler :: struct {
    current_task: *Task_Info;
    idle_task:    *Task_Info;

    sleep_queue: *Task_Info;

    waiting_to_run: Queue(*Task_Info);

    spinlock: Spinlock;

    last_task_switch_timestamp: Apollo_Time;
}

Xsave_Area :: struct {
    // Warning: this struct requires 16-byte alignment to be accessed by fxsave64 etc.
    fpu: [512] u8;

#place fpu;
    pad: [24] u8;
    mxcsr: Mxcsr;
}

allocate_task_info_struct :: () -> *Task_Info {
    using kernel_globals;

    Scoped_Acquire(*add_task_info_struct_spinlock);

    locator, task := bucket_array_add(*tasks, .{});
    task.id = next_task_id;
    next_task_id += 1;

    log("Created task id %\n", task.id);

    return task;
}

core_begin_multitasking :: () {

    core := get_current_core();
    scheduler := *core.scheduler;

    queue_reserve(*scheduler.waiting_to_run, 256);

    scheduler.current_task = allocate_task_info_struct();
    scheduler.current_task.cr3 = cast(u64) *kernel_globals.page_tables.pml4 - DIRECT_MAPPING_BASE;

    idle :: () #c_call {
        push_context,defer_pop;

        core := get_current_core();
        release(*core.scheduler.spinlock);

        while true {
            #asm { hlt; }
            yield();
        }
    }

    params: Create_Task_Parameters;
    params.user_stack_size = 0;
    params.entry_point = idle;

    scheduler.idle_task = create_task(params);

    {
        // Enable Local APIC timer interrupts

        register_interrupt_gate(int__spurious_interrupt, 0xff);
        spurious := read_apic_register(.SPURIOUS_INTERRUPT);
        write_apic_register(.SPURIOUS_INTERRUPT, spurious | 0x1ff);

        write_apic_register(.TIC__TIMER_INITIAL, 0x0400_0000);

        lvtt: Apic_Local_Vector_Table_Entry;
        lvtt.vector = cast(u8) kernel_globals.local_apic_timer_interrupt_gate;
        lvtt.flags &= ~.M__mask;
        lvtt.flags |= .TMM__timer_mode;
        write_apic_register(.LVT__TIMER, << cast(*u32) *lvtt);
    }
}

put_task_on_core :: (task: *Task_Info, core: *X64_Core) {
    scheduler := *core.scheduler;
    Scoped_Acquire(*scheduler.spinlock);

    task.on_core = core.id;
    queue_push(*scheduler.waiting_to_run, task);
}

Create_Task_Parameters :: struct {
    entry_point: () #c_call = task_do_work;

    kernel_stack_size: int = 0x8000;
    user_stack_size:   int = 0x8000;

    mxcsr: Mxcsr = .MASK_ALL;
}

create_task :: (params: Create_Task_Parameters = .{}) -> *Task_Info {
    new_task := allocate_task_info_struct();
    new_task.cr3 = cast(u64) *kernel_globals.page_tables.pml4 - DIRECT_MAPPING_BASE;

    new_task.kernel_stack = alloc(params.kernel_stack_size) + params.kernel_stack_size;
    new_task.user_stack   = alloc(params.user_stack_size)   + params.user_stack_size;

    stack := cast(*Interrupt_Stack) new_task.kernel_stack - 1;
    stack.flags = .IF__interrupt;
    stack.cs = .RING0_CODE;
    stack.ss = .RING0_DATA;
    stack.ip = cast(*void) params.entry_point;
    stack.sp = new_task.kernel_stack;

    new_task.rsp = cast(*void) stack;

    mxcsr := *params.mxcsr;
    #asm { stmxcsr [mxcsr]; }

    return new_task;
}

sleep_until :: (time: Apollo_Time) {

    scheduler := *get_current_core().scheduler;
    task := scheduler.current_task;

    {
        Scoped_Acquire(*scheduler.spinlock);

        task.sleeping = true;
        task.sleep_until = time;

        queue := scheduler.sleep_queue;
        previous: *Task_Info;

        if !queue {
            scheduler.sleep_queue = task;
            task.next_sleeping = null;
        } else while (true) {
            if !queue || queue.sleep_until > time {

                if queue == scheduler.sleep_queue {
                    scheduler.sleep_queue = task;
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

wake_sleeping_tasks :: (core: *X64_Core, time: Apollo_Time) -> bool {
    scheduler := *core.scheduler;
    queue := scheduler.sleep_queue;

    if queue && queue.sleep_until < time {
        scheduler.sleep_queue = queue.next_sleeping;

        queue_push(*scheduler.waiting_to_run, queue);
        queue.sleeping = false;
        queue.next_sleeping = null;

        return true;
    }

    return false;
}

yield :: () {
    core := get_current_core();
    scheduler := *core.scheduler;

    Scoped_Acquire(*scheduler.spinlock);

    next: *Task_Info;
    current := scheduler.current_task;

    time_now := get_monotonic_system_time();
    wake_sleeping_tasks(core, time_now);

    if queue_is_empty(scheduler.waiting_to_run) {
        next = scheduler.idle_task;
    } else {
        next = queue_pop(*scheduler.waiting_to_run);
    }

    if next == current {
        return;
    }

    if !current.sleeping && current != scheduler.idle_task {
        // This should never be an allocation since we just removed.
        queue_push(*scheduler.waiting_to_run, current);
    }

    current.cpu_time += time_now - scheduler.last_task_switch_timestamp;
    scheduler.last_task_switch_timestamp = time_now;

    // Todo: we don't need to write into scheduler.current_task in the interrupt routine
    _current := *scheduler.current_task;
    core.task_state_segment.rsp[0] = next.kernel_stack;

    #asm {
        mov rax: gpr === a, _current;
        mov rbx: gpr === b, next;
        int TASK_SWITCH_GATE;
    }
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

print_from_user_mode :: (format: string, args: .. Any) {
    syscall_number := 4;

    builder: String_Builder;
    print(*builder, format, ..args);
    result := builder_to_string(*builder, do_reset=true);

    data  := result.data;
    count := result.count;

    #asm SYSCALL_SYSRET {
        syscall_number === a;
        count === b;
        data === d;

        syscall c:, _11:, count, data, syscall_number;
    }
}

#program_export
syscall_handler :: (data: *Syscall_Stack) #c_call {
    push_context,defer_pop;

    if data.rax == {
      case 1;
        yield();

      case 2;
        data.rax = cast(u64) get_current_core();

      case 3;
        t: Apollo_Time;
        t.low  = data.rbx;
        t.high = cast(s64) data.rdx;

        time := get_monotonic_system_time();
        sleep_until(time + t);

      case 4;
        s: string;
        s.count = cast(s64) data.rbx;
        s.data  = cast(*u8) data.rdx;
        write_string(s);

      case;
        write_string("Invalid syscall parameter.\n");
        bluescreen();
    }
}

#program_export
get_kernel_stack :: () -> *void #c_call {
    core := get_current_core();
    return core.scheduler.current_task.kernel_stack;
}

enter_user_mode :: (entry_point: () #c_call, flags: X64_Flags, user_stack: *void) #foreign Interrupts;



task_do_work :: () #c_call {
    core := get_current_core();
    release(*core.scheduler.spinlock);

    user_stack := core.scheduler.current_task.user_stack;
    entry_point := task_do_work_in_ring_3;

    enter_user_mode(entry_point, .IF__interrupt, user_stack);
}

task_do_work_in_ring_3 :: () #c_call {
    c: #Context;
    make_kernel_context(*c);

    push_context c {
        core := get_current_core_from_user_mode();
        thread := core.scheduler.current_task;

        while true {
            print_from_user_mode("Thread % doing some work in user mode, on core %.\n", thread.id, core.id);

            for 1..5_000_000 {
                #asm { pause; }
            }

            ms := rdtsc() % 2000;

            print_from_user_mode("Sleeping for % ms\n", ms);
            sleep_from_user_mode(milliseconds_to_apollo(xx ms));
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

    push_context {
        yield();
    }
} @InterruptRoutine

#program_export
spurious_interrupt :: (stack: Interrupt_Stack()) #c_call {
    write_string("Spurious...\n");
} @InterruptRoutine



Queue :: struct (Item_Type: Type) {
    // Using a resizeable array to hold the underlying data, to get the resizing logic from Basic/Array.jai. It means we need to keep saying items.count = items.allocated.
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
        maybe_grow(cast(*Resizable_Array) *queue.items, size_of(queue.Item_Type));
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
