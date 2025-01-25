
Acpi_Madt :: struct {
    using #as header: Acpi_Table_Header;

    local_apic_address: u32;
    flags: u32;

    Interrupt_Controller_Structure :: struct {
        subtype: Subtype;
        length: u8;

        Subtype :: enum u8 {
            LOCAL_APIC                :: 0;
            IO_APIC                   :: 1;
            INTERRUPT_SOURCE_OVERRIDE :: 2;
            NON_MASKABLE_INTERRUPT    :: 4;
            LAPIC_ADDRESS_OVERRIDE    :: 5;
            LOCAL_X2APIC              :: 9;
        }
    }

    Ics_Local_Apic :: struct {
        using ics: Interrupt_Controller_Structure;

        acpi_processor_uid: u8;
        apic_id: u8;

        flags: enum_flags u32 {
            ENABLED           :: 0x1;
            ONLINE_CAPABLE    :: 0x2;
        };
    }

    Ics_Io_Apic :: struct {
        using ics: Interrupt_Controller_Structure;

        io_apic_id: u8;
        reserved: u8;
        address: u32;
        global_system_interrupt_base: u32;
    }

    Ics_Source_Override :: struct {
        using ics: Interrupt_Controller_Structure;

        bus: u8;
        source: u8;
        global_system_interrupt: u32;
        flags: u16;
    }

    Ics_Non_Maskable_Interrupt :: struct {
        using ics: Interrupt_Controller_Structure;

        processor_uid: u8;
        flags: u16 #align 1;
        lapic_lint: u8;
    }
}

Apic_Register :: enum {
    APIC_ID                   :: 0x20;
    APIC_VERSION              :: 0x30;
    TPR__TASK_PRIORITY        :: 0x80;
    APR__ARBITRATION_PRIORITY :: 0x90;
    PPR__PROCESSOR_PRIORITY   :: 0xa0;
    EOI__END_OF_INTERRUPT     :: 0xb0;
    SPURIOUS_INTERRUPT        :: 0xf0;
    ICR__INTERRUPT_COMMAND    :: 0x300;
    DES__INTERRUPT_DEST       :: 0x310;
    LVT__TIMER                :: 0x320;
    TIC__TIMER_INITIAL        :: 0x380;
    TCC__TIMER_CURRENT        :: 0x390;
    DV__TIMER_DIVIDE          :: 0x3e0;
    EXTENDED_FEATURE          :: 0x400;
}

read_apic_register :: (register: Apic_Register, loc := #caller_location) -> u32 #no_context {
    if kernel_globals.apic == null {
        bluescreen(loc);
    }

    return << cast(*u32) (kernel_globals.apic + cast(u64) register);
}

write_apic_register :: (register: Apic_Register, value: u32) #no_context {
    if kernel_globals.apic == null {
        bluescreen();
    }

    << cast(*u32) (kernel_globals.apic + cast(u64) register) = value;
}

Apic_Lvt_Timer :: enum u32 {
    gate_index      :: 8;
    reserved_0      :: 4;
    delivery_status :: 1;
    reserved_1      :: 3;
    mask            :: 1;
    timer_mode      :: 2;
    reserved_2      :: 13;
} @Bitfield

