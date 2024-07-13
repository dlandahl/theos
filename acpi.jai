
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
} #no_padding

Acpi_FADT__Fixed_Description_Table :: struct {
    #as header: Acpi_Table_Header;
    firmware_ctrl: u32;
    dsdt_address: u32;

    // Todo: doesn't handle 64bit dsdt address
    // https://uefi.org/htmlspecs/ACPI_Spec_6_4_html/05_ACPI_Software_Programming_Model/ACPI_Software_Programming_Model.html?highlight=dsdt#fadt-format
}

find_acpi_table :: (signature: string) -> *Acpi_Table_Header {
    table_size := root_acpi_table.length - size_of(Acpi_Table_Header);

    pointer_size := cast(u64) (ifx acpi_version then 8 else 4);
    pointer_count := table_size / pointer_size;

    table_base := cast(u64) (root_acpi_table + 1);

    for table_index: 0..pointer_count - 1 {
        offset := table_index * pointer_size + table_base;

        phys := ifx acpi_version {
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



Acpi_MADT :: struct {
    using #as header: Acpi_Table_Header;

    local_apic_address: u32;
    flags: u32;

    Interrupt_Controller_Structure :: struct {
        type: Type;
        length: u8;

        Type :: enum u8 {
            LOCAL_APIC                :: 0x0;
            IO_APIC                   :: 0x1;
            INTERRUPT_SOURCE_OVERRIDE :: 0x2;
            NON_MASKABLE_INTERRUPT    :: 0x4;
            MULTIPROCESSOR_WAKEUP     :: 0x10;
        }
    }

    Ics_Local_Apic :: struct {
        using ics: Interrupt_Controller_Structure;

        acpi_processor_uid: u8;
        apic_id: u8;

        flags: enum_flags u32 {
            enabled;
            online_capable;
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

APIC_Register :: enum {
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
}

read_apic_register :: (register: APIC_Register) -> u32 {
    assert(kernel_globals.apic != null);
    return << cast(*u32) (apic + cast(u64) register);
}

write_apic_register :: (register: APIC_Register, value: u32) {
    assert(kernel_globals.apic != null);
    << cast(*u32) (apic + cast(u64) register) = value;
}

Acpi_Lvt :: struct {
    vector: u8;

#place vector;
    flags: enum_flags u32 {
        MT__message_type0    :: 1 << 8;
        MT__message_type1    :: 1 << 9;
        MT__message_type2    :: 1 << 10;
        DM__destination_mode :: 1 << 11;
        DS__delivery_status  :: 1 << 12;
        RIR__remote_irr      :: 1 << 14;
        L__level             :: RIR__remote_irr;
        TGM__trigger_mode    :: 1 << 15;
        M__mask              :: 1 << 16;
        TMM__timer_mode      :: 1 << 17;
    };
}

tock: bool;

#program_export
timer_interrupt :: (stack: *void) #c_call {
    push_context .{} {
        serial_out(ifx tock then "tock\n" else "tick\n");
        tock = !tock;

        write_apic_register(.EOI__END_OF_INTERRUPT, 0x0);
    }
} @InterruptHandler

apic_stuff :: () {
    register_interrupt_gate(xx int__fault_0, 0);
    register_interrupt_gate(xx int__fault_1, 1);
    register_interrupt_gate(xx int__fault_2, 2);
    register_interrupt_gate(xx int__fault_3, 3);
    register_interrupt_gate(xx int__fault_4, 4);
    register_interrupt_gate(xx int__fault_5, 5);
    register_interrupt_gate(xx int__fault_6, 6);
    register_interrupt_gate(xx int__fault_7, 7);
    register_interrupt_gate(xx int__fault_8, 8);
    register_interrupt_gate(xx int__fault_9, 9);
    register_interrupt_gate(xx int__fault_10, 10);
    register_interrupt_gate(xx int__fault_11, 11);
    register_interrupt_gate(xx int__fault_12, 12);
    register_interrupt_gate(xx int__general_protection_fault, 13);
    register_interrupt_gate(xx int__fault_14, 14);
    register_interrupt_gate(xx int__fault_15, 15);

    acpi_header := cast(*Acpi_MADT) find_acpi_table("APIC");

    Apic_Base_Flags :: enum_flags {
        BSC__Boot_Strap_Core :: 1 << 8;
        EXTD__2xApic_Mode    :: 1 << 10;
        AE__Apic_Enable      :: 1 << 11;
    }

    apic_base := << cast(*Apic_Base_Flags) *read_msr(.APIC_BASE__Apic_Base);
    assert(apic_base & .BSC__Boot_Strap_Core > 0);

    apic_base |= .AE__Apic_Enable;
    write_msr(.APIC_BASE__Apic_Base, cast(u64) apic_base);

    physical := cast(u64) apic_base & ~0xfff;
    assert(0xfee0_0000 == physical);
    assert(acpi_header.local_apic_address == cast(u32) physical);

    virtual := alloc_block(*kernel_globals.virtual_block_allocator, 4096); // Allocating an individual page using the block allocator because we don't have anything better for virtual memory yet
    map_page(virtual, physical, Page_Flags.READ_WRITE | .PRESENT | .CACHE_DISABLE);

    kernel_globals.apic = cast(*void) virtual;

    cursor := cast(u64) acpi_header + size_of(Acpi_MADT);

    my_id := read_apic_register(.APIC_ID);
    other_apic_ids: [..] u32;

    while cursor < cast(u64) acpi_header + acpi_header.length {
        ics := cast(*Acpi_MADT.Interrupt_Controller_Structure) cursor;

        if ics.type == .LOCAL_APIC {
            lapic := cast(*Acpi_MADT.Ics_Local_Apic) ics;

            if lapic.apic_id != my_id {
                array_add(*other_apic_ids, lapic.apic_id);
            }
        } else if ics.type == .IO_APIC {
            assert(kernel_globals.io_apic == null);

            ioapic_ics := cast(*Acpi_MADT.Ics_Io_Apic) ics;
            virtual := alloc_block(*kernel_globals.virtual_block_allocator, 4096);
            map_page(virtual, ioapic_ics.address, Page_Flags.READ_WRITE | .PRESENT | .CACHE_DISABLE);

            assert(ioapic_ics.address == 0xfec0_0000);

            kernel_globals.io_apic = cast(*u32) virtual;
        } else if ics.type == .INTERRUPT_SOURCE_OVERRIDE {
            iso := cast(*Acpi_MADT.Ics_Source_Override) ics;
            print("Interrupt source override: %\n", << iso);
        }

        cursor += ics.length;
    }


    register_interrupt_gate(xx int__timer_interrupt, 49);

    write_apic_register(.TIC__TIMER_INITIAL, 0x0800_0000);

    lvtt := << cast(*Acpi_Lvt) *read_apic_register(.LVT__TIMER);
    lvtt.vector = 49;
    lvtt.flags &= ~.M__mask;
    write_apic_register(.LVT__TIMER, << cast(*u32) *lvtt);

    #asm {
        sti;
    }

    for other_apic_ids print("Found APIC ID: %\n", it);

    // Load the 16 bit AP initialization routine that was placed into static memory using metaprogramming
    memcpy(cast(*void) 0x8000 + DIRECT_MAPPING_BASE, ap_startup_bin.data, 4096);

    stack := alloc_block(*physical_block_allocator, 0x20_0000) + DIRECT_MAPPING_BASE;
    << cast(*u64)   (0x8200 + DIRECT_MAPPING_BASE) = stack; // Hardcoded offset from ap_startup_bin
    << cast(**void) (0x8208 + DIRECT_MAPPING_BASE) = cast(*void) ap_startup;
    << cast(*u32)   (0x8210 + DIRECT_MAPPING_BASE) = cast(u32) boot_data.page_tables.pml4.data;

    for other_apic_ids {
        write_apic_register(.DES__INTERRUPT_DEST, xx it << 24);

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

    code := read_entire_file(".build/ap_startup.bin");
    return add_global_data(cast([] u8) code, .WRITABLE);
}

ap_startup :: () #c_call {
    push_context .{} {
        write_string("AP Startup\n");
        while true #asm { cli; hlt; }
    }
}




// HPET (High precision timer)

Hpet_Acpi_Table :: struct {
    #as header: Acpi_Table_Header;
    hardware_revision: u8;
    flags: u8;
    vendor: u16;
    address_space: enum u8 { MAIN_MEMORY :: 0; IO :: 1; };
    stuff: [3] u8;
    base_address: u64 #align 1;
}

Hpet_Register :: enum u64 {
    CAPABILITIES :: 0x0;
    CONFIG       :: 0x10;
    STATUS       :: 0x20;
    COUNTER      :: 0xf0;

    TIMER0       :: 0x100;
    TIMER0_COMP  :: 0x108;
    TIMER1       :: 0x120;
    TIMER1_COMP  :: 0x128;
    TIMER2       :: 0x140;
    TIMER2_COMP  :: 0x148;
}

write :: (reg: Hpet_Register, value: u64) #no_context {
    << cast(*u64) (high_precision_timer.base_address + cast(u64) reg) = value;
}

read :: (reg: Hpet_Register) -> u64 #no_context {
    return << cast(*u64) (high_precision_timer.base_address + cast(u64) reg);
}

HPET :: struct {
    initialized: bool;

    base_address: *void;
    base_period_femtoseconds: u64;

    ticks_per_interrupt: u64;
    total_ticks: Apollo_Time;

    _64bit_counter: bool;
    counter_value_at_last_interrupt: u64;
}

init_hpet :: () {
    acpi_header := find_acpi_table("HPET");
    assert(acpi_header != null, "HPET is not available");

    acpi_table := cast(*Hpet_Acpi_Table) acpi_header;
    assert(acpi_table.address_space == .MAIN_MEMORY);

    virtual := alloc_block(*kernel_globals.virtual_block_allocator, 4096); // Allocating an individual page using the block allocator because we don't have anything better for virtual memory yet

    map_page(virtual, acpi_table.base_address, Page_Flags.READ_WRITE | .PRESENT | .CACHE_DISABLE);

    offset_in_page := acpi_table.base_address % 0x1000;
    high_precision_timer.base_address = xx (virtual + offset_in_page);

    capabilities := read(Hpet_Register.CAPABILITIES);

    LEG_RT_CAP :: 0x8000;
    assert(capabilities & LEG_RT_CAP > 0, "HPET does not support legacy replacement route");

    COUNT_SIZE_CAP :: 0x2000;
    high_precision_timer._64bit_counter = capabilities & COUNT_SIZE_CAP > 0;

    high_precision_timer.base_period_femtoseconds = capabilities >> 32;
    assert(high_precision_timer.base_period_femtoseconds > 0 && high_precision_timer.base_period_femtoseconds < 100_000_000);

    hpet_restart();

    high_precision_timer.initialized = true;
}

hpet_enable_interrupts :: (freq: u64) {
    LEG_RT_CNF :: 0x2; // Enable legacy mode until we support allocating interrupts
    write(.CONFIG, read(.CONFIG) | LEG_RT_CNF);

    timer := read(.TIMER0);

    Tn_PER_INT_CAP :: 0x10;
    assert(timer & Tn_PER_INT_CAP > 0, "HPET timer 0 is not periodic capable");

    // Tn_SIZE_CAP :: 0x20;
    // assert(timer & Tn_SIZE_CAP > 0, "HPET timer 0 is not 64bit");

    Tn_INT_TYPE_CNF :: 0x2;  // Interrupt type (0=edge  1=level)
    Tn_INT_ENB_CNF  :: 0x4;  // Interrupt enable
    Tn_TYPE_CNF     :: 0x8;  // Timer type (0=non-periodic  1=periodic)
    Tn_VAL_SET_CNF  :: 0x40; // Periodic-mode enable write accumulator

    timer |= (Tn_TYPE_CNF | Tn_INT_ENB_CNF | Tn_VAL_SET_CNF);
    timer &= ~Tn_INT_TYPE_CNF;

    write(.TIMER0, timer);

    ticks_per_second := cast(u64) 1_000_000_000_000_000 / high_precision_timer.base_period_femtoseconds;
    high_precision_timer.ticks_per_interrupt = ticks_per_second / freq;

    write(.TIMER0_COMP, high_precision_timer.ticks_per_interrupt);

    register_interrupt_gate(xx int__hpet_interrupt, 55);
    // Allocate INTI2 (interrupt input 2) for the HPET.

    // Get INTI2 redirection entry.
    io_apic.* = 0x14;
    (io_apic + 4).* = 55;

    io_apic.* = 0x15;
    (io_apic + 4).* = 0;

    hpet_restart();
}

hpet_restart :: () {
    ENABLE_CNF :: 0x1;
    config := read(Hpet_Register.CONFIG);

    write(.CONFIG, config & ~ENABLE_CNF);
    write(Hpet_Register.COUNTER, 0);
    write(.CONFIG, config | ENABLE_CNF);
}

#program_export
hpet_interrupt :: (data: *Interrupt_Data(false)) #c_call {
    push_context .{} {
        serial_out("HPET Tick\n");
        while true #asm { cli; hlt; }
    }
} @InterruptHandler




#program_export
fault_0 :: (stack: *void) #c_call {
    push_context .{} {
        serial_out("Something bad happened (0)\n");
        while true #asm { cli; hlt; }
    }
} @InterruptHandler

