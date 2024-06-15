
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
            INTERRUPT_SOURCE_OVERRIDE :: 0x1;
            NON_MASKABLE_INTERRUPT    :: 0x4;
            MULTIPROCESSOR_WAKEUP     :: 0x10;
        }
    }

    Ics_Local_Apic :: struct {
        using ics: Interrupt_Controller_Structure;

        acpi_processor_uid: u8;
        apic_id: u8;

        flags: enum u32 {
            enabled;
            online_capable;
        };
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
    LVT__TIMER                :: 0x320;
    TIC__TIMER_INITIAL        :: 0x380;
    TCC__TIMER_CURRENT        :: 0x390;
    DV__TIMER_DIVIDE          :: 0x3e0;
}

read_apic_register :: (register: APIC_Register) -> u32 {
    return << cast(*u32) (apic + cast(u64) register);
}

write_apic_register :: (register: APIC_Register, value: u32) {
    << cast(*u32) (apic + cast(u64) register) = value;
}

Acpi_Lvt :: struct {
    vector: u8;

#place vector;
    flags: enum_flags u32 {
        DS__delivery_status :: 1 << 12;
        RIR__remote_irr     :: 1 << 14;
        TGM__trigger_mode   :: 1 << 15;
        M__mask             :: 1 << 16;
        TMM__timer_mode     :: 1 << 17;
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

apic_stuff :: () {
    register_interrupt_gate(xx fault_0_wrapper, 0);
    register_interrupt_gate(xx fault_1_wrapper, 1);
    register_interrupt_gate(xx fault_2_wrapper, 2);
    register_interrupt_gate(xx fault_3_wrapper, 3);
    register_interrupt_gate(xx fault_4_wrapper, 4);
    register_interrupt_gate(xx fault_5_wrapper, 5);
    register_interrupt_gate(xx fault_6_wrapper, 6);
    register_interrupt_gate(xx fault_7_wrapper, 7);
    register_interrupt_gate(xx fault_8_wrapper, 8);
    register_interrupt_gate(xx fault_9_wrapper, 9);
    register_interrupt_gate(xx fault_10_wrapper, 10);
    register_interrupt_gate(xx fault_11_wrapper, 11);
    register_interrupt_gate(xx fault_12_wrapper, 12);
    register_interrupt_gate(xx general_protection_fault_wrapper, 13);
    register_interrupt_gate(xx fault_14_wrapper, 14);
    register_interrupt_gate(xx fault_15_wrapper, 15);

    acpi_header := cast(*Acpi_MADT) find_acpi_table("APIC");

    cursor := cast(u32) acpi_header + size_of(Acpi_MADT);

    while cursor < cast(u32) acpi_header + acpi_header.length {
        ics := cast(*Acpi_MADT.Interrupt_Controller_Structure) cursor;

        if ics.type == {
          case .LOCAL_APIC;
            lapic := cast(*Acpi_MADT.Ics_Local_Apic) ics;
            print("Found Local APIC: %\n", << lapic);
          case;
            print("ICS type %\n", cast(u8) ics.type);
        }

        cursor += ics.length;
    }

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

    // Manual memory mapping because cache needs to be disabled for APIC accesses
    virtual := alloc_block(*kernel_globals.virtual_block_allocator, 4096); // Allocating an individual page using the block allocator because we don't have anything better for virtual memory yet
    map_page(virtual, physical, Page_Flags.READ_WRITE | .PRESENT | .CACHE_DISABLE);

    apic = cast(*void) virtual;
    version := read_apic_register(.APIC_VERSION);

    register_interrupt_gate(xx timer_interrupt_wrapper, 49);

    write_apic_register(.TIC__TIMER_INITIAL, 0x1000_0000);

    lvtt := << cast(*Acpi_Lvt) *read_apic_register(.LVT__TIMER);
    lvtt.vector = 49;
    lvtt.flags &= ~.M__mask;
    write_apic_register(.LVT__TIMER, << cast(*u32) *lvtt);

    #asm {
        sti;
    }

    while true {
        // tcc := read_apic_register(.TCC__TIMER_CURRENT);
        // serial_write_hex(tcc);
    }
}
