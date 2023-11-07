
acpi_parse_definition_block :: (bytecode: [] u8) {
    HexMode();
    LongForm();
    context.print_style.default_format_struct.draw_type_name = true;

    context.acpi_parser.start_address = bytecode.data;
    context.acpi_parser.bytecode = bytecode;

    // dump();
    // return;

    allocate :: () {

    }

    while context.acpi_parser.bytecode.count > 0 {
        term_obj := parse_term_object();
        print_term_object(term_obj);
    }
}

#scope_file

#add_context acpi_parser: struct {
    start_address: *u8;
    bytecode: [] u8;

    namespace_root: *Term_Object;
}

dump :: () {
    HexMode();
    context.print_style.default_format_int.minimum_digits = 2;

    using context.acpi_parser;

    printf("Starting dump at byte 0x% (0x% left)\n", bytecode.data - start_address, bytecode.count);

    for 0..99 {
        byte := bytecode[it];
        if byte == 0x8 {
            printf("0x% ", byte, color = theme.highlight);
        } else {
            printf("0x% ", byte);
        }
        if !((it+1) % 10) printf("\n");
    }
    printf("\n");
}

print_term_object :: (term_obj: *Term_Object) {
    item: Any;
    item.type = cast(*Type_Info) term_obj.type;
    item.value_pointer = term_obj;

    builder: String_Builder;
    print_item_to_builder(*builder, item, false);
    result := builder_to_string(*builder);
    free_buffers(*builder);

    printf("%\n", result);

    children := get_children(term_obj);
    for children print_term_object(it);
}

Term_Object :: struct {
    type: Type;
    name: Name_String;
    parent: *Term_Object;
}

Field :: struct {
    using #as base: Term_Object;
    type = #this;

    flags: u8;
    elements: [] Element;

    Element :: struct {
        name: string;
        length: int;
    }
}

Index_Field :: struct {
    using #as base: Term_Object;
    type = #this;

    name_b: Name_String;
    flags: u8;
    elements: [] Field.Element;
}

Scope :: struct {
    using #as base: Term_Object;
    type = #this;

    term_list: [] *Term_Object;
}

Device :: struct {
    using #as base: Term_Object;
    type = #this;

    term_list: [] *Term_Object;
}

Method :: struct {
    using #as base: Term_Object;
    type = #this;

    term_list: [] *Term_Object;
    flags: u8;
}

Name :: struct {
    using #as base: Term_Object;
    type = #this;

    value: Term_Arg;
}

Package :: struct {
    using #as base: Term_Object;
    num_elements: int;
}

Op_Region :: struct {
    using #as base: Term_Object;
    type = #this;

    address_space: Address_Space;
    offset: Term_Arg;
    length: Term_Arg;

    Address_Space :: enum u8 {
        SystemMemory     :: 0x00;
        SystemIO         :: 0x01;
        PCI_Config       :: 0x02;
        EmbeddedControl  :: 0x03;
        SMBus            :: 0x04;
        System_CMOS      :: 0x05;
        PciBarTarget     :: 0x06;
        IPMI             :: 0x07;
        GeneralPurposeIO :: 0x08;
        GenericSerialBus :: 0x09;
        PCC              :: 0x0a;
    }
}

get_children :: (term_obj: *Term_Object) -> [] *Term_Object {
    if term_obj.type == {
        case Scope;  return (cast(*Scope) term_obj).term_list;
        case Device; return (cast(*Device) term_obj).term_list;
        case Method; return (cast(*Method) term_obj).term_list;
        case; return .[];
    }
}



peek :: () -> u8 {
    using context.acpi_parser;
    assert(bytecode.count > 0);
    return bytecode[0];
}

consume :: ($ type: Type) -> type {
    using context.acpi_parser;

    size := size_of(type);

    assert(bytecode.count > size);

    result := << cast(*type) bytecode.data;

    bytecode.count -= size;
    bytecode.data += size;

    return result;
}

consume_string :: (count: int = 4) -> string {
    using context.acpi_parser;

    result: string;
    result.data = bytecode.data;
    result.count = count;

    bytecode.data += count;
    bytecode.count -= count;

    return result;
}

