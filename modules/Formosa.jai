
// This is the formosa system API, kind of like #include "windows.h"

#scope_export

Syscall_Numbers :: enum {
    NONE             :: 0x00;
    MAP_MEMORY       :: 0x01;
    UNMAP_MEMORY     :: 0x02;
    WRITE_STRING     :: 0x03;
    READ_FILE        :: 0x04;
    WRITE_FILE       :: 0x05;
    CREATE_FILE      :: 0x06;
    STAT_FILE        :: 0x07;
    GET_MESSAGE      :: 0x08;
    CREATE_WINDOW    :: 0x09;
    CLOSE_WINDOW     :: 0x0a;
    REPAINT          :: 0x0b;
    GET_THEME        :: 0x0c;
    SET_THEME        :: 0x0d;
    INPUT            :: 0x0e;
    OUTPUT           :: 0x0f;
    READ_STRING      :: 0x10;
    LIST_DIRECTORY   :: 0x11;
    GET_TIME         :: 0x12;
    GET_SYSTEM_PARAMETERS :: 0x13;
    WAIT_FOR_MESSAGE :: 0x14;
    GET_DEVICE_LIST  :: 0x15;
    GET_SPACE_NEEDED_FOR_DEVICE_LIST :: 0x16;
    YIELD :: 0x17;
    QWERTYUIOP_RUN_COMMAND :: 0x18;
    GET_WINDOW_BUFFER :: 0x19;
}

qwertyuiop_run_command :: (command: string) {
    using Syscall_Numbers;

    count := command.count;
    data := command.data;
    #asm {
        mov rbx: gpr === b, data;
        mov rcx: gpr === c, count;
        mov rax: gpr === a, QWERTYUIOP_RUN_COMMAND;

        int 0x80;
    }
}

System_Params :: struct {
    x_resolution: int;
    y_resolution: int;

    physical_memory: int;
    used_physical_memory: int;
}

get_system_parameters :: (params: *System_Params) {
    using Syscall_Numbers;

    #asm {
        mov rbx: gpr === b, params;
        mov rax: gpr === a, GET_SYSTEM_PARAMETERS;

        int 0x80;
    }
}

formosa_get_time :: () -> Apollo {
    using Syscall_Numbers;

    time: Apollo;
    target := *time;
    #asm {
        mov rbx: gpr === b, target;
        mov rax: gpr === a, GET_TIME;

        int 0x80;
    }
    return time;
}

output :: (value: Any) {
    using Syscall_Numbers;

    value_pointer := value.value_pointer;
    type := value.type;

    #asm {
        mov rbx: gpr === b, value_pointer;
        mov rcx: gpr === c, type;
        mov rax: gpr === a, OUTPUT;

        int 0x80;
    }
}

input :: () -> Any {
    using Syscall_Numbers;

    result: Any;
    target := *result;

    #asm {
        mov rbx: gpr === b, target;
        mov rax: gpr === a, INPUT;

        int 0x80;
    }

    return result;
}

yield :: () {
    using Syscall_Numbers;

    #asm {
        mov rax: gpr === a, YIELD;
        int 0x80;
    }
}

get_theme :: () -> Theme {
    using Syscall_Numbers;

    theme: Theme;
    target := *theme;
    #asm {
        mov rbx: gpr === b, target;
        mov rax: gpr === a, GET_THEME;

        int 0x80;
    }
    return theme;
}

set_theme :: (theme: Theme) {
    using Syscall_Numbers;

    source := *theme;
    #asm {
        mov rbx: gpr === b, source;
        mov rax: gpr === a, SET_THEME;

        int 0x80;
    }
}

read_file :: (name: string) -> [] u8 {
    using Syscall_Numbers;

    p_name := *name;

    result: [] u8;
    target := *result;
    #asm {
        mov rbx: gpr === d, target;
        mov rcx: gpr === c, p_name;
        mov rax: gpr === a, READ_FILE;

        int 0x80;
    }
    return result;
}

write_file :: (name: string, data: [] u8) {
    using Syscall_Numbers;

    _data := *data;
    _name := *name;
    #asm {
        mov rbx: gpr === b, _data;
        mov rcx: gpr === c, _name;
        mov rax: gpr === a, WRITE_FILE;

        int 0x80;
    }
}

create_file :: (name: string) {
    using Syscall_Numbers;

    _name := *name;
    #asm {
        mov rbx: gpr === b, _name;
        mov rax: gpr === a, CREATE_FILE;

        int 0x80;
    }
}

list_directory :: (name: string) -> [] Directory_Entry_Info {
    using Syscall_Numbers;

    result: [] Directory_Entry_Info;
    _name := *name;
    _result := *result;

    #asm {
        mov rbx: gpr === b, _name;
        mov rcx: gpr === c, _result;
        mov rax: gpr === a, LIST_DIRECTORY;

        int 0x80;
    }

    return result;
}


Window_Handle :: s64;
INVALID_WINDOW_HANDLE : Window_Handle : -1;