initialize_apic :: () {

    // Disable the older interrupt controller. I sort of assume UEFI does this anyway.
    #asm {
        mov.8 ax: gpr === a, 0xff;
        out.8 0x21, ax;
        out.8 0xa1, ax;
    }

    acpi_header := cast(*Acpi_Madt) find_acpi_table("APIC");

    Apic_Base_Flags :: enum_flags {
        BSC__Boot_Strap_Core :: 1 << 8;
        EXTD__2xApic_Mode    :: 1 << 10;
        AE__Apic_Enable      :: 1 << 11;
    }

    apic_base := << cast(*Apic_Base_Flags) *read_msr(.APIC_BASE);
    assert(apic_base & .BSC__Boot_Strap_Core > 0);

    apic_base |= .AE__Apic_Enable;
    write_msr(.APIC_BASE, cast(u64) apic_base);

    {
        physical := cast(u64) apic_base & ~0xfff;
        assert(0xfee0_0000 == physical);

        virtual := alloc_block(*kernel_globals.virtual_block_allocator, 4096);
        map_page(virtual, physical, Page_Flags.READ_WRITE | .PRESENT | .CACHE_DISABLE);

        kernel_globals.apic = cast(*void) virtual;
    }

    bootstrap_core := array_add(*kernel_globals.processor_cores);
    bootstrap_core.local_apic_id = read_apic_register(.APIC_ID) >> 24;
    init_processor_core();


    #insert #run,host -> string {
        builder: String_Builder;
        for 0..12 {
            print(*builder, "register_interrupt_gate(int__fault_%1, %1, true);\n", it);
        }
        return builder_to_string(*builder);
    };

    register_interrupt_gate(int__general_protection_fault, 13, true);
    register_interrupt_gate(int__fault_14, 14, true);
    register_interrupt_gate(int__simd_floating_point_exception, 19, true);

    //
    // Iterate interrupt controller structures
    //

    cursor := cast(u64) acpi_header + size_of(Acpi_Madt);

    while cursor < cast(u64) acpi_header + acpi_header.length {
        ics := cast(*Acpi_Madt.Interrupt_Controller_Structure) cursor;
        defer cursor += ics.length;

        if ics.subtype == {
          case .LOCAL_APIC;
            lapic_ics := cast(*Acpi_Madt.Ics_Local_Apic) ics;

            if lapic_ics.apic_id == bootstrap_core.local_apic_id {
                continue;
            }

            // Apparently we should be able to use the ONLINE_CAPABLE bit in the ics flags to determine if
            // this processor core is usable, but for some reason it's always 0 in Qemu and Vbox.

            new_core := array_add(*kernel_globals.processor_cores);

            new_core.local_apic_id = lapic_ics.apic_id;
            new_core.id = kernel_globals.processor_cores.count-1;

          case .IO_APIC;
            assert(kernel_globals.io_apic == null);

            ioapic_ics := cast(*Acpi_Madt.Ics_Io_Apic) ics;

            virtual := alloc_block(*kernel_globals.virtual_block_allocator, 4096);
            map_page(virtual, ioapic_ics.address, Page_Flags.READ_WRITE | .PRESENT | .CACHE_DISABLE);

            kernel_globals.io_apic = cast(*u32) virtual;

            assert(ioapic_ics.address == 0xfec0_0000);

          case .INTERRUPT_SOURCE_OVERRIDE;
            iso := cast(*Acpi_Madt.Ics_Source_Override) ics;
            // Todo
        }
    }

    timer_gate := allocate_interrupt_gate();
    register_interrupt_gate(int__local_apic_timer_interrupt, timer_gate);

    // Store this, to be able to configure the LAPIC of all CPUs to use the same interrupt handler.
    // In the future we might not need LAPIC timer if we only support CPUs with the TSC deadline feature.
    kernel_globals.local_apic_timer_interrupt_gate = timer_gate;
}

startup_application_processors :: () {

    // Load the 16 bit AP initialization routine from static memory
    memcpy(cast(*void) 0x8000 + DIRECT_MAPPING_BASE, ap_startup_bin.data, 4096);

    Ap_Startup_Data :: struct {
        // Layout matches the ap_startup assembly code in first.jai
        stack: u64;
        entry_point: *void;
        pml4: *u64;
    }

    ap_startup_data := cast(*Ap_Startup_Data) (0x8200 + DIRECT_MAPPING_BASE);
    ap_startup_data.entry_point = cast(*void) ap_entry_point;
    ap_startup_data.pml4 = kernel_globals.boot_data.page_tables.pml4.data;

    bsp := get_current_core();

    for* kernel_globals.processor_cores {
        if it == bsp {
            continue;
        }

        // This lock is to ensure that APs have time to copy their stack's base address into their stack register before the next AP is started up.
        // Maybe if processors could use their APIC ID to find their stack memory it would be faster
        acquire(*ap_startup_spinlock);

        acquire(*kernel_globals.memory_spinlock);
        stack := alloc_block(*kernel_globals.physical_block_allocator, 0x1_0000) + 0x1_0000;
        release(*kernel_globals.memory_spinlock);

        ap_startup_data.stack = stack + DIRECT_MAPPING_BASE;

        write_apic_register(.DES__INTERRUPT_DEST, it.local_apic_id << 24);

        // Todo: People online are saying these need to be executed multiple times per core
        command: u32;
        command = (0b101 << 8) | (1 << 14); // INIT IPI
        write_apic_register(.ICR__INTERRUPT_COMMAND, command);

        command = (0b110 << 8) | 8; // STARTUP IPI
        write_apic_register(.ICR__INTERRUPT_COMMAND, command);
    }
}