parse_term_object :: () -> *Term_Object {
    ExtOpPrefix :: 0x5b;

    opcode := consume(u8);

    if opcode == ExtOpPrefix {
        opcode = consume(u8);

        if opcode == {
          case 0x80;
            return parse_op_region();
          case 0x81;
            return parse_field();
          case 0x82;
            return parse_device();
          case 0x86;
            return parse_index_field();
          case;
            dump();
            assert(false, tprint("Prefixed opcode not supported: 0x5b 0x%", opcode));
        }
    }

    else if opcode == {
      case 0x8;
        return parse_name();
      case 0x10;
        return parse_scope();
      case 0x12;
        return parse_package();
      case 0x14;
        return parse_method();
      case 0x8b;
        Create_Word_Field :: #type,distinct void;

        parse_create_word_field();
        return null;
        // CreateWordFieldOp
      case;
        dump();
        assert(false, tprint("Term object not supported: 0x%", opcode));
    }

    return null;
}

parse_scope :: () -> *Scope {
    using context.acpi_parser;

    start_offset := bytecode.data;

    package_length := parse_package_length();

    scope := New(Scope);
    scope.name = parse_name_string();

    end_offset := bytecode.data;

    scope_body_size_bytes := package_length - (end_offset - start_offset);
    scope.term_list = parse_term_list(scope_body_size_bytes, scope);

    return scope;
}

parse_device :: () -> *Device {
    using context.acpi_parser;

    start_offset := bytecode.data;

    package_length := parse_package_length();

    device := New(Device);
    device.name = parse_name_string();

    end_offset := bytecode.data;

    device_body_size_bytes := package_length - (end_offset - start_offset);
    device.term_list = parse_term_list(device_body_size_bytes, device);

    return device;
}

parse_package :: () -> *Package {
    using context.acpi_parser;

    start_offset := bytecode.data;
    package_length, bytes_used := parse_package_length();

    package := New(Package);
    package.num_elements = cast(int) consume(u8);

    end_offset := bytecode.data;
    method_body_size_bytes := package_length - (end_offset - start_offset);

    // Skip package contents for now
    bytecode.data += method_body_size_bytes;
    bytecode.count -= method_body_size_bytes;

    return package;
}

parse_index_field :: () -> *Index_Field {
    index_field := New(Index_Field);

    start := context.acpi_parser.bytecode.data;
    length := parse_package_length();

    index_field.name = parse_name_string();
    index_field.name_b = parse_name_string();
    index_field.flags = consume(u8);

    elements: [..] Field.Element;
    while true {
        array_add(*elements, parse_field_element());
        if context.acpi_parser.bytecode.data >= start + length break;
    }
    index_field.elements = elements;

    return index_field;
}

parse_op_region :: () -> *Op_Region {
    op_region := New(Op_Region);
    op_region.name = parse_name_string();

    op_region.address_space = consume(Op_Region.Address_Space);
    op_region.offset = parse_term_arg();
    op_region.length = parse_term_arg();
    return op_region;
}

parse_method :: () -> *Method {
    start_offset := context.acpi_parser.bytecode.data;

    package_length, bytes_used := parse_package_length();

    method := New(Method);
    method.name = parse_name_string();
    method.flags = consume(u8);

    end_offset := context.acpi_parser.bytecode.data;

    // Skip method bodies for now
    method_body_size_bytes := package_length - (end_offset - start_offset);
    // printf("Skipping, bytes used: %\n", bytes_used);

    // method.term_list = parse_term_list(method_body_size_bytes, method);
    context.acpi_parser.bytecode.data += method_body_size_bytes;
    context.acpi_parser.bytecode.count -= method_body_size_bytes;

    return method;
}

parse_name :: () -> *Name {
    name := New(Name);
    name.name = parse_name_string();
    name.value = parse_term_arg();
    return name;
}

parse_field :: () -> *Field {
    field := New(Field);

    start := context.acpi_parser.bytecode.data;
    length := parse_package_length();

    field.name = parse_name_string();
    field.flags = consume(u8);

    elements: [..] Field.Element;
    while true {
        array_add(*elements, parse_field_element());
        if context.acpi_parser.bytecode.data >= start + length break;
    }
    field.elements = elements;

    return field;
}

