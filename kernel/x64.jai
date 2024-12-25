
X64_Flags :: enum_flags u64 {
    CF__carry  :: 0x1;
    PF__parity :: 0x4;
    AF__adjust :: 0x10;
    ZF__zero   :: 0x40;
    SF__sign   :: 0x80;
    TF__trap   :: 0x100;
    IF__interrupt :: 0x200;
    DF__direction :: 0x400;
    OF__overflow  :: 0x800;
    RF__resume    :: 0x10000;
}

Syscall_Stack :: struct {
    r15:  u64;
    r14:  u64;
    r13:  u64;
    r12:  u64;
    r11:  u64;
    r10:  u64;
    r9:   u64;
    r8:   u64;
    rbp:  u64;
    rdi:  u64;
    rsi:  u64;
    rdx:  u64;
    rcx:  u64;
    rbx:  u64;
    rax:  u64;
}

Interrupt_Stack :: struct (with_error_code := false) {
    r15:  u64;
    r14:  u64;
    r13:  u64;
    r12:  u64;
    r11:  u64;
    r10:  u64;
    r9:   u64;
    r8:   u64;
    rbp:  u64;
    rdi:  u64;
    rsi:  u64;
    rdx:  u64;
    rcx:  u64;
    rbx:  u64;
    rax:  u64;

#if with_error_code {
    error_code: u64;
}

    ip:    *void;
    cs:    Segment_Selector;
    flags: X64_Flags;
    sp:    *void;
    ss:    Segment_Selector;
}

Interrupt_Gate_Desc :: struct {
    offset_1: u16;
    segment:  Segment_Selector;
    ist:      u8;
    flags:    u8;
    offset_2: u16;
    offset_3: u32;
    reserved: u32;
}

register_interrupt_gate :: (handler: () #c_call, index: int, trap := false) {
    desc := *kernel_globals.interrupt_descriptor_table[index];
    address := cast(u64) cast(*void) handler;

    desc.offset_1 = xx  address        & 0xffff;
    desc.offset_2 = xx (address >> 16) & 0xffff;
    desc.offset_3 = xx (address >> 32) & 0xffffffff;
    desc.segment  = .RING0_CODE;
    desc.ist      = 0x0;
    desc.flags    = cast(u8) ifx trap 0x8f else 0x8e;
    desc.reserved = 0x0;

    // Allow all gates to be used in ring 3 for now.
    desc.flags   |= 0b1100000;
}

Global_Descriptor_Table :: struct {
    null_entry: u64;
    ring0_code: Gdt_Entry_Flags;
    ring0_data: Gdt_Entry_Flags;
    ring3_data: Gdt_Entry_Flags;
    ring3_code: Gdt_Entry_Flags;
    task_state: System_Segment_Descriptor;
    terminator: u64;
}

Segment_Selector :: enum u16 {
    RING0_CODE :: 0x08;
    RING0_DATA :: 0x10;
    RING3_DATA :: 0x18|3;
    RING3_CODE :: 0x20|3;
}

Gdt_Entry_Flags :: enum u64 {
    AVAILABLE       :: 0x01 << 52;
    LONG_MODE_CODE  :: 0x02 << 52;
    SIZE            :: 0x04 << 52;
    GRANULARITY     :: 0x08 << 52;
    ACCESSED        :: 0x01 << 40;
    READ_WRITE      :: 0x02 << 40;
    DIRECTION       :: 0x04 << 40;
    EXECUTABLE      :: 0x08 << 40;
    DESCRIPTOR_TYPE :: 0x10 << 40;
    PRIVILEGE0      :: 0x20 << 40;
    PRIVILEGE1      :: 0x40 << 40;
    PRESENT         :: 0x80 << 40;
}

Task_State_Segment :: struct {
    reserved_0: u32;
    rsp:        [3] u64 #align 4;
    reserved_1: [2] u32;
    ist:        [7] u64 #align 4;
    reserved_2: [2] u32;
    reserved_3: u16;
    iopb:       u16;
}

Tss_With_Iopb :: struct {
    using tss: Task_State_Segment;
    bitmap: [8192] u8;
}

System_Segment_Descriptor :: struct {
    segment_limit:  u16;
    base_address_0: u16;
    base_address_1: u8;
    flags_0:        u8;
    flags_1:        u8;
    base_address_2: u8;
    base_address_3: u32;
    reserved:       u32;
}



Ia32_Model_Specific_Register :: enum {
    APIC_BASE__apic_base      :: 0x0000_001b;
    PAT__page_attribute_table :: 0x0000_0277;
    EFER__extended_features   :: 0xc000_0080;
    STAR__syscall_segment     :: 0xc000_0081;
    LSTAR__syscall_address    :: 0xc000_0082;
    SFMASK__syscall_flags     :: 0xc000_0084;
}

write_msr :: (msr: Ia32_Model_Specific_Register, value: u64) {
    high := value >> 32;
    low := value & 0xffff_ffff;

    #asm {
        msr === c;
        high === d;
        low  === a;

        wrmsr high, low, msr;
    }
}

read_msr :: (msr: Ia32_Model_Specific_Register) -> u64 {
    low: u64;
    high: u64;

    #asm {
        msr === c;
        high === d;
        low === a;

        rdmsr high, low, msr;
    }

    return low | (high << 32);
}



enable_cpu_features :: () {
    cpu_features := get_cpu_info().feature_leaves;

    CR0_MP         :=   1 << 1;
    CR0_EM_CLEAR   := ~(1 << 2);

    CR4_OSFXSR     :=   1 << 9;
    CR4_OSXMMEXCPT :=   1 << 10;
    CR4_OSXSAVE    :=   1 << 18;
    CR4_FSGSBASE   :=   1 << 16;

    if check_feature(cpu_features, .SSE) {
        #asm {
            get_cr0 cr0:;
            and cr0, CR0_EM_CLEAR;
            or  cr0, CR0_MP;
            set_cr0 cr0;

            get_cr4 cr4:;
            or  cr4, CR4_OSFXSR;
            or  cr4, CR4_OSXMMEXCPT;
            set_cr4 cr4;
        }
    }

    if check_feature(cpu_features, .FSGSBASE) {
        #asm {
            get_cr4 cr4:;
            or  cr4, CR4_FSGSBASE;
            set_cr4 cr4;
        }
    }

    if check_feature(cpu_features, .XSAVE) {
        // This doesn't seem to be needed to execute fxsave64 etc. Maybe UEFI enables some CPU features for us
        #asm {
            get_cr4 cr4:;
            or  cr4, CR4_OSXSAVE;
            set_cr4 cr4;
        }
    }
}