ap_startup_bin :: #run,host -> [] u8 {
    #import "Compiler";
    #import "File";

    context.allocator = Context_Base.default_allocator;

    code := read_entire_file(".build/ap_startup.bin");
    return add_global_data(cast([] u8) code, .WRITABLE);
}

ap_startup_spinlock: Spinlock;

ap_entry_point :: () #c_call {
    release(*ap_startup_spinlock);

    push_context {
        make_kernel_context(*context);

        init_processor_core();

        core := get_current_core();

        core_begin_multitasking();

        for 1..4 {
            new_task := create_task();
            put_task_on_core(new_task, core);
        }

        #asm { sti; }

        while true {
            time := get_monotonic_system_time();
            sleep_until(time + milliseconds_to_apollo(2000));
            print("Whatever.\n");

            reset_temporary_storage();
        }
    }
}

get_current_core :: (loc := #caller_location) -> *X64_Core #no_context {
    // Depending on FSGSBASE because for some reason I could not get GS_BASE MSR to work.

    core: *X64_Core;
    #asm FSGSBASE {
        rdgsbase core;
    }

    if !core bluescreen(loc);
    return core;
}


ioapic_add_interrupt_redirection_table_entry :: (redirection_index: u32, gate_number: int) {
    REDIRECTION_TABLE_BASE       : u32 : 0x10;
    REDIRECTION_TABLE_ENTRY_SIZE : u32 : 0x2;

    register_index := REDIRECTION_TABLE_BASE + redirection_index * REDIRECTION_TABLE_ENTRY_SIZE;

    kernel_globals.io_apic[0] = register_index;
    kernel_globals.io_apic[4] = cast(u32) gate_number;

    kernel_globals.io_apic[0] = register_index+1;
    kernel_globals.io_apic[4] = 0;
}





#program_export fault_0 :: (stack: *void) #c_call {
    core := get_current_core();

    write_string("Something bad happened (0) on core ");
    write_number(core.id);
    write_string("\n");

    bluescreen();
} @InterruptRoutine

#program_export fault_1 :: (stack: *void) #c_call {
    core := get_current_core();

    write_string("Something bad happened (1) on core ");
    write_number(core.id);
    write_string("\n");

    bluescreen();
} @InterruptRoutine

#program_export fault_2 :: (stack: *void) #c_call {
    core := get_current_core();

    write_string("Something bad happened (2) on core ");
    write_number(core.id);
    write_string("\n");

    bluescreen();
} @InterruptRoutine

#program_export fault_3 :: (stack: *void) #c_call {
    core := get_current_core();

    write_string("Something bad happened (3) on core ");
    write_number(core.id);
    write_string("\n");

    bluescreen();
} @InterruptRoutine

#program_export fault_4 :: (stack: *void) #c_call {
    core := get_current_core();

    write_string("Something bad happened (4) on core ");
    write_number(core.id);
    write_string("\n");

    bluescreen();
} @InterruptRoutine

#program_export fault_5 :: (stack: *void) #c_call {
    core := get_current_core();

    write_string("Something bad happened (5) on core ");
    write_number(core.id);
    write_string("\n");

    bluescreen();
} @InterruptRoutine

#program_export fault_6 :: (stack: *Interrupt_Stack(false)) #c_call {
    push_context {
        context.print_style.default_format_int.base = 16;

        print("Invalid Opcode.\n");
        print("RIP: 0x%\n", stack.ip);
        print("RSP: 0x%\n", stack.sp);
        print("SS: 0x%\n", stack.ss);
        print("CS: 0x%\n", stack.cs);
        bluescreen();
    }
} @InterruptRoutine

