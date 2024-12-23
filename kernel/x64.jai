
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
    cs:    Gdt_Segment_Offset;
    flags: X64_Flags;
    sp:    *void;
    ss:    Gdt_Segment_Offset;
}

Interrupt_Gate_Desc :: struct {
    offset_1: u16;
    segment:  Gdt_Segment_Offset;
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
}

Global_Descriptor_Table :: struct {
    null_entry: u64;
    ring0_code: Gdt_Entry_Flags;
    ring0_data: Gdt_Entry_Flags;
    ring3_code: Gdt_Entry_Flags;
    ring3_data: Gdt_Entry_Flags;
    terminator: u64;
}

Gdt_Segment_Offset :: enum u16 {
    RING0_CODE :: 0x08;
    RING0_DATA :: 0x10;
    RING3_CODE :: 0x18;
    RING3_DATA :: 0x20;
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

Ia32_Model_Specific_Register :: enum {
    APIC_BASE__Apic_Base      :: 0x0000_001b;
    PAT__page_attribute_table :: 0x0000_0277;
    EFER__extended_features   :: 0xc000_0080;
    STAR__syscall_segment     :: 0xc000_0081;
    LSTAR__syscall_address    :: 0xc000_0082;
    FMASK__syscall_flags      :: 0xc000_0084;
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
