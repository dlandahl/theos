
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

    // Note that this is only aligned to 4 bytes, so if you put this in a struct followed by a u64, it will be wrong.
} #no_padding

Acpi_FADT__Fixed_Description_Table :: struct {
    #as header: Acpi_Table_Header;
    firmware_ctrl: u32;
    dsdt_address: u32;

    // Todo: doesn't handle 64bit dsdt address
    // https://uefi.org/htmlspecs/ACPI_Spec_6_4_html/05_ACPI_Software_Programming_Model/ACPI_Software_Programming_Model.html?highlight=dsdt#fadt-format
}

find_acpi_table :: (signature: string) -> *Acpi_Table_Header {
    table_size := kernel_globals.root_acpi_table.length - size_of(Acpi_Table_Header);

    pointer_size := cast(u64) (ifx kernel_globals.acpi_version then 8 else 4);
    pointer_count := table_size / pointer_size;

    table_base := cast(u64) (kernel_globals.root_acpi_table + 1);

    for table_index: 0..pointer_count - 1 {
        offset := table_index * pointer_size + table_base;

        phys := ifx kernel_globals.acpi_version {
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
    EXTENDED_FEATURE          :: 0x400;
}

read_apic_register :: (register: APIC_Register) -> u32 #no_context {
    if kernel_globals.apic == null {
        bluescreen();
    }

    return << cast(*u32) (kernel_globals.apic + cast(u64) register);
}

write_apic_register :: (register: APIC_Register, value: u32) #no_context {
    if kernel_globals.apic == null {
        bluescreen();
    }

    << cast(*u32) (kernel_globals.apic + cast(u64) register) = value;
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

apic_stuff :: () {
    register_interrupt_gate(int__fault_0, 0, true);
    register_interrupt_gate(int__fault_1, 1, true);
    register_interrupt_gate(int__fault_2, 2, true);
    register_interrupt_gate(int__fault_3, 3, true);
    register_interrupt_gate(int__fault_4, 4, true);
    register_interrupt_gate(int__fault_5, 5, true);
    register_interrupt_gate(int__fault_6, 6, true);
    register_interrupt_gate(int__fault_7, 7, true);
    register_interrupt_gate(int__fault_8, 8, true);
    register_interrupt_gate(int__fault_9, 9, true);
    register_interrupt_gate(int__fault_10, 10, true);
    register_interrupt_gate(int__fault_11, 11, true);
    register_interrupt_gate(int__fault_12, 12, true);
    register_interrupt_gate(int__general_protection_fault, 13, true);
    register_interrupt_gate(int__fault_14, 14, true);
    register_interrupt_gate(int__fault_15, 15, true);

    acpi_header := cast(*Acpi_MADT) find_acpi_table("APIC");

    Apic_Base_Flags :: enum_flags {
        BSC__Boot_Strap_Core :: 1 << 8;
        EXTD__2xApic_Mode    :: 1 << 10;
        AE__Apic_Enable      :: 1 << 11;
    }

    apic_base := << cast(*Apic_Base_Flags) *read_msr(.APIC_BASE__apic_base);
    assert(apic_base & .BSC__Boot_Strap_Core > 0);

    apic_base |= .AE__Apic_Enable;
    write_msr(.APIC_BASE__apic_base, cast(u64) apic_base);

    {
        physical := cast(u64) apic_base & ~0xfff;
        assert(0xfee0_0000 == physical);
        assert(acpi_header.local_apic_address == cast(u32) physical);

        // Allocating an individual page using the block allocator because we don't have anything better for virtual memory yet
        // Can't use the direct mapping because we want cache disabled for this page
        virtual := alloc_block(*kernel_globals.virtual_block_allocator, 4096);
        map_page(virtual, physical, Page_Flags.READ_WRITE | .PRESENT | .CACHE_DISABLE);

        kernel_globals.apic = cast(*void) virtual;
    }

    //
    // Iterate interrupt controller structures
    //

    bootstrap_processor_local_apic_id := read_apic_register(.APIC_ID);
    other_apic_ids: [..] u32;

    cursor := cast(u64) acpi_header + size_of(Acpi_MADT);

    while cursor < cast(u64) acpi_header + acpi_header.length {
        ics := cast(*Acpi_MADT.Interrupt_Controller_Structure) cursor;
        defer cursor += ics.length;

        if ics.type == {
          case .LOCAL_APIC;
            lapic_ics := cast(*Acpi_MADT.Ics_Local_Apic) ics;

            if lapic_ics.apic_id == bootstrap_processor_local_apic_id {
                continue;
            }

            // Apparently we should be able to use the ONLINE_CAPABLE bit in the ics flags to determine if
            // this processor core is usable, but for some reason it's always 0 in Qemu and Vbox.

            array_add(*other_apic_ids, lapic_ics.apic_id);

          case .IO_APIC;
            assert(kernel_globals.io_apic == null);

            ioapic_ics := cast(*Acpi_MADT.Ics_Io_Apic) ics;

            virtual := alloc_block(*kernel_globals.virtual_block_allocator, 4096);
            map_page(virtual, ioapic_ics.address, Page_Flags.READ_WRITE | .PRESENT | .CACHE_DISABLE);

            kernel_globals.io_apic = cast(*u32) virtual;

            assert(ioapic_ics.address == 0xfec0_0000);

          case .INTERRUPT_SOURCE_OVERRIDE;
            iso := cast(*Acpi_MADT.Ics_Source_Override) ics;
            // Todo
        }
    }

    #asm {
        sti;
    }

    for other_apic_ids print("Found APIC ID: %\n", it);

    // Load the 16 bit AP initialization routine from static memory
    memcpy(cast(*void) 0x8000 + DIRECT_MAPPING_BASE, ap_startup_bin.data, 4096);

    Ap_Startup_Data :: struct {
        // Layout matches the ap_startup assembly code in first.jai
        stack: u64;
        entry_point: *void;
        pml4: u32 #align 8;
    }

    ap_startup_data := cast(*Ap_Startup_Data) (0x8200 + DIRECT_MAPPING_BASE);
    ap_startup_data.entry_point = cast(*void) ap_entry_point;
    ap_startup_data.pml4 = cast(u32) kernel_globals.boot_data.page_tables.pml4.data;

    for other_apic_ids {
        // This lock is to ensure that APs have time to copy their stack's base address into their stack register before the next AP is started up.
        // Maybe if processors could use their APIC ID to find their stack memory it would be faster
        acquire(*ap_stack_lock);

        stack := alloc_block(*kernel_globals.physical_block_allocator, 0x1_0000) + DIRECT_MAPPING_BASE;
        ap_startup_data.stack = stack;

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

ap_stack_lock: Spinlock;

ap_entry_point :: () #c_call {
    using kernel_globals;

    release(*ap_stack_lock);

    {
        gdt_desc: struct {
            limit: u16;
            base: *Global_Descriptor_Table #align 2;
        }

        gdt_desc.limit = size_of(Global_Descriptor_Table);
        gdt_desc.base = *global_descriptor_table;
        pointer := *gdt_desc;
        #asm { lgdt [pointer]; }

        init_segment_registers();
    }

    {
        idt_desc: struct {
            limit: u16;
            base: *Interrupt_Gate_Desc #align 2;
        }

        idt_desc.limit = size_of(type_of(interrupt_descriptor_table));
        idt_desc.base = interrupt_descriptor_table.data;

        pointer := *idt_desc;
        #asm { lidt [pointer]; }
    }

    apic_id := read_apic_register(.APIC_ID);

    acquire(*ap_startup_message_lock);
    write_string("AP Startup - ");
    write_number(apic_id, base=16);
    write_string(" -\n");
    release(*ap_startup_message_lock);

    while true #asm { cli; hlt; }
}

ap_startup_message_lock: Spinlock;



ioapic_add_interrupt_redirection_table_entry :: (redirection_index: u32, gate_number: int) {
    REDIRECTION_TABLE_BASE       : u32 : 0x10;
    REDIRECTION_TABLE_ENTRY_SIZE : u32 : 0x2;

    register_index := REDIRECTION_TABLE_BASE + redirection_index * REDIRECTION_TABLE_ENTRY_SIZE;

    kernel_globals.io_apic[0] = register_index;
    kernel_globals.io_apic[4] = cast(u32) gate_number;

    kernel_globals.io_apic[0] = register_index+1;
    kernel_globals.io_apic[4] = 0;
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
    << cast(*u64) (kernel_globals.high_precision_timer.base_address + cast(u64) reg) = value;
}

read :: (reg: Hpet_Register) -> u64 #no_context {
    return << cast(*u64) (kernel_globals.high_precision_timer.base_address + cast(u64) reg);
}

