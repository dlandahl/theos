
Journal_Entry_Type :: enum u8 {
    TRANSACTION_BEGIN;
    TRANSACTION_END;
    PATCH_BYTES;
    ALLOCATE_BLOCK;
    FREE_BLOCK;
    WRAP;
}

Journal_Entry_Header :: struct {
    sequence: u64;
    type: Journal_Entry_Type;

    hole: [7] u8; // At the moment everything in the journal is aligned according to language rules.
}

Journal_Entry_Footer :: struct {
    sequence: u64;
    crc: u64;
}

Journal_Entry_Payload__Patch_Bytes :: struct {
    block: u64;
    byte_count: u32;
    byte_offset: u32;

    // Followed by byte_count number of bytes before the (aligned) footer.
}

Journal_Entry_Payload__Allocate_Block :: struct {
    block: u64;
    flags: enum_flags u8 { ZERO_ON_REPLAY; };

    hole: [7] u8;
}

Journal_Entry_Payload__Free_Block :: struct {
    block: u64;
}