#program_export fault_7 :: (stack: *void) #c_call {
    core := get_current_core();

    write_string("Something bad happened (7) on core ");
    write_number(core.id);
    write_string("\n");

    bluescreen();
} @InterruptRoutine

#program_export fault_8 :: (stack: *void) #c_call {
    core := get_current_core();

    write_string("Something bad happened (8) on core ");
    write_number(core.id);
    write_string("\n");

    bluescreen();
} @InterruptRoutineWithErrorCode

#program_export fault_9 :: (stack: *void) #c_call {
    core := get_current_core();

    write_string("Something bad happened (9) on core ");
    write_number(core.id);
    write_string("\n");

    bluescreen();
} @InterruptRoutine

#program_export fault_10 :: (stack: *void) #c_call {
    core := get_current_core();

    write_string("Something bad happened (10) on core ");
    write_number(core.id);
    write_string("\n");

    bluescreen();
} @InterruptRoutineWithErrorCode

#program_export fault_11 :: (stack: *void) #c_call {
    core := get_current_core();

    write_string("Something bad happened (11) on core ");
    write_number(core.id);
    write_string("\n");

    bluescreen();
} @InterruptRoutineWithErrorCode

#program_export fault_12 :: (stack: *void) #c_call {
    core := get_current_core();

    write_string("Something bad happened (12) on core ");
    write_number(core.id);
    write_string("\n");

    bluescreen();
} @InterruptRoutineWithErrorCode

#program_export
general_protection_fault :: (stack: *Interrupt_Stack(with_error_code = true)) #c_call {
    push_context {
        core := get_current_core();
        task := core.scheduler.current_task;

        print("General Protection Fault    (On core %, running thread %)\n", core.id, task.id);

        context.print_style.default_format_int.base = 16;
        print("RIP: 0x%\n", stack.ip);
        print("RSP: 0x%\n", stack.sp);
        print("SS: %\n", stack.ss);
        print("CS: %\n", stack.cs);

        Selector_Error_Code :: enum u32 {
            external              :: 1;
            descriptor_table_kind :: 2;
            selector_index        :: 13;
            reserved              :: 16;
        } @Bitfield

        Table_Kind :: enum {
            GDT  :: 0b00;
            IDT  :: 0b01;
            LDT  :: 0b10;
            IDT_ :: 0b11;
        }

        selector_error := cast(Selector_Error_Code) stack.error_code;

        is_external := cast(bool)       bitfield_get(selector_error, .external);
        table       := cast(Table_Kind) bitfield_get(selector_error, .descriptor_table_kind);
        index       :=                  bitfield_get(selector_error, .selector_index);

        print("Error code: external=%, table=%, index=% (0x%)\n", is_external, table, formatInt(index, base=10), index);
        bluescreen();
    }
} @InterruptRoutineWithErrorCode

#program_export fault_14 :: (stack: *void) #c_call {
    core := get_current_core();

    write_string("Something bad happened (14) on core ");
    write_number(core.id);
    write_string("\n");

    bluescreen();
} @InterruptRoutineWithErrorCode

#program_export fault_15 :: (stack: *void) #c_call {
    core := get_current_core();

    write_string("Something bad happened (15) on core ");
    write_number(core.id);
    write_string("\n");

    bluescreen();
} @InterruptRoutine



//
// Implement the uACPI kernel API callbacks
//

#import "Uacpi";

#program_export uacpi_do_atomic_cmpxchg64 :: () #c_call {
    write_string("uACPI kernel call: \"uacpi_do_atomic_cmpxchg64\"\n");
    bluescreen();
}

#program_export uacpi_do_atomic_cmpxchg32 :: () #c_call {
    write_string("uACPI kernel call: \"uacpi_do_atomic_cmpxchg32\"\n");
    bluescreen();
}

#program_export uacpi_do_atomic_cmpxchg16 :: () #c_call {
    write_string("uACPI kernel call: \"uacpi_do_atomic_cmpxchg16\"\n");
    bluescreen();
}

#program_export uacpi_kernel_get_rsdp :: (rsdp_address: *uacpi_phys_addr) -> uacpi_status #c_call {
    rsdp_address.* = cast(uacpi_phys_addr) kernel_globals.acpi_rsdp;
    return .OK;
}