Hpet_Config_Flags :: enum_flags u64 {
    ENABLE         :: 0x1;
    LEGACY_ROUTING :: 0x2;
}

Hpet_Capability_Flags :: enum_flags u64 {
    SIXTYFOUR_BIT_COUNTER :: 0x2000;
    LEGACY_ROUTING        :: 0x8000;
}

Hpet_Timer_Flags :: enum_flags u64 {
    INTERRUPT_TYPE           :: 0x2;  // (0=edge  1=level)
    INTERRUPT_ENABLE         :: 0x4;
    PERIODIC_ENABLE          :: 0x8;
    PERIODIC_CAPABLE         :: 0x10;
    SIXTYFOUR_BIT_CAPABLE    :: 0x20;
    WRITE_ACCUMULATOR_ENABLE :: 0x40;
}

HPET :: struct {
    base_address: *void;
    base_period_femtoseconds: u64;

    counters_are_64_bit: bool;
    counters: [2] u64;
}

initialize_hpet :: () {
    hpet := *kernel_globals.high_precision_timer;

    acpi_header := find_acpi_table("HPET");

    if acpi_header == null {
        log_error("HPET is not available");
        bluescreen();
    }

    acpi_table := cast(*Hpet_Acpi_Table) acpi_header;
    assert(acpi_table.address_space == .MAIN_MEMORY);

    virtual := alloc_block(*kernel_globals.virtual_block_allocator, 4096); // Allocating an individual page using the block allocator because we don't have anything better for virtual memory yet
    map_page(virtual, acpi_table.base_address, Page_Flags.READ_WRITE | .PRESENT | .CACHE_DISABLE);

    offset_in_page := acpi_table.base_address % 0x1000;
    hpet.base_address = xx (virtual + offset_in_page);

    capabilities := cast(Hpet_Capability_Flags) read(Hpet_Register.CAPABILITIES);

    if !(capabilities & .LEGACY_ROUTING) {
        log_error("HPET does not support legacy replacement route");
        bluescreen();
    }

    // Todo: might have to check this per-counter
    hpet.counters_are_64_bit = capabilities & .SIXTYFOUR_BIT_COUNTER > 0;
    hpet.base_period_femtoseconds = cast(u64) (capabilities >> 32);

    write(.CONFIG, read(.CONFIG) | cast(u64) Hpet_Config_Flags.LEGACY_ROUTING);

    hpet_restart();


    // Interrupt routing

    t0_gate := cast(u32) allocate_interrupt_gate();
    t1_gate := cast(u32) allocate_interrupt_gate();

    register_interrupt_gate(int__hpet_timer0_interrupt, t0_gate);
    register_interrupt_gate(int__hpet_timer1_interrupt, t1_gate);

    // Get INTI2/8 redirection entry. The numbers 2 and 8 come from the legacy replacement routing.
    // Todo: need to detect if there is an interrupt source override in the MADT.
    ioapic_add_interrupt_redirection_table_entry(2, t0_gate);
    ioapic_add_interrupt_redirection_table_entry(8, t1_gate);
}

