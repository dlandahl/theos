
Task_Info :: struct {
    rsp: *void;
    // cr3: u64;
    // xsave_area: *[512] u8 #align 16;

    next: *Task_Info;
    user_stack:   *void;
    kernel_stack: *void;
}

main_thread: Task_Info;
task_a: Task_Info;
current_task: *Task_Info;

TASK_SWITCH_GATE :: 64;

start_multitasking :: () {
    if false {

        //
        // Enable local apic timer interrupts
        //

        lapic_timer_gate := allocate_interrupt_gate();
        register_interrupt_gate(int__local_apic_timer_interrupt, lapic_timer_gate);

        write_apic_register(.TIC__TIMER_INITIAL, 0x0800_0000);

        lvtt := cast(*Acpi_Lvt) *read_apic_register(.LVT__TIMER);
        lvtt.vector = cast(u8) lapic_timer_gate;
        lvtt.flags &= ~.M__mask;
        write_apic_register(.LVT__TIMER, << cast(*u32) lvtt);
    }

    task_switch :: () #foreign Interrupts;
    register_interrupt_gate(task_switch, TASK_SWITCH_GATE);

    main_thread.next = *task_a;
    current_task = *main_thread;

    task_a.next = *main_thread;
    task_a.user_stack   = alloc(0x10_0000) + 0x10_0000;
    task_a.kernel_stack = alloc(0x2000) + 0x2000;

    stack := cast(*Interrupt_Stack) task_a.kernel_stack - 1;
    stack.flags = .IF__interrupt;
    stack.cs = .RING0_CODE;
    stack.ss = .RING0_DATA;
    stack.ip = cast(*void) task_do_work;
    stack.sp = task_a.kernel_stack;

    task_a.rsp = cast(*void) stack;

    for 1..10 yield();

    write_string("Made it past all the yields.\n");
}

yield :: () #no_context {
    current := *current_task;
    next := current_task.next;

    #asm {
        mov rax: gpr === a, current;
        mov rbx: gpr === b, next;
        int TASK_SWITCH_GATE;
    }
}

task_do_work :: () #c_call {
    write_string(".. 1 ..\n");
    yield();

    write_string(".. 2 ..\n");
    yield();

    write_string(".. 3 ..\n");
    yield();

    address := task_do_work_in_ring_3;

    #asm SYSCALL_SYSRET {
        mov rcx: gpr === c,  address;
        mov r11: gpr === 11, 0x202;
        sysret.q;
    }
}

yield_from_user_mode :: () #no_context {
    syscall_number := 12345;

    #asm SYSCALL_SYSRET {
        syscall_number === a;
        syscall c:, _11:, syscall_number;
    }
}

#program_export
syscall_handler :: (data: *Syscall_Stack) #c_call {
    syscall_number := data.rax;
    if syscall_number == 12345 {
        yield();
    }
}

task_do_work_in_ring_3 :: () #c_call {
    // #asm {int 0xd;}
    write_string("Doing stuff in ring 3\n");
    yield_from_user_mode();
    write_string("Doing more stuff.\n");
    for 1..50 yield_from_user_mode();
    while true { }
}

#program_export
local_apic_timer_interrupt :: (stack: *void) #c_call {
    write_apic_register(.EOI__END_OF_INTERRUPT, 0x0);
} @InterruptRoutine
