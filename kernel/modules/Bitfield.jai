
#import "Basic";
#import "Compiler";

bitfield_0  :: 0x100;
bitfield_1  :: 0x200;
bitfield_2  :: 0x300;
bitfield_3  :: 0x400;
bitfield_4  :: 0x500;
bitfield_5  :: 0x600;
bitfield_6  :: 0x700;
bitfield_7  :: 0x800;
bitfield_8  :: 0x900;
bitfield_9  :: 0x1000;
bitfield_10 :: 0x1100;




Gate_Descriptor_Flags :: enum u16 {
    interrupt_stack_table :: 3 |bitfield_0;
    ignored               :: 5 |bitfield_1;
    gate_type             :: 4 |bitfield_2;
    always_zero           :: 1 |bitfield_3;
    protection_level      :: 2 |bitfield_4;
    present               :: 1 |bitfield_5;
}

validate_bitfield :: (bitfield: *Type_Info, loc: Source_Code_Location) {
    if bitfield.type != .ENUM {
        compiler_report("Argument to bitfield_set is not an enum.", loc);
        return;
    }

    ti := cast(*Type_Info_Enum) bitfield;

    total_width: int;
    for ti.values {
        bit_width := it % 0x100;

        expected_tag := (it_index+1) * 0x100;
        actual_tag   := it - bit_width;

        if expected_tag != actual_tag {
            error_message := tprint("Bitfield \"%\" tags are not sequentially assigned. The tag at index %2 should have been bitfield_%2.", ti.name, it_index);
            compiler_report(error_message, loc);
        }

        total_width += bit_width;
    }

    expected_width := bitfield.runtime_size*8;
    if total_width != expected_width {
        error_message := tprint("Bitfield \"%\" values do not sum to the width of its integer type. The total width was %, expected %", ti.name, total_width, expected_width);
        compiler_report(error_message, loc);
    }
}

bitfield_set :: (bitfield: *$B, $flag: B, value: s64, $loc := #caller_location, call := #caller_code) {

    bit_mask, bit_offset := #run -> int, int {
        ti := type_info(B);
        validate_bitfield(ti, loc);

        bit_offset: int;

        found: bool;
        for ti.values {
            if it == cast(s64) flag {
                found = true;
                break;
            }

            bit_offset += it % 0x100;
        }

        if !found {
            error_message := tprint("Trying to set a field on bitfield \"%\", that it doesn't contain.", ti.name);
            compiler_report(error_message, loc);
        }

        bit_count := (cast(int) flag % 0x100);

        bit_mask: int = 1;
        for 1..bit_count bit_mask *= 2;
        bit_mask -= 1;

        bit_mask <<= bit_offset;
        return bit_mask, bit_offset;
    };

    bitfield.* &= cast,no_check(B) (~bit_mask);
    bitfield.* |= cast,no_check(B) ((value << bit_offset) & bit_mask);
}

set :: bitfield_set;

#run {
    flags: Gate_Descriptor_Flags;
    bitfield_set(*flags, .protection_level, 3);

    print("Flags is %\n", formatInt(cast(int) flags, base=2));
}
