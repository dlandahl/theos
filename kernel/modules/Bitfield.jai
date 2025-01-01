
/*

Usage example:

    Gate_Descriptor_Flags :: enum u16 {
        interrupt_stack_table :: 3;
        ignored               :: 5;
        gate_type             :: 4;
        always_zero           :: 1;
        protection_level      :: 2;
        present               :: 1;
    }

    main :: () {
        set :: bitfield_set; // Optional

        gate_flags: Gate_Descriptor_Flags;

        set(*gate_flags, .protection_level, 3);
        set(*gate_flags, .interrupt_stack_table, 1);

        print("Flags is %\n", formatInt(cast(int) gate_flags, base=2));
    }

Todo: would like to have this syntax:

    Set(gate_flags.protection_level, 3);

*/

#module_parameters(ENABLE_RUNTIME_ERROR_CHECKS := true);

#scope_export

bitfield_set :: (bitfield: *$B, flag: B, value: s64, $loc := #caller_location, $call := #caller_code) {
    bit_mask, bit_offset := #run calculate_mask_and_offset(B, loc, call);

    #if ENABLE_RUNTIME_ERROR_CHECKS {
        max_value := bit_mask >> bit_offset;
        assert(value <= max_value, "The bitfield slot does not have enough bits to represent the value %. It can maximally represent %.", value, max_value);
    }

    bitfield.* &= cast,no_check(B) (~bit_mask);
    bitfield.* |= cast,no_check(B) ((value << bit_offset) & bit_mask);
}

bitfield_get :: (bitfield: $B, flag: B, $loc := #caller_location, $call := #caller_code) -> s64 {
    bit_mask, bit_offset := #run calculate_mask_and_offset(B, loc, call);

    value := cast(u64) bitfield;
    value &= cast(u64) bit_mask;
    value >>= cast(u64) bit_offset;
    return cast(s64) value;
}

#scope_module

#import "Compiler";
#import "Basic";

calculate_mask_and_offset :: (bitfield: Type, loc: Source_Code_Location, call: Code) -> int, int {
    ti := cast(*Type_Info_Enum) bitfield;
    validate_bitfield(ti, loc);

    bit_offset: int;

    nodes := compiler_get_nodes(call);
    procedure_call := cast(*Code_Procedure_Call) nodes;
    expression := procedure_call.arguments_unsorted[1].expression;

    // This procedure should have been called with either an unary or a binary enum dereference as the second argument.
    operator_type: Operator_Type.loose;

    if expression.kind == {
      case .UNARY_OPERATOR;
        unary := cast(*Code_Unary_Operator) expression;
        operator_type = unary.operator_type;
        expression = unary.subexpression;

      case .BINARY_OPERATOR;
        binary := cast(*Code_Binary_Operator) expression;
        operator_type = binary.operator_type;
        expression = binary.left;

      case .IDENT;
        operator_type = #char ".";
    }

    if operator_type != #char "." || expression.kind != .IDENT {
        error := tprint("Here, please pass a single field from the bitfield \"%\"", ti.name);
        compiler_report(error, make_location(expression));
    }

    ident := cast(*Code_Ident) expression;
    field_name := ident.name;

    bit_count: int;
    found: bool;

    for ti.names {
        if it == field_name {
            bit_count = ti.values[it_index];
            found = true;
            break;
        }

        bit_offset += ti.values[it_index] % 0x100;
    }

    if !found {
        error := tprint("The name \"%\" is not a field of the bitfield \"%\". (You can't use variables as the second argument to bitfield_set.)", field_name, ti.name);
        compiler_report(error, make_location(expression));
    }

    bit_mask: int = 1;
    for 1..bit_count bit_mask *= 2;
    bit_mask -= 1;

    bit_mask <<= bit_offset;
    return bit_mask, bit_offset;
}

validate_bitfield :: (bitfield: *Type_Info, loc: Source_Code_Location) {
    if bitfield.type != .ENUM {
        compiler_report("Argument to bitfield_set is not an enum.", loc);
        return;
    }

    ti := cast(*Type_Info_Enum) bitfield;

    total_width: int;

    for ti.values {
        total_width += it;
    }

    expected_width := bitfield.runtime_size*8;

    if total_width != expected_width {
        error_message := tprint("Bitfield \"%\" values do not sum to the width of its integer type. The total width was %, expected %", ti.name, total_width, expected_width);
        compiler_report(error_message, loc);
    }
}