#program_export
fault_1 :: (stack: *void) #c_call {
    push_context .{} {
        serial_out("Something bad happened (1)\n");
        while true #asm { cli; hlt; }
    }
} @InterruptHandler

#program_export
fault_2 :: (stack: *void) #c_call {
    push_context .{} {
        serial_out("Something bad happened (2)\n");
        while true #asm { cli; hlt; }
    }
} @InterruptHandler

#program_export
fault_3 :: (stack: *void) #c_call {
    push_context .{} {
        serial_out("Something bad happened (3)\n");
        while true #asm { cli; hlt; }
    }
} @InterruptHandler

#program_export
fault_4 :: (stack: *void) #c_call {
    push_context .{} {
        serial_out("Something bad happened (4)\n");
        while true #asm { cli; hlt; }
    }
} @InterruptHandler

#program_export
fault_5 :: (stack: *void) #c_call {
    push_context .{} {
        serial_out("Something bad happened (5)\n");
        while true #asm { cli; hlt; }
    }
} @InterruptHandler

#program_export
fault_6 :: (stack: *void) #c_call {
    push_context .{} {
        serial_out("Something bad happened (6)\n");
        while true #asm { cli; hlt; }
    }
} @InterruptHandler

#program_export
fault_7 :: (stack: *void) #c_call {
    push_context .{} {
        serial_out("Something bad happened (7)\n");
        while true #asm { cli; hlt; }
    }
} @InterruptHandler

