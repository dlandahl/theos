
//
// Runtime_Support is less volatile than Preload and contains imports and various biggish code;
// it is considered reasonable that you can mess around with Runtime_Support and ship your own
// version of it.
//

#module_parameters(DEFINE_SYSTEM_ENTRY_POINT: bool, DEFINE_INITIALIZATION: bool, ENABLE_BACKTRACE_ON_CRASH: bool);

#scope_export

OS_IS_UNIX :: OS == .MACOS || OS == .LINUX || OS == .PS5 || OS == .IOS || OS == .ANDROID;

// @Cleanup: __element_duplicate should lose its c_call status, and also be faster...!
__element_duplicate :: (start: *u8, num_elements: s64, size: s64) #c_call #no_aoc {
    cursor := start + size;
    for 1..num_elements-1 {
        memcpy(cursor, start, size);
        cursor += size;
    }
}

write_nonnegative_number :: (n: u64, base := 10, to_standard_error := false) #no_context #no_abc #no_aoc {
    if n == 0 {
        write_string("0", to_standard_error);
        return;
    }

    if base > 16  base = 16;
    if base < 2   base = 2;

    ubase := cast,no_check(u64) base;

    // This is of course a horrible hack.
    // A u64 in base 2 can be up to 64 digits,
    // so we need at least that much space. Add a few more digits for superstition.
    buf: [69] u8;

    starting_cursor : s32 = buf.count;
    cursor := starting_cursor;


    while n {
        cursor -= 1;
        index := n % ubase;
        if index <= 9 {
            buf[cursor] = cast(u8)(index + #char "0");
        } else {
            buf[cursor] = cast(u8)(index - 10 + #char "a");
        }

        n /= ubase;
    }

    s: string = ---;
    s.data  = buf.data + cursor;
    s.count = starting_cursor - cursor;
    write_string(s, to_standard_error);
}

write_number :: (n: s64, base := 10, to_standard_error := false) #no_context #no_aoc {
    if n < 0 {
        write_string("-", to_standard_error);
        n = -n;  // Will overflow if this is the most negative s64.
    }

    write_nonnegative_number(cast,no_check(u64) n, base, to_standard_error = to_standard_error);
}

runtime_support_assertion_failed :: (loc: Source_Code_Location, message: string) -> bool {
    return false;
}

runtime_support_default_logger :: (message: string, data: *void, info: Log_Info) {
}

c_style_strlen :: (str: *u8) -> s64 #no_context {
    p := str;
    while << p  { p += 1; }
    return p - str;
}

to_string :: (c_string: *u8) -> string #no_context {
    if c_string == null return "";

    s: string = ---;
    s.data = c_string;
    s.count = c_style_strlen(c_string);

    return s;
}

// @Incomplete: Pass loc to Runtime_Support versions.
__array_bounds_check_fail :: (index: s64, limit: s64, line_number: s64, filename: *u8) #no_context {
}

__cast_bounds_check_fail :: (pre_value: s64, pre_flags: u32, post_value: s64, post_flags: u32, fatal: u8, line_number: s64, filename: *u8) #no_context {
}

__null_pointer_check_fail :: (index: s64, line_number: s64, filename: *u8) #no_context {
}

__arithmetic_overflow :: (left: s64, right: s64, type_code: u16, line_number: s64, filename: *u8) #no_context #no_aoc {
}

write_string_unsynchronized :: (s: string, to_standard_error := false) #no_context {
    serial_out(s);
}

write_string :: (s: string, to_standard_error := false) #no_context #compiler {

    mutex := *serial_mutex;
    carry: u8;

    while true {
        #asm {
            lock_bts.q [mutex], 0;
            setc carry;
        }

        if !carry break;
        #asm { pause; }
    }

    write_string_unsynchronized(s, to_standard_error);

    #asm { lock_dec.q [mutex]; }
}

write_strings :: (strings: ..string, to_standard_error := false) #no_context #compiler {
    for strings write_string(it, to_standard_error);
}

serial_mutex: u64;

serial_out :: (data: string) #no_context {
    COM1 :: 0x3f8;

    for cast([] u8) data {
        for 1..1_0000 {
            status: u8;
            port := COM1 + 5;

            #asm {
                status === a;
                port   === d;
                in.b status, port;
            }

            if status & 0x20 break;

            #asm { pause; }
        }

        byte := it;
        port := COM1;

        #asm {
            byte === a;
            port === d;
            out.b port, byte;
        }
    }
}

#scope_module

write_loc :: (loc: Source_Code_Location, to_standard_error := false) #no_context {
    write_strings(loc.fully_pathed_filename, ":", to_standard_error = to_standard_error);
    write_number(loc.line_number, to_standard_error = to_standard_error);
    write_string(",", to_standard_error);
    write_number(loc.character_number, to_standard_error = to_standard_error);
}

my_panic :: () #no_context {
    write_string("Panic.\n", to_standard_error = true);
    while true #asm { cli; hlt; }
}

__panic_due_to_runtime_call_of_compile_time_procedure :: (line_number: s64, filename: *u8) #no_context {
}

#if DEFINE_INITIALIZATION {
    // TEMPORARY_STORAGE_SIZE is defined by the compiler based on Build_Options.

    #scope_export
    #program_export
    __jai_runtime_init :: (argc: s32, argv: **u8) -> *Context #c_call {
        return null;
    }

    #program_export
    __jai_runtime_fini :: (_context: *void) #c_call {
    }
}