create_window :: (width: int, height: int) -> Window_Handle {
    using Syscall_Numbers;

    result: Window_Handle;
    target := *result;
    #asm {
        mov rbx: gpr === di, width;
        mov rcx: gpr === c, height;
        mov rdx: gpr === d, target;
        mov rax: gpr === a, CREATE_WINDOW;

        int 0x80;
    }
    return result;
}

close_window :: (window: Window_Handle) {
    using Syscall_Numbers;

    #asm {
        mov rbx: gpr === b, window;
        mov rax: gpr === a, CLOSE_WINDOW;

        int 0x80;
    }
}

get_window_buffer :: (window: Window_Handle) -> *u32 {
    using Syscall_Numbers;

    result: *u32;
    target := *result;
    #asm {
        mov rcx: gpr === c, target;
        mov rbx: gpr === b, window;
        mov rax: gpr === a, GET_WINDOW_BUFFER;

        int 0x80;
    }
    return result;
}

repaint :: () {
    using Syscall_Numbers;

    #asm {
        mov rax: gpr === a, REPAINT;
        int 0x80;
    }
}

write_string :: (text: string) {
    using Syscall_Numbers;

    count := text.count;
    data := text.data;
    #asm {
        mov rbx: gpr === b, data;
        mov rcx: gpr === c, count;
        mov rax: gpr === a, WRITE_STRING;

        int 0x80;
    }
}

read_string :: (prompt: string) -> string {
    using Syscall_Numbers;

    result: string;
    result_count := *result.count;
    result_data := *result.data;

    prompt_count := prompt.count;
    prompt_data := prompt.data;

    #asm {
        mov rbx: gpr === b, prompt_data;
        mov rcx: gpr === c, prompt_count;
        mov rax: gpr === a, READ_STRING;

        int 0x80;

        mov [result_count], rcx;
        mov [result_data],  rbx;
    }

    return result;
}

map_memory :: (size: int) -> *void {
    using Syscall_Numbers;

    buffer: *void;
    target := *buffer;
    #asm {
        mov rbx: gpr === b, target;
        mov rcx: gpr === c, size;
        mov rax: gpr === a, MAP_MEMORY;

        int 0x80;
    }
    return buffer;
}

unmap_memory :: (size_bytes: int, buffer: *void) {
    using Syscall_Numbers;

    #asm {
        mov rbx: gpr === b, size_bytes;
        mov rcx: gpr === c, buffer;
        mov rax: gpr === a, UNMAP_MEMORY;

        int 0x80;
    }
}

get_message :: () -> Message {
    using Syscall_Numbers;

    message: Message;
    target := *message;
    #asm {
        mov rbx: gpr === b, target;
        mov rax: gpr === a, GET_MESSAGE;

        int 0x80;
    }
    return message;
}

wait_for_message :: () -> Message {
    using Syscall_Numbers;

    message: Message;
    target := *message;
    #asm {
        mov rbx: gpr === b, target;
        mov rax: gpr === a, WAIT_FOR_MESSAGE;

        int 0x80;
    }
    return message;
}

get_device_list :: (space: *void) -> [] Hardware_Device {
    using Syscall_Numbers;

    count: int;
    _count := *count;
    #asm {
        mov rcx: gpr === c, _count;
        mov rbx: gpr === b, space;
        mov rax: gpr === a, GET_DEVICE_LIST;

        int 0x80;
    }

    result: [] Hardware_Device;
    result.count = count;
    result.data = cast(*Hardware_Device) space;
    return result;
}

get_space_needed_for_device_list :: () -> int {
    using Syscall_Numbers;

    result: int;
    _result := *result;
    #asm {
        mov rbx: gpr === b, _result;
        mov rax: gpr === a, GET_SPACE_NEEDED_FOR_DEVICE_LIST;

        int 0x80;
    }

    return result;
}

Message :: struct {
    kind: Message_Kind;
    using data: union {
        keyboard_scan_code: Keyboard_Scan_Code;
        key: Keyboard_Scan_Code;
        mouse_event: Mouse_Event;
    };
}

Message_Kind :: enum {
    NONE;
    EXIT;
    KEYBOARD;
    MOUSE;
    // THEME_CHANGED;
}

Theme :: struct {
    background:  u32; @hex
    foreground:  u32; @hex
    primary:     u32; @hex
    secondary:   u32; @hex
    highlight:   u32; @hex
    accent:      u32; @hex

    shadow: float;

#place background;
    array: [6] u32;
}

Apollo :: struct {
    low:  u64;
    high: s64;
}

File_Information :: struct {
    size_bytes: int;

    creation_date: Apollo;
    modification_date: Apollo;
}

Directory_Entry_Info :: struct {
    name: string;

    created: Apollo; @Formosa.apollo
    modified: Apollo; @Formosa.apollo
    type: enum int { dir; file; }
    size: int; @Formosa.base16
}

Rich_Text :: struct {
    text: string;
    attributes: [] Attribute;

    Attribute :: struct {
        start_position: int;
        color: u32;
    }
}