#program_export
fault_8 :: (stack: *void) #c_call {
    push_context .{} {
        serial_out("Something bad happened (8)\n");
        while true #asm { cli; hlt; }
    }
} @InterruptHandler

#program_export
fault_9 :: (stack: *void) #c_call {
    push_context .{} {
        serial_out("Something bad happened (9)\n");
        while true #asm { cli; hlt; }
    }
} @InterruptHandler

#program_export
fault_10 :: (stack: *void) #c_call {
    push_context .{} {
        serial_out("Something bad happened (10)\n");
        while true #asm { cli; hlt; }
    }
} @InterruptHandler

#program_export
fault_11 :: (stack: *void) #c_call {
    push_context .{} {
        serial_out("Something bad happened (11)\n");
        while true #asm { cli; hlt; }
    }
} @InterruptHandler

#program_export
fault_12 :: (stack: *void) #c_call {
    push_context .{} {
        serial_out("Something bad happened (12)\n");
        while true #asm { cli; hlt; }
    }
} @InterruptHandler

#program_export
general_protection_fault :: (stack: *Interrupt_Data(true)) #c_call {
    push_context .{} {
        print("General Protection Fault.\n");
        print("RIP: 0x%\n", formatInt(stack.ip, base=16));
        print("RSP: 0x%\n", formatInt(stack.sp, base=16));
        print("SS: 0x%\n", formatInt(stack.ss, base=16));
        print("CS: 0x%\n", formatInt(stack.cs, base=16));
        print("Error Code: 0x%\n", formatInt(stack.error_code, base=16));
        print_stack_trace(main_thread_context.stack_trace);

        while true #asm { cli; hlt; }
    }
} @InterruptHandler

#program_export
fault_14 :: (stack: *void) #c_call {
    push_context .{} {
        serial_out("Something bad happened (14)\n");
        while true #asm { cli; hlt; }
    }
} @InterruptHandler

#program_export
fault_15 :: (stack: *void) #c_call {
    push_context .{} {
        serial_out("Something bad happened (15)\n");
        while true #asm { cli; hlt; }
    }
} @InterruptHandler