#program_export uacpi_kernel_raw_memory_read :: () #c_call {
    write_string("uACPI kernel call: \"uacpi_kernel_raw_memory_read\"\n");
    bluescreen();
}

#program_export uacpi_kernel_raw_memory_write :: () #c_call {
    write_string("uACPI kernel call: \"uacpi_kernel_raw_memory_write\"\n");
    bluescreen();
}

#program_export uacpi_kernel_raw_io_read :: (address: uacpi_io_addr, byte_width: uacpi_u8, out_value: *uacpi_u64) -> uacpi_status #c_call {
    value: u64;

    #asm {
        address === d;
        value   === a;
    }

    if byte_width == {
        case 1; #asm { in.8  value, address; }
        case 2; #asm { in.16 value, address; }
        case 4; #asm { in.32 value, address; }
        case; bluescreen();
    }

    out_value.* = value;
    return .OK;
}

#program_export uacpi_kernel_raw_io_write :: (address: uacpi_io_addr, byte_width: uacpi_u8, value: uacpi_u64) -> uacpi_status #c_call {
    #asm {
        address === d;
        value   === a;
    }

    if byte_width == {
        case 1; #asm { out.8  address, value; }
        case 2; #asm { out.16 address, value; }
        case 4; #asm { out.32 address, value; }
        case; bluescreen();
    }

    return .OK;
}

#program_export uacpi_kernel_pci_read :: () #c_call {
    write_string("uACPI kernel call: \"uacpi_kernel_pci_read\"\n");
    bluescreen();
}

#program_export uacpi_kernel_pci_write :: () #c_call {
    write_string("uACPI kernel call: \"uacpi_kernel_pci_write\"\n");
    bluescreen();
}

#program_export uacpi_kernel_io_map :: () #c_call {
    write_string("uACPI kernel call: \"uacpi_kernel_io_map\"\n");
    bluescreen();
}

#program_export uacpi_kernel_io_unmap :: () #c_call {
    write_string("uACPI kernel call: \"uacpi_kernel_io_unmap\"\n");
    bluescreen();
}

#program_export uacpi_kernel_io_read :: () #c_call {
    write_string("uACPI kernel call: \"uacpi_kernel_io_read\"\n");
    bluescreen();
}

#program_export uacpi_kernel_io_write :: () #c_call {
    write_string("uACPI kernel call: \"uacpi_kernel_io_write\"\n");
    bluescreen();
}

#program_export uacpi_kernel_map :: (addr: uacpi_phys_addr, len: uacpi_size) -> *void #c_call {
    return cast(*void) addr + DIRECT_MAPPING_BASE;
}

#program_export uacpi_kernel_unmap :: (addr: *void, len: uacpi_size) #c_call {
    return;
}

#program_export uacpi_kernel_alloc :: (size: uacpi_size) -> *void #c_call {
    // Not currently thread synced, and alloc_block is not efficient for small allocations.
    push_context {
        phys := alloc_block(*kernel_globals.physical_block_allocator, size);
        virt := cast(*void) phys + DIRECT_MAPPING_BASE;

        return virt;
    }
}

#program_export uacpi_kernel_calloc :: (count: uacpi_size, size: uacpi_size) -> *void #c_call {
    // Comment in uacpi_kernel_alloc applies
    size_bytes := size*count;

    push_context {
        phys := alloc_block(*kernel_globals.physical_block_allocator, size_bytes);
        virt := cast(*void) phys + DIRECT_MAPPING_BASE;

        memset(virt, 0, cast(s64) size_bytes);
        return virt;
    }
}

#program_export uacpi_kernel_free :: (mem: *void) #c_call {
    // Comment in uacpi_kernel_alloc applies
    if mem == null return;

    push_context {
        phys := cast(u64) mem - DIRECT_MAPPING_BASE;
        free_block(*kernel_globals.physical_block_allocator, phys);
    }
}

#program_export uacpi_kernel_log :: (log_level: uacpi_log_level, c_string: *uacpi_char) #c_call {
    message: string;
    message.data = c_string;
    message.count = c_style_strlen(c_string);

    write_string(message);
}

