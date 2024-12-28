
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
}

TASK_SWITCH_GATE :: 64;

Scheduler :: struct {
    main_task: *Task_Info;
    current_task: [..] *Task_Info;

    sleeping:       [..] *Task_Info;
    waiting_to_run: [..] *Task_Info;

    tasks: Bucket_Array(Task_Info, 256, always_iterate_by_pointer=true);
    next_id: int;

    spinlock: Spinlock;
}

Xsave_Area :: struct {
    fpu: [512] u8 #align 16;
}

initialize_scheduler :: () {
    task_switch :: () #foreign Interrupts;
    register_interrupt_gate(task_switch, TASK_SWITCH_GATE);

    using kernel_globals;

    scheduler.tasks.allocator = context.allocator;
    scheduler.next_id = 1;
    array_resize(*scheduler.current_task, processor_cores.count);

    array_reserve(*scheduler.waiting_to_run, 256);
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

        write_apic_register(.TIC__TIMER_INITIAL, 0x0400_0000);

        lvtt := << cast(*Acpi_Lvt) *read_apic_register(.LVT__TIMER);
        lvtt.vector = cast(u8) lapic_timer_gate;
        lvtt.flags &= ~.M__mask;
        lvtt.flags |= .TMM__timer_mode;
        write_apic_register(.LVT__TIMER, << cast(*u32) *lvtt);

        spurious := read_apic_register(.SPURIOUS_INTERRUPT);
        write_apic_register(.SPURIOUS_INTERRUPT, spurious | 0x100);
    }
}

create_task :: () -> *Task_Info {
    using kernel_globals;

    // Scoped_Acquire(*scheduler.spinlock);

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

    return new_task;
}

yield :: (loc := #caller_location) #no_context {
    using kernel_globals;

    c: Context;

    next: *Task_Info;
    core := get_current_core();

    current_task := scheduler.current_task[core.id];

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
            array_add(*scheduler.waiting_to_run, current_task);

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
    core := get_current_core();
    user_stack := kernel_globals.scheduler.current_task[core.id].user_stack;
    entry_point := task_do_work_in_ring_3;

    enter_user_mode(entry_point, .IF__interrupt, user_stack);
}

task_do_work_in_ring_3 :: () #c_call {

    c: Context;
    push_context c {

        while true {
            core := get_current_core_from_user_mode();
            thread := kernel_globals.scheduler.current_task[core.id];

            print("Thread % doing some work in user mode, on core %.\n", thread.id, core.id);

            for 1..1_000_000 {
                #asm { pause; }
            }
        }
    }
}


#program_export
local_apic_timer_interrupt :: (stack: *Interrupt_Stack()) #c_call {
    write_apic_register(.EOI__END_OF_INTERRUPT, 0x0);

    if stack.cs == .RING0_CODE {
        // Don't preempt the kernel for now. Otherwise we might get preempted while holding a spinlock.
        return;
    }

    yield();
} @InterruptRoutine
