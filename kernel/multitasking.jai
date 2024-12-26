
#import "Bucket_Array";

Task_Info :: struct {

    // These fields are volatile, because they get dereferenced in the
    // context switch routine implemented in assembly in first.jai
    // ============
    rsp: *void;
    cr3: u64;
    xsave_area: Xsave_Area;
    // ============

    user_stack:   *void;
    kernel_stack: *void;

    id: int;

    state: enum {
        RUNNING;
        WAITING_TO_RUN;
        SLEEPING;
    }
}

TASK_SWITCH_GATE :: 64;

Scheduler :: struct {
    main_task: *Task_Info;
    current_task: *Task_Info;

    sleeping:       [..] *Task_Info;
    waiting_to_run: [..] *Task_Info;

    tasks: Bucket_Array(Task_Info, 256, always_iterate_by_pointer=true);
    next_id: int;

    spinlock: Spinlock;
}

Xsave_Area :: struct {
    fpu: [512] u8 #align 16;
}

start_multitasking :: () {
    {
        // Enable Local APIC timer interrupts
        lapic_timer_gate := allocate_interrupt_gate();
        register_interrupt_gate(int__local_apic_timer_interrupt, lapic_timer_gate);

        write_apic_register(.TIC__TIMER_INITIAL, 0x0280_0000);

        lvtt := cast(*Acpi_Lvt) *read_apic_register(.LVT__TIMER);
        lvtt.vector = cast(u8) lapic_timer_gate;
        lvtt.flags &= ~.M__mask;
        write_apic_register(.LVT__TIMER, << cast(*u32) lvtt);
    }

    task_switch :: () #foreign Interrupts;
    register_interrupt_gate(task_switch, TASK_SWITCH_GATE);

    using kernel_globals.scheduler;

    tasks.allocator = context.allocator;
    next_id = 1;

    locator:, main_task = bucket_array_add(*tasks, .{});

    main_task.cr3  = cast(u64) *kernel_globals.page_tables.pml4 - DIRECT_MAPPING_BASE;
    main_task.id   = next_id;

    next_id += 1;
    current_task = main_task;

    create_task();
    create_task();
    create_task();

    for 1..10 yield();

    write_string("Made it past all the yields.\n");
}

create_task :: () -> *Task_Info {
    using kernel_globals;

    Scoped_Acquire(*scheduler.spinlock);

    locator, new_task := bucket_array_add(*scheduler.tasks, .{});
    new_task.cr3 = cast(u64) *page_tables.pml4 - DIRECT_MAPPING_BASE;

    new_task.user_stack   = alloc(0x10_0000) + 0x10_0000;
    new_task.kernel_stack = alloc(0x2000) + 0x2000;

    stack := cast(*Interrupt_Stack) new_task.kernel_stack - 1;
    stack.flags = .IF__interrupt;
    stack.cs = .RING0_CODE;
    stack.ss = .RING0_DATA;
    stack.ip = cast(*void) task_do_work;
    stack.sp = new_task.kernel_stack;

    new_task.rsp = cast(*void) stack;
    new_task.id = scheduler.next_id;
    scheduler.next_id += 1;

    array_add(*scheduler.waiting_to_run, new_task);

    return new_task;
}

yield :: () #no_context {
    using kernel_globals;

    next: *Task_Info;

    c: Context;
    push_context c {
        while true {
            while scheduler.waiting_to_run.count == 0 {
                #asm { hlt; }
            }

            Scoped_Acquire(*scheduler.spinlock);

            if scheduler.waiting_to_run.count == 0 {
                continue;
            }

            next = scheduler.waiting_to_run[0];

            // Ordered remove to prevent starvation.
            array_ordered_remove_by_index(*scheduler.waiting_to_run, 0);

            // This should never be an allocation since we just removed.
            array_add(*scheduler.waiting_to_run, scheduler.current_task);

            break;
        }
    }

    current := *scheduler.current_task;
    task_state_segment.rsp[0] = next.kernel_stack;

    #asm {
        mov rax: gpr === a, current;
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

#program_export
syscall_handler :: (data: *Syscall_Stack) #c_call {
    if data.rax == 1 {
        yield();
    } else {
        write_string("Invalid syscall parameter.\n");
        bluescreen();
    }
}

#program_export
get_kernel_stack :: () -> *void #c_call {
    return kernel_globals.scheduler.current_task.kernel_stack;
}

enter_user_mode :: (entry_point: () #c_call, flags: X64_Flags, user_stack: *void) #foreign Interrupts;



task_do_work :: () #c_call {
    entry_point := task_do_work_in_ring_3;
    user_stack  := kernel_globals.scheduler.current_task.user_stack;

    enter_user_mode(entry_point, .IF__interrupt, user_stack);
}

task_do_work_in_ring_3 :: () #c_call {
    while true {
        write_string("Thread ");
        write_number(kernel_globals.scheduler.current_task.id);
        write_string(" doing some work.\n");

        for 1..5_000_000 {
            #asm { pause; }
        }
    }
}



#program_export
local_apic_timer_interrupt :: (stack: *void) #c_call {
    write_apic_register(.EOI__END_OF_INTERRUPT, 0x0);
    yield();
} @InterruptRoutine