hpet_configure_timer :: (timer_index: int, frequency: u64, periodic: bool) {
    hpet := *kernel_globals.high_precision_timer;
    register_offset := cast(Hpet_Register) (0x20 * timer_index);

    timer := cast(Hpet_Timer_Flags) read(register_offset + .TIMER0);

    if !(timer & .PERIODIC_CAPABLE) log("HPET timer % is not periodic capable", timer_index);

    timer |=  (.INTERRUPT_ENABLE | .WRITE_ACCUMULATOR_ENABLE);
    timer &= ~ .INTERRUPT_TYPE;

    if periodic  timer |=  .PERIODIC_ENABLE;
    else         timer &= ~.PERIODIC_ENABLE;

    write(register_offset + .TIMER0, cast(u64) timer);

    ticks_per_second    := cast(u64) 1_000_000_000_000_000 / hpet.base_period_femtoseconds;
    ticks_per_interrupt := ticks_per_second / frequency;

    write(register_offset + .TIMER0_COMP, ticks_per_interrupt);

    hpet.counters[timer_index] = 0;
}

hpet_restart :: () {
    config := read(Hpet_Register.CONFIG);

    ENABLE_BIT :: cast(u64) Hpet_Config_Flags.ENABLE;

    write(.CONFIG, config & ~ENABLE_BIT);
    write(Hpet_Register.COUNTER, 0);
    write(.CONFIG, config | ENABLE_BIT);
}

#program_export hpet_timer0_interrupt :: (data: *Interrupt_Stack()) #c_call {
    kernel_globals.high_precision_timer.counters[0] += 1;
    write_apic_register(.EOI__END_OF_INTERRUPT, 0);
} @InterruptRoutine

#program_export hpet_timer1_interrupt :: (data: *Interrupt_Stack()) #c_call {
    kernel_globals.high_precision_timer.counters[1] += 1;
    write_apic_register(.EOI__END_OF_INTERRUPT, 0);
} @InterruptRoutine