__instrumentation_first  :: () {
    // These are places to insert code, from a metaprogram, if you want
    // that code to run before main().
}

__instrumentation_second :: () {
}

#scope_module

#if DEFINE_SYSTEM_ENTRY_POINT {
    #program_export "main"
    __system_entry_point :: (argc: s32, argv: **u8) -> s32 #c_call {
        return 0;
    }
}

Default_Allocator :: #import "Default_Allocator";

runtime_support_default_allocator_proc :: Default_Allocator.allocator_proc;

#scope_export

compile_time_debug_break :: () #compiler #no_context;

debug_break :: () #no_context {
    if #compile_time {
        compile_time_debug_break();
    } else {
        // Break into the debugger, or stop the running process.
        #if OS == .PS5 {
            #asm { int 0x41; }
        } else #if CPU == .X64 {
            #asm { int3; }
        } else #if OS == .WASM {
            wasm_debug_break :: () #foreign; // You will need to provide this function as JS code in your WASM environment. :JaiWasm:
            wasm_debug_break();
        } else {
            llvm_trap :: () #intrinsic "llvm.debugtrap"; // @ToDo: This used to be llvm.trap which supposedly doesn’t work on Android. We need to test if "debugtrap" works there or if we need a different implemenation.
            llvm_trap();
        }
    }
}

// one_time_init is exposed because maybe user libraries want to use a similar thing.
one_time_init :: (synch_value: *s32, to_insert: Code) #expand {
    // A routine to run the code in 'to_insert' only once, even if
    // there are multiple threads. synch_value.* should be 0 at startup.

    // The values of synch_value.*:
    // 0 = uninitialized, 1 = in progress init, 2 = initialized.

    // Courtesy of Jeff Roberts.

    while 1 {
        // @Warning: Apparently this read may not work on ARM, we need to look into it.
        // The goal here is just to avoid the overhead of spamming the compare_and_swap.
        if synch_value.* == 2  break;

        old := lock_cmpxchg(synch_value, 0, 1);
        if old == {
          case 0;
            #insert to_insert;

            if lock_cmpxchg(synch_value, 1, 2) != 1  debug_break();  // Should not happen!
          case 1;
            // Maybe some exponential fall offy thing here?
            #if CPU == .X64 {
                for 1..4 #asm { pause; pause; pause; pause; pause; }
            }
            #if CPU == .ARM64 {
                #bytes .[0x3F, 0x20, 0x03, 0xD5]; // YIELD
            }
          case 2;
        }
    }
}

// @Volatile: Context_Base must match internal compiler settings in general.h
// It must exist and be relatively easy to compile (without requiring #run of
// procedures, for example). Context_Base is going to be annoying to edit because
// if you make an error of some kind, even a simple one like an undeclared identifier,
// you won't get a helpful error message.
Context_Base :: struct {
    // @Incomplete: Initialize this to type_of(Context) to make sure it is not null when someone creates a default context!
    // :InitContextInfo
    context_info:  *Type_Info_Struct; // Allow libs or DLLs to see what context we are passing them.

    thread_index   : u32;

    allocator      := default_allocator;

    logger         := runtime_support_default_logger;
    logger_data    :  *void;
    log_source_identifier: u64;      // Arbitrary identifier; settable by the main program.
    log_level      :  Log_Level;     // Settable by the main program to inform anyone who logs.

    temporary_storage: *Temporary_Storage;

    // Currently, for simplicity we don't #if this out right now when _STACK_TRACE is false;
    // initially an implementation detail prevented us from doing this, but now that's gone,
    // but to be conservative we aren't changing this yet (but may later). It is probably
    // convenient to let runtime code be able to check context.stack_trace to see if it is
    // null in some cases, rather than needing all that to be #iffed as well. We will see.
    stack_trace: *Stack_Trace_Node;

    assertion_failed := runtime_support_assertion_failed;
    handling_assertion_failure := false;  // Used to avoid assert() infinite loops. Do not mess with this value.

    program_print_plugin: *void;  // This is a dumb field that will go away when we have a better alternative.

    default_allocator :: Allocator.{runtime_support_default_allocator_proc, null};
}

Temporary_Storage :: struct {  // @Volatile: Must match general.h
    data:     *u8;
    size:     s64;
    current_page_bytes_occupied: s64;
    total_bytes_occupied: s64;
    high_water_mark: s64;
    last_set_mark_location: Source_Code_Location;

    overflow_allocator : Allocator;

    overflow_pages: *Overflow_Page;
    original_data: *u8;  // Data to restore after clearing overflow pages. @Simplify: Maybe could be an Overflow_Page, but maybe we want to be able to assert on overflow_pages==null to ensure performance.
    original_size: s64;

    Overflow_Page :: struct {
        next: *Overflow_Page;
        allocator: Allocator;
        size: s64;
    }
}

set_initial_data :: (ts: *Temporary_Storage, count: s64, data: *u8) #no_context {
    ts.data = data;
    ts.size = count;

    ts.original_data = data;
    ts.original_size = count;
}

#add_context using base: Context_Base;


#scope_module

init_synchronization :: () #no_context {
}

synch_initted: s32 = 0;