parse_create_word_field :: () {
    parse_term_arg();
    parse_term_arg();
    parse_name_string();
}

Name_String :: struct {
    name_path: string;
    prefix_count: int;
    flags: enum_flags {
        root;
        dual;
        multi;
    };
}

parse_name_string :: () -> Name_String {
    DualNamePrefix :: 0x2e;
    MultiNamePrefix :: 0x2f;

    name_string: Name_String;

    char := peek();
    if char == #char "\\" {
        consume(u8);
        name_string.flags |= .root;
    } else while char == #char "^" {
        consume(u8);
        name_string.prefix_count += 1;
        char = peek();
    }

    if char == {
      case DualNamePrefix;
        consume(u8);
        name_string.name_path = consume_string(8);
        name_string.flags |= .dual;
      case MultiNamePrefix;
        consume(u8);
        seg_count := consume(u8);
        name_string.name_path = consume_string(seg_count * 4);
        name_string.flags |= .multi;
      case 0x0;
        consume(u8);
      case;
        name_string.name_path = consume_string(4);
    }

    return name_string;
}

parse_package_length :: () -> int, bytes_used: int {
    lead_byte := consume(u8);

    count := lead_byte >> 6;

    if count == 0 return lead_byte & 0x3f, 1;

    value: int = lead_byte & 0xf;
    value |= (cast(int) consume(u8)) << 4;

    if count > 1  value |= (cast(int) consume(u8)) << 12;
    if count > 2  value |= (cast(int) consume(u8)) << 20;

    return value, count+1;
}

parse_buffer :: () -> [] u8 {
    parse_package_length();

    buffer_size := parse_term_arg();
    assert(buffer_size.type == .integer);
    result := consume_string(buffer_size._int);
    return xx result;
}

parse_term_list :: (term_list_size_bytes: int, parent: *Term_Object) -> [] *Term_Object {
    start := context.acpi_parser.bytecode.data;
    result: [..] *Term_Object;

    while true {
        if context.acpi_parser.bytecode.data >= start + term_list_size_bytes {
            break;
        }

        object := parse_term_object();
        array_add(*result, object);
    }

    return result;
}

Term_Arg :: struct {
    type: enum {
        none;
        byte;
        integer;
        _string;
        buffer;
        package;
        object_reference;
        data_ref_object;
        computational_data;
    }

    _int: int;
    _string: string;
    buffer: [] u8;
}

parse_term_arg :: () -> Term_Arg, bool {
    BytePrefix :: 0x0a;
    WordPrefix :: 0x0b;
    DWordPrefix :: 0x0c;
    StringPrefix :: 0x0d;

    result: Term_Arg;

    prefix := consume(u8);

    if prefix == {
      case BytePrefix;
        result.type = .integer;
        result._int = consume(u8);

      case WordPrefix;
        result.type = .integer;
        result._int = consume(u16);

      case DWordPrefix;
        result.type = .integer;
        result._int = consume(u32);

      case StringPrefix;
        result.type = ._string;
        result._string.data = context.acpi_parser.bytecode.data;
        while consume(u8) result._string.count += 1;

      case 0x00; #through;
      case 0x01; #through;
      case 0xff;
        result.type = .integer;
        result._int = prefix;

      case 0x11;
        result.type = .buffer;
        result.buffer = parse_buffer();

      case 0x12;
        result.type = .package;
        parse_package();

      case;
        // if {
        //     
        // }

        dump();
        assert(false, tprint("Term arg prefix not supported 0x%", prefix));
    }

    return result, result.type != .none;
}

parse_field_element :: () -> Field.Element {
    ReservedFieldPrefix       :: 0x0;
    AccessFieldPrefix         :: 0x1;
    ConnectFieldPrefix        :: 0x2;
    ExtendedAccessFieldPrefix :: 0x3;

    result: Field.Element;

    prefix := peek();

    if prefix == {
      case ReservedFieldPrefix;
        consume(u8);
        result.length = parse_package_length();

      case AccessFieldPrefix; #through;
      case ConnectFieldPrefix; #through;
      case ExtendedAccessFieldPrefix;
        assert(false, tprint("Field type not supported: %", prefix));

      case;
        result.name = consume_string(4);
        result.length = parse_package_length();
    }

    return result;
}