Acpi_Device :: struct {
    table_header: struct {
        signature: [4] u8;
        length: u32;
        revision: u8;
        checksum: u8;
        oem_id: [6] u8;
        oem_table_id: [8] u8;
        oem_revision: u32;
        creator_id: u32;
        creator_revision: u32;
    };
}

Pci_Device :: struct {
    header: struct {
        vendor_id:       u16;
        device_id:       u16;
        status:          u16;
        command:         u16;
        revision_id:     u8;
        prog_if:         u8;
        subclass:        u8;
        class_code:      u8;
        cache_line_size: u8;
        latency_timer:   u8;
        header_type:     u8;
        bist:            u8;
    };

    address: struct {
        bus: u32;
        index: u32;
        function: u32;
    };
}

Hardware_Device :: struct {
    type: enum int {
        ACPI;
        PCI;
    };

    using data: union {
        acpi: Acpi_Device;
        pci: Pci_Device;
    };
}

Keyboard_Scan_Code :: enum u16 {
    NONE;
    ESC;
    NUM1;
    NUM2;
    NUM3;
    NUM4;
    NUM5;
    NUM6;
    NUM7;
    NUM8;
    NUM9;
    NUM0;
    DASH;
    EQUAL;
    BACKSPACE;
    TAB;
    Q;
    W;
    E;
    R;
    T;
    Y;
    U;
    I;
    O;
    P;
    OPEN_BRACKET;
    CLOSED_BRACKET;
    ENTER;
    CTRL;
    A;
    S;
    D;
    F;
    G;
    H;
    J;
    K;
    L;
    SEMICOLON;
    APOSTROPHE;
    BACKTICK;
    LSHIFT;
    BACKSLASH;
    Z;
    X;
    C;
    V;
    B;
    N;
    M;
    COMMA;
    PERIOD;
    FORWARDSLASH;
    RSHIFT;
    ASTERISK;
    ALT;
    SPACE;
    CAPSLOCK;
    F1;
    F2;
    F3;
    F4;
    F5;
    F6;
    F7;
    F8;
    F9;
    F10;
    NUMLOCK;
    SCROLLLOCK;
    KEYPAD7;
    KEYPAD8;
    KEYPAD9;
    KEYPAD_MINUS;
    KEYPAD4;
    KEYPAD5;
    KEYPAD6;
    KEYPAD_PLUS;
    KEYPAD1;
    KEYPAD2;
    KEYPAD3;
    KEYPAD0;
    KEYPAD_PERIOD;

    F11 :: 0x57;
    F12;


    E0_PREFIX_OFFSET :: 0xe0;
    MM_PREV_TRACK   :: E0_PREFIX_OFFSET + 0x10;
    MM_NEXT_TRACK   :: E0_PREFIX_OFFSET + 0x19;
    KEYPAD_ENTER    :: E0_PREFIX_OFFSET + 0x1c;
    RCONTROL;
    MM_MUTE         :: E0_PREFIX_OFFSET + 0x20;
    MM_CALC;
    MM_PLAY;
    MM_STOP;
    MM_VOL_DOWN     :: E0_PREFIX_OFFSET + 0x2e;
    MM_VOL_UP       :: E0_PREFIX_OFFSET + 0x30;
    MM_WWW_HOME     :: E0_PREFIX_OFFSET + 0x32;
    MM_FORWARDSLASH :: E0_PREFIX_OFFSET + 0x35;
    MM_ALTGR        :: E0_PREFIX_OFFSET + 0x38;
    HOME            :: E0_PREFIX_OFFSET + 0x47;
    CURSOR_UP;
    PAGE_UP;
    CURSOR_LEFT     :: E0_PREFIX_OFFSET + 0x4b;
    CURSOR_RIGHT    :: E0_PREFIX_OFFSET + 0x4d;
    CURSOR_END      :: E0_PREFIX_OFFSET + 0x4f;
    CURSOR_DOWN;
    PAGE_DOWN;
    INSERT;
    DELETE;
}

Mouse_Event :: enum {
    NONE;
    BUTTON_1_PRESSED;
    BUTTON_1_RELEASED;
    BUTTON_2_PRESSED;
    BUTTON_2_RELEASED;
}


#scope_module

crt_memset :: (target: *u8, value: s32, count: u64) -> *void #c_call {
    #asm {
        cld;

        count  === c;
        target === di;
        value  === a;
        rep_stos.b target, value, count;
    }

    return target;
}

crt_memcpy :: (dst: *void, src: *void, count: u64) -> *void #c_call {
    #asm {
        cld;

        src   === si;
        dst   === di;
        count === c;
        rep_movs.b dst, src, count;
    }

    return dst;
}

crt_memcmp :: (a: *u8, b: *u8, count: u64) -> s32 #c_call {
    for 0..(cast(s64) count)-1 {
        if a[it] != b[it] {
            return a[it] - b[it];
        }
    }
    return 0;
}