#program_export fault_0 :: (stack: *void) #c_call {
    write_string("Something bad happened (0)\n");
    bluescreen();
} @InterruptRoutine

#program_export fault_1 :: (stack: *void) #c_call {
    write_string("Something bad happened (1)\n");
    bluescreen();
} @InterruptRoutine

#program_export fault_2 :: (stack: *void) #c_call {
    write_string("Something bad happened (2)\n");
    bluescreen();
} @InterruptRoutine

#program_export fault_3 :: (stack: *void) #c_call {
    write_string("Something bad happened (3)\n");
    bluescreen();
} @InterruptRoutine

#program_export fault_4 :: (stack: *void) #c_call {
    write_string("Something bad happened (4)\n");
    bluescreen();
} @InterruptRoutine

#program_export fault_5 :: (stack: *void) #c_call {
    write_string("Something bad happened (5)\n");
    bluescreen();
} @InterruptRoutine

#program_export fault_6 :: (stack: *Interrupt_Stack(false)) #c_call {
    c: Context;
    c.print_style.default_format_int.base = 16;

    push_context c {
        print("Invalid Opcode.\n");
        print("RIP: 0x%\n", stack.ip);
        print("RSP: 0x%\n", stack.sp);
        print("SS: 0x%\n", stack.ss);
        print("CS: 0x%\n", stack.cs);
        bluescreen();
    }
} @InterruptRoutine

#program_export fault_7 :: (stack: *void) #c_call {
    write_string("Something bad happened (7)\n");
    bluescreen();
} @InterruptRoutine

#program_export fault_8 :: (stack: *void) #c_call {
    write_string("Something bad happened (8)\n");
    bluescreen();
} @InterruptRoutine

#program_export fault_9 :: (stack: *void) #c_call {
    write_string("Something bad happened (9)\n");
    bluescreen();
} @InterruptRoutine

#program_export fault_10 :: (stack: *void) #c_call {
    write_string("Something bad happened (10)\n");
    bluescreen();
} @InterruptRoutine

#program_export fault_11 :: (stack: *void) #c_call {
    write_string("Something bad happened (11)\n");
    bluescreen();
} @InterruptRoutine

#program_export fault_12 :: (stack: *void) #c_call {
    write_string("Something bad happened (12)\n");
    bluescreen();
} @InterruptRoutine

#program_export
general_protection_fault :: (stack: *Interrupt_Stack(with_error_code = true)) #c_call {
    c: Context;
    c.print_style.default_format_int.base = 16;

    push_context c {
        print("General Protection Fault.\n");
        print("RIP: 0x%\n", stack.ip);
        print("RSP: 0x%\n", stack.sp);
        print("SS: 0x%\n", stack.ss);
        print("CS: 0x%\n", stack.cs);
        print("Error Code: 0x%\n", stack.error_code);

        print("Stack trace of the main thread:\n");
        print_stack_trace(kernel_globals.main_thread_context.stack_trace);

        bluescreen();
    }
} @InterruptRoutine

#program_export fault_14 :: (stack: *void) #c_call {
    write_string("Something bad happened (14)\n");
    bluescreen();
} @InterruptRoutine

#program_export fault_15 :: (stack: *void) #c_call {
    write_string("Something bad happened (15)\n");
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
    // We can cast this to a physical address, because the RSDP is stored in identity-mapped UEFI memory.
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
        case 1; #asm { in.b value, address; }
        case 2; #asm { in.w value, address; }
        case 4; #asm { in.d value, address; }
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
        case 1; #asm { out.b address, value; }
        case 2; #asm { out.w address, value; }
        case 4; #asm { out.d address, value; }
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
    c: Context;
    push_context c {
        phys := alloc_block(*kernel_globals.physical_block_allocator, cast(s64) size);
        virt := cast(*void) phys + DIRECT_MAPPING_BASE;

        return virt;
    }
}

#program_export uacpi_kernel_calloc :: (count: uacpi_size, size: uacpi_size) -> *void #c_call {
    // Comment in uacpi_kernel_alloc applies
    size_bytes := cast(s64) (size*count);

    c: Context;
    push_context c {
        phys := alloc_block(*kernel_globals.physical_block_allocator, size_bytes);
        virt := cast(*void) phys + DIRECT_MAPPING_BASE;

        memset(virt, 0, size_bytes);
        return virt;
    }
}

#program_export uacpi_kernel_free :: (mem: *void) #c_call {
    // Comment in uacpi_kernel_alloc applies
    if mem == null return;

    c: Context;
    push_context c {
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