#program_export uacpi_kernel_get_nanoseconds_since_boot :: () #c_call {
    write_string("uACPI kernel call: \"uacpi_kernel_get_nanoseconds_since_boot\"\n");
    bluescreen();
}

#program_export uacpi_kernel_stall :: () #c_call {
    write_string("uACPI kernel call: \"uacpi_kernel_stall\"\n");
    bluescreen();
}

#program_export uacpi_kernel_sleep :: () #c_call {
    write_string("uACPI kernel call: \"uacpi_kernel_sleep\"\n");
    bluescreen();
}



// These uACPI multithreading callbacks should be implemented once we have multithreading primitives in the kernel.

next_mutex_handle: uacpi_handle = xx 1;
next_event_handle: uacpi_handle = xx 1;

#program_export uacpi_kernel_create_mutex :: () -> uacpi_handle #c_call {
    result := next_mutex_handle;
    next_mutex_handle += 1;
    return result;
}

#program_export uacpi_kernel_free_mutex :: (handle: uacpi_handle) #c_call {
    // Do nothing
}

#program_export uacpi_kernel_create_event :: () -> uacpi_handle #c_call {
    result := next_event_handle;
    next_event_handle += 1;
    return result;
}

#program_export uacpi_kernel_free_event :: () #c_call {
    // Do nothing
}

#program_export uacpi_kernel_get_thread_id :: () -> uacpi_thread_id #c_call {
    return cast(*void) 1;
}

#program_export uacpi_kernel_acquire_mutex :: (handle: uacpi_handle, timeout: uacpi_u16) -> uacpi_status #c_call {
    return .OK;
}

#program_export uacpi_kernel_release_mutex :: (handle: uacpi_handle) #c_call {
    // Do nothing
}

#program_export uacpi_kernel_wait_for_event :: (handle: uacpi_handle, timeout: uacpi_u16) -> uacpi_bool #c_call {
    return true;
}

#program_export uacpi_kernel_signal_event :: () #c_call {
    write_string("uACPI kernel call: \"uacpi_kernel_signal_event\"\n");
    bluescreen();
}

#program_export uacpi_kernel_reset_event :: () #c_call {
    write_string("uACPI kernel call: \"uacpi_kernel_reset_event\"\n");
    bluescreen();
}

#program_export uacpi_kernel_handle_firmware_request :: () #c_call {
    write_string("uACPI kernel call: \"uacpi_kernel_handle_firmware_request\"\n");
    bluescreen();
}

#program_export uacpi_kernel_install_interrupt_handler :: () #c_call {
    write_string("uACPI kernel call: \"uacpi_kernel_install_interrupt_handler\"\n");
    bluescreen();
}

#program_export uacpi_kernel_uninstall_interrupt_handler :: () #c_call {
    write_string("uACPI kernel call: \"uacpi_kernel_uninstall_interrupt_handler\"\n");
    bluescreen();
}

#program_export uacpi_kernel_create_spinlock :: () #c_call {
    write_string("uACPI kernel call: \"uacpi_kernel_create_spinlock\"\n");
    bluescreen();
}

#program_export uacpi_kernel_free_spinlock :: () #c_call {
    write_string("uACPI kernel call: \"uacpi_kernel_free_spinlock\"\n");
    bluescreen();
}

#program_export uacpi_kernel_lock_spinlock :: () #c_call {
    write_string("uACPI kernel call: \"uacpi_kernel_lock_spinlock\"\n");
    bluescreen();
}

#program_export uacpi_kernel_unlock_spinlock :: () #c_call {
    write_string("uACPI kernel call: \"uacpi_kernel_unlock_spinlock\"\n");
    bluescreen();
}

#program_export uacpi_kernel_schedule_work :: () #c_call {
    write_string("uACPI kernel call: \"uacpi_kernel_schedule_work\"\n");
    bluescreen();
}

#program_export uacpi_kernel_wait_for_work_completion :: () #c_call {
    write_string("uACPI kernel call: \"uacpi_kernel_wait_for_work_completion\"\n");
    bluescreen();
}
 
#program_export __popcountdi2 :: () {
    write_string("uACPI kernel call: \"__popcountdi2\"\n");
    bluescreen();
}
