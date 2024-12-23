//
// This file does not get compiled into Default_Allocator; you compile it separately.

// @Note This is a derived from `rpmalloc-1.4.4/test/main.c`,
//       but as this module is drastically cut down from rpmalloc it is
//       no longer directly comparable.

default_allocator :: #import "Default_Allocator"(
    ENABLE_ASSERTS = ENABLE_ASSERTS,
    ENABLE_VALIDATE_ARGS = ENABLE_VALIDATE_ARGS,
);

ENABLE_ASSERTS :: false;
ENABLE_STATISTICS :: false;
ENABLE_VALIDATE_ARGS :: false;

SPEED_TEST : enum { NONE; THIS; LIBC; RPMALLOC; MIMALLOC; }
           : .NONE;

DUMP_STATISTICS :: false;
DUMP_HEAP_STATISTICS :: false;
LOOP :: true;


#import "Basic";
#import "Random";
#import "Thread";

/*
Windows   Threaded  Single-Thread
RPMALLOC     53.8       1.9s
THIS        218.2       9.3s
LIBC        420.4      13.4s
MIMALLOC      N/A       5.9s

Linux     Threaded  Single-Thread
RPMALLOC     45.2       1.9s
LIBC         64.3       4.7s
THIS        135.4       8.4s
MIMALLOC      N/A       5.8s
*/


TEST : enum_flags { FAILS; PASSES; ALL :: 3; }
     : .ALL;

test_run :: () -> s32, float64 {
    test_initialize();
    start_t := get_time();

    #if TEST & .FAILS {
    }

    #if TEST & .PASSES {
        if test_alloc()              return -1, 0; // (a)
        if test_realloc()            return -1, 0; // (b)
        if test_crossthread()        return -1, 0; // (d)
        if test_threaded()           return -1, 0; // (e)
        if test_threadspam()         return -1, 0; // (f)
        if test_first_class_heaps()  return -1, 0; // (h)
    }
    end_t := get_time();

    print("All tests passed\n\n");
    return 0, end_t - start_t;
}


// #define pointer_offset(ptr, ofs) (void*)((char*)(ptr) + (ptrdiff_t)(ofs))
// #define pointer_diff(first, second) (ptrdiff_t)((const char*)(first) - (const char*)(second))
pointer_offset :: (ptr: *$T, ofs: $U) -> *void #expand {
    return cast(*void)(cast(*char)ptr + cast(ptrdiff_t)ofs);
}
pointer_diff :: (first: *$T, second: *$U) -> ptrdiff_t #expand {
    return cast(ptrdiff_t)(cast(*char)first - cast(*char)second);
}


hardware_threads : _size_t;
test_failed : s32;

char :: u8;
ptrdiff_t :: s64;
uintptr_t :: *Thread;

usable_size :: default_allocator.usable_size;

_size_t :: s64;
#add_context test_allocator_data : *void;

#if SPEED_TEST == .NONE || SPEED_TEST == .THIS {
    _rpmalloc_initialize :: () { }
    _rpmalloc_finalize   :: () { }
    _rpmalloc_thread_initialize :: () { }
    _rpmalloc_thread_finalize   :: (_ := false) { }

    _rpfree :: inline (ptr: *void) {
        default_allocator.allocator.proc(.FREE, 0, 0, ptr, context.test_allocator_data);
    }

    _rpmalloc :: inline (size: s64) -> *void {
        return default_allocator.allocator.proc(.ALLOCATE, size, 0, null, context.test_allocator_data);
    }

    _rprealloc :: inline (ptr: *void, size: s64) -> *void {
        return default_allocator.allocator.proc(.RESIZE, size, 0, ptr, context.test_allocator_data);
    }

    default_allocator_heap_alloc :: inline (heap: *void, size: s64) -> *void {
        return default_allocator.allocator.proc(.ALLOCATE, size, 0, null, xx heap);
    }
}
else #if SPEED_TEST == .LIBC {
    _rpmalloc_initialize :: () { }
    _rpmalloc_finalize   :: () { }
    _rpmalloc_thread_initialize :: () { }
    _rpmalloc_thread_finalize   :: (_ := false) { }

    _rpfree :: inline (ptr: *void) {
        context.allocator.proc(.FREE, 0, 0, ptr, context.test_allocator_data);
    }

    _rpmalloc :: inline (size: s64) -> *void {
        return context.allocator.proc(.ALLOCATE, size, 0, null, context.test_allocator_data);
    }

    _rprealloc :: inline (ptr: *void, size: s64) -> *void {
        return context.allocator.proc(.RESIZE, size, 0, ptr, context.test_allocator_data);
    }

    default_allocator_heap_alloc :: inline (heap: *void, size: s64) -> *void {
        return context.allocator.proc(.ALLOCATE, size, 0, null, xx heap);
    }
}
else #if SPEED_TEST == .RPMALLOC {
    rpmalloc :: #import "rpmalloc"(
        ENABLE_STATISTICS = ENABLE_STATISTICS,
        ENABLE_ASSERTS = ENABLE_ASSERTS,
        ENABLE_VALIDATE_ARGS = ENABLE_VALIDATE_ARGS,
        USE_RAW = false,
    );

    _rpmalloc_initialize :: () {
        rpmalloc.rpmalloc_allocator_proc(.STARTUP, 0, 0, null, context.test_allocator_data);
    }

    _rpmalloc_finalize   :: () {
        _rpmalloc_thread_finalize();
        rpmalloc.rpmalloc_allocator_proc(.SHUTDOWN, 0, 0, null, context.test_allocator_data);
    }

    _rpmalloc_thread_initialize :: () {
        rpmalloc.rpmalloc_allocator_proc(.THREAD_START, 0, 0, null, context.test_allocator_data);
    }

    _rpmalloc_thread_finalize   :: (_ := false) {
        rpmalloc.rpmalloc_allocator_proc(.THREAD_STOP, 0, 0, null, context.test_allocator_data);
    }

    _rpfree :: inline (ptr: *void) {
        rpmalloc.rpmalloc_allocator_proc(.FREE, 0, 0, ptr, context.test_allocator_data);
    }

    _rpmalloc :: inline (size: s64) -> *void {
        return rpmalloc.rpmalloc_allocator_proc(.ALLOCATE, size, 0, null, context.test_allocator_data);
    }

    _rprealloc :: inline (ptr: *void, size: s64) -> *void {
        return rpmalloc.rpmalloc_allocator_proc(.RESIZE, size, 0, ptr, context.test_allocator_data);
    }

    default_allocator_heap_alloc :: inline (heap: *void, size: s64) -> *void {
        return rpmalloc.rpmalloc_allocator_proc(.ALLOCATE, size, 0, null, xx heap);
    }
}
else #if SPEED_TEST == .MIMALLOC {
    #import "mimalloc"(
        //ENABLE_ASSERT = .EXPENSIVE
    );

    _rpmalloc_initialize :: () { }
    _rpmalloc_finalize   :: () { }
    _rpmalloc_thread_initialize :: () {
        //mi_thread_init();
     }
    _rpmalloc_thread_finalize   :: (_ := false) { }

    _rpfree :: inline (ptr: *void) {
        mi_allocator_proc(.FREE, 0, 0, ptr, context.test_allocator_data);
    }

    _rpmalloc :: inline (size: s64) -> *void {
        return mi_allocator_proc(.ALLOCATE, size, 0, null, context.test_allocator_data);
    }

    _rprealloc :: inline (ptr: *void, size: s64) -> *void {
        return mi_allocator_proc(.RESIZE, size, 0, ptr, context.test_allocator_data);
    }

    default_allocator_heap_alloc :: inline (heap: *void, size: s64) -> *void {
        return mi_allocator_proc(.ALLOCATE, size, 0, null, xx heap);
    }
}

test_fail_cb :: (reason: string, file: string, line: s32) -> s32 {
    print("FAIL: % @ %:%\n", reason, file, line);
    test_failed = 1;
    return -1;
}

test_fail :: (msg: string, loc := #caller_location) -> s32 #expand {
    return test_fail_cb(msg, loc.fully_pathed_filename, xx loc.line_number);
}

defer_free_thread :: (thread: *Thread) -> s64 {
    thread_data : *thread_data_t = thread.data;
    _rpfree(thread_data.arg);
    thread_exit(0);
    return 0;
}

test_alloc :: () -> s32 {
    if SPEED_TEST != .NONE  return 0;

    iloop : u32 = 0;
    ipass : u32 = 0;
    icheck : u32 = 0;
    id : u32 = 0;
    addr : [8142]*void;
    data : [20000]u8;
    datasize := u32.[473, 39, 195, 24, 73, 376, 245];
    wanted_usable_size : _size_t;

    _rpmalloc_initialize();

    //Query the small granularity
    zero_alloc : *void = _rpmalloc(0);
    small_granularity : _size_t = usable_size(zero_alloc);
    _rpfree(zero_alloc);

    // for (id = 0; id < 20000; ++id)
    for id: 0 .. 19999
        data[id] = xx (id % 139 + id % 17);

    //Verify that blocks are 16 byte size aligned
    testptr : *void = _rpmalloc(16);
    if (usable_size(testptr) != 16)
        return test_fail("Bad base alloc usable size");
    _rpfree(testptr);
    testptr = _rpmalloc(32);
    if (usable_size(testptr) != 32)
        return test_fail("Bad base alloc usable size");
    _rpfree(testptr);
    testptr = _rpmalloc(128);
    if (usable_size(testptr) != 128)
        return test_fail("Bad base alloc usable size");
    _rpfree(testptr);
    // for (iloop = 0; iloop <= 1024; ++iloop) {
    for iloop: 0 .. cast(_size_t)1024 {
        testptr = _rpmalloc(iloop);
        wanted_usable_size = ifx iloop then small_granularity * ((iloop + (small_granularity - 1)) / small_granularity) else small_granularity;
        if (usable_size(testptr) != wanted_usable_size) {
            print("For % wanted % got %\n", iloop, wanted_usable_size, usable_size(testptr));
            return test_fail("Bad base alloc usable size");
        }
        _rpfree(testptr);
    }

    //Verify medium block sizes (until class merging kicks in)
    // for (iloop = 1025; iloop <= 6000; ++iloop) {
    for iloop: 1025 .. cast(_size_t)6000 {
        testptr = _rpmalloc(iloop);
        wanted_usable_size = 512 * ((iloop / 512) + xx (ifx (iloop % 512) then 1 else 0));
        if (usable_size(testptr) != wanted_usable_size)
            return test_fail("Bad medium alloc usable size");
        _rpfree(testptr);
    }

    //Large reallocation test
    testptr = _rpmalloc(253000);
    testptr = _rprealloc(testptr, 151);
    wanted_usable_size = (small_granularity * ((151 + (small_granularity - 1)) / small_granularity));
    if (usable_size(testptr) != wanted_usable_size)
        return test_fail("Bad usable size");
    if (usable_size(pointer_offset(testptr, 16)) != (wanted_usable_size - 16))
        return test_fail("Bad offset usable size");
    _rpfree(testptr);

    //Reallocation tests
    // for (iloop = 1; iloop < 24; ++iloop) {
    for iloop: 1 .. cast(_size_t)23 {
        size : _size_t = 37 * iloop;
        testptr = _rpmalloc(size);
        <<(cast(*u64)testptr) = 0x12345678;
        wanted_usable_size = small_granularity * ((size / small_granularity) + xx (ifx (size % small_granularity) then 1 else 0));
        if (usable_size(testptr) != wanted_usable_size)
            return test_fail("Bad usable size (alloc)");
        testptr = _rprealloc(testptr, size + 16);
        if (usable_size(testptr) < (wanted_usable_size + 16))
            return test_fail("Bad usable size (realloc)");
        if (<<(cast(*u64)testptr) != 0x12345678)
            return test_fail("Data not preserved on realloc");
        _rpfree(testptr);
    }

    // for (iloop = 0; iloop < 64; ++iloop) {
    for iloop: 0 .. cast(_size_t)63 {
        // for (ipass = 0; ipass < 8142; ++ipass) {
        for ipass: 0 .. cast(_size_t)8141 {
            addr[ipass] = _rpmalloc(500);
            if (addr[ipass] == null)
                return test_fail("Allocation failed");

            memcpy(addr[ipass], data.data + ipass, 500);

            // for (icheck = 0; icheck < ipass; ++icheck) {
            if ipass > 0  for icheck: 0 .. ipass - 1 {
                if (addr[icheck] == addr[ipass])
                    return test_fail("Bad allocation result");
                if (addr[icheck] < addr[ipass]) {
                    if (pointer_offset(addr[icheck], 500) > addr[ipass])
                        return test_fail("Bad allocation result");
                }
                else if (addr[icheck] > addr[ipass]) {
                    if (pointer_offset(addr[ipass], 500) > addr[icheck])
                        return test_fail("Bad allocation result");
                }
            }
        }

        // for (ipass = 0; ipass < 8142; ++ipass) {
        for ipass: 0 .. cast(_size_t)8141 {
            if (memcmp(addr[ipass], data.data + ipass, 500))
                return test_fail("Data corruption");
        }

        #if DUMP_HEAP_STATISTICS
            print("\nDefault Heap Stats:\n%\n", default_allocator_heap_statistics(default_allocator_heap));

        // for (ipass = 0; ipass < 8142; ++ipass)
        for ipass: 0 .. cast(_size_t)8141
            _rpfree(addr[ipass]);
    }

    // for (iloop = 0; iloop < 64; ++iloop) {
    for iloop: 0 .. cast(_size_t)63 {
        // for (ipass = 0; ipass < 1024; ++ipass) {
        for ipass: 0 .. cast(_size_t)1023 {
            cursize : u32 = datasize[ipass%7] + xx ipass;

            addr[ipass] = _rpmalloc(cursize);
            if (addr[ipass] == null)
                return test_fail("Allocation failed");

            memcpy(addr[ipass], data.data + ipass, cursize);

            // for (icheck = 0; icheck < ipass; ++icheck) {
            if ipass > 0  for icheck: 0 .. ipass - 1 {
                if (addr[icheck] == addr[ipass])
                    return test_fail("Identical pointer returned from allocation");
                if (addr[icheck] < addr[ipass]) {
                    if (pointer_offset(addr[icheck], usable_size(addr[icheck])) > addr[ipass])
                        return test_fail("Invalid pointer inside another block returned from allocation");
                }
                else if (addr[icheck] > addr[ipass]) {
                    if (pointer_offset(addr[ipass], usable_size(addr[ipass])) > addr[icheck])
                        return test_fail("Invalid pointer inside another block returned from allocation");
                }
            }
        }

        // for (ipass = 0; ipass < 1024; ++ipass) {
        for ipass: 0 .. cast(_size_t)1023 {
            cursize : u32 = datasize[ipass%7] + xx ipass;
            if (memcmp(addr[ipass], data.data + ipass, cursize))
                return test_fail("Data corruption");
        }

        // for (ipass = 0; ipass < 1024; ++ipass)
        for ipass: 0 .. cast(_size_t)1023
            _rpfree(addr[ipass]);
    }

    // for (iloop = 0; iloop < 128; ++iloop) {
    for iloop: 0 .. cast(_size_t)127 {
        // for (ipass = 0; ipass < 1024; ++ipass) {
        for ipass: 0 .. cast(_size_t)1023 {
            addr[ipass] = _rpmalloc(500);
            if (addr[ipass] == null)
                return test_fail("Allocation failed");

            memcpy(addr[ipass], data.data + ipass, 500);

            // for (icheck = 0; icheck < ipass; ++icheck) {
            if ipass > 0  for icheck: 0 .. ipass - 1 {
                if (addr[icheck] == addr[ipass])
                    return test_fail("Identical pointer returned from allocation");
                if (addr[icheck] < addr[ipass]) {
                    if (pointer_offset(addr[icheck], 500) > addr[ipass])
                        return test_fail("Invalid pointer inside another block returned from allocation");
                }
                else if (addr[icheck] > addr[ipass]) {
                    if (pointer_offset(addr[ipass], 500) > addr[icheck])
                        return test_fail("Invalid pointer inside another block returned from allocation");
                }
            }
        }

        // for (ipass = 0; ipass < 1024; ++ipass) {
        for ipass: 0 .. cast(_size_t)1023 {
            if (memcmp(addr[ipass], data.data + ipass, 500))
                return test_fail("Data corruption");
        }

        // for (ipass = 0; ipass < 1024; ++ipass)
        for ipass: 0 .. cast(_size_t)1023
            _rpfree(addr[ipass]);
    }

    _rpmalloc_finalize();

    // for (iloop = 0; iloop < 2048; iloop += 16) {
    iloop = 0;
    while iloop < 2048 {
        defer iloop += 16;
        _rpmalloc_initialize();
        addr[0] = _rpmalloc(iloop);
        if (!addr[0])
            return test_fail("Allocation failed");
        _rpfree(addr[0]);
        _rpmalloc_finalize();
    }

    // for (iloop = 2048; iloop < (64 * 1024); iloop += 512) {
    iloop = 2048;
    while iloop < 64 * 1024 {
        defer iloop += 512;
        _rpmalloc_initialize();
        addr[0] = _rpmalloc(iloop);
        if (!addr[0])
            return test_fail("Allocation failed");
        _rpfree(addr[0]);
        _rpmalloc_finalize();
    }

    // for (iloop = (64 * 1024); iloop < (2 * 1024 * 1024); iloop += 4096) {
    iloop = (64 * 1024);
    while iloop < 2 * 1024 * 1024 {
        defer iloop += 4096;
        _rpmalloc_initialize();
        addr[0] = _rpmalloc(iloop);
        if (!addr[0])
            return test_fail("Allocation failed");
        _rpfree(addr[0]);
        _rpmalloc_finalize();
    }

    _rpmalloc_initialize();
    // for (iloop = 0; iloop < (2 * 1024 * 1024); iloop += 16) {
    iloop = 0;
    while iloop < (2 * 1024 * 1024) {
        defer iloop += 16;
        addr[0] = _rpmalloc(iloop);
        if (!addr[0])
            return test_fail("Allocation failed");
        _rpfree(addr[0]);
    }
    _rpmalloc_finalize();

    // Test that a full span with deferred block is finalized properly
    // Also test that a deferred huge span is finalized properly
    _rpmalloc_initialize();
    {
        addr[0] = _rpmalloc(23457);
        //print_statistics();

        thread_data : thread_data_t;
        thread_data.fn = defer_free_thread;
        thread_data.arg = addr[0];
        thread := thread_run(*thread_data);
        thread_sleep(100);
        thread_join(thread);

        addr[0] = _rpmalloc(12345678);

        thread_data.fn = defer_free_thread;
        thread_data.arg = addr[0];
        thread = thread_run(*thread_data);
        thread_sleep(100);
        thread_join(thread);
    }
    _rpmalloc_finalize();

    print("Memory allocation tests passed\n");

    return 0;
}

test_realloc :: () -> s32 {
    random_seed(current_time_monotonic().low);

    _rpmalloc_initialize();

    pointer_count : _size_t = 4096;
    pointers : **void = _rpmalloc(xx (size_of(*void) * pointer_count));
    memset(pointers, 0, xx (size_of(*void) * pointer_count));

    alignments := _size_t.[0, 16, 32, 64, 128];

    // for (_size_t iloop = 0; iloop < 8000; ++iloop) {
    for iloop: 0 .. cast(_size_t)8000 {
        // for (_size_t iptr = 0; iptr < pointer_count; ++iptr) {
        for iptr: 0 .. pointer_count - 1 {
            if (iloop)
                _rpfree(_rprealloc(pointers[iptr], xx (random_get() % 4096)));
            pointers[iptr] = _rpmalloc(xx iloop + iptr);
        }
    }

    // for (_size_t iptr = 0; iptr < pointer_count; ++iptr)
    for iptr: 0 .. pointer_count - 1
        _rpfree(pointers[iptr]);
    _rpfree(pointers);

    bigsize : _size_t = 1024 * 1024;
    bigptr : *void = _rpmalloc(bigsize);
    while (bigsize < 3000000) {
        bigsize += 1;
        bigptr = _rprealloc(bigptr, bigsize);
    }
    _rpfree(bigptr);

    _rpmalloc_finalize();

    print("Memory reallocation tests passed\n");

    return 0;
}



thread_data_t :: struct {
    fn: Thread_Proc;
	arg: *void;
    result: u64;
    done: bool;
}

allocator_thread_arg_t :: struct {
    loops : u32;
    passes : u32;  //max 4096
    datasize : [32]u32;
    num_datasize : u32;  //max 32
    init_fini_each_loop : s32;
    pointers : **void;
    crossthread_pointers : **void;
}


allocator_thread :: (thread: *Thread) -> s64 {
    thread_data : *thread_data_t = thread.data;
    arg : allocator_thread_arg_t = <<cast(*allocator_thread_arg_t)thread_data.arg;
    iloop : u32 = 0;
    ipass : u32 = 0;
    icheck : u32 = 0;
    id : u32 = 0;
    addr : **void;
    data : *u32;
    cursize : u32;
    iwait : u32 = 0;
    ret : s32 = 0;

    arg.init_fini_each_loop = 0;

    _rpmalloc_thread_initialize();

    addr = _rpmalloc(size_of(*void) * arg.passes);
    data = _rpmalloc(512 * 1024);
    // for (id = 0; id < 512 * 1024 / 4; ++id)
    for id: 0 .. cast(u32)512 * 1024 / 4 - 1
        data[id] = id;

    thread_sleep(1);

    if arg.init_fini_each_loop
        _rpmalloc_thread_finalize(true);

    for end: 1 .. 1 {

        // for (iloop = 0; iloop < arg.loops; ++iloop) {
        for iloop: 0 .. arg.loops - 1 {
            if (arg.init_fini_each_loop)
                _rpmalloc_thread_initialize();

            // for (ipass = 0; ipass < arg.passes; ++ipass) {
            for ipass: 0 .. arg.passes - 1 {
                cursize = 4 + arg.datasize[(iloop + ipass + iwait) % arg.num_datasize] + ((iloop + ipass) % 1024);

                addr[ipass] = _rpmalloc(4 + cursize);
                if (addr[ipass] == null) {
                    ret = test_fail("Allocation failed");
                    break end;
                }

                <<cast(*u32)addr[ipass] = cast(u32)cursize;
                memcpy(pointer_offset(addr[ipass], 4), data, cursize);

                // for (icheck = 0; icheck < ipass; ++icheck) {
                if ipass > 0 for icheck: 0 .. ipass - 1 {
                    if (addr[icheck] == addr[ipass]) {
                        ret = test_fail("Identical pointer returned from allocation");
                        break end;
                    }
                    if (addr[icheck] < addr[ipass]) {
                        if (pointer_offset(addr[icheck], <<cast(*u32)addr[icheck] + 4) > addr[ipass]) {
                            ret = test_fail("Invalid pointer inside another block returned from allocation");
                            break end;
                        }
                    }
                    else if (addr[icheck] > addr[ipass]) {
                        if (pointer_offset(addr[ipass], <<cast(*u32)addr[ipass] + 4) > addr[icheck]) {
                            ret = test_fail("Invalid pointer inside another block returned from allocation");
                            break end;
                        }
                    }
                }
            }

            // for (ipass = 0; ipass < arg.passes; ++ipass) {
            for ipass: 0 .. arg.passes - 1 {
                cursize = <<cast(*u32)addr[ipass];

                if (memcmp(pointer_offset(addr[ipass], 4), data, cursize)) {
                    ret = test_fail("Data corrupted");
                    break end;
                }

                _rpfree(addr[ipass]);
            }

            if (arg.init_fini_each_loop)
                _rpmalloc_thread_finalize(true);
        }

        _rpfree(data);
        _rpfree(addr);

        _rpmalloc_thread_finalize(true);

    } // end:

    thread_exit(cast(u64)ret);

    return 0;
}

RPMALLOC_FIRST_CLASS_HEAPS :: true;
#if RPMALLOC_FIRST_CLASS_HEAPS {

    heap_allocator_thread :: (thread: *Thread) -> s64 {
        thread_data : *thread_data_t = thread.data;
        arg : allocator_thread_arg_t = <<cast(*allocator_thread_arg_t)thread_data.arg;
        iloop : u32 = 0;
        ipass : u32 = 0;
        icheck : u32 = 0;
        id : u32 = 0;
        addr : **void;
        data : *u32;
        cursize : u32;
        iwait : u32 = 0;
        ret : s32 = 0;

        outer_heap := default_allocator._heap_acquire();

        addr = default_allocator_heap_alloc(outer_heap, size_of(*void) * arg.passes);
        data = default_allocator_heap_alloc(outer_heap, 512 * 1024);
        // for (id = 0; id < 512 * 1024 / 4; ++id)
        for id: 0 .. cast(u32)512 * 1024 / 4 - 1
            data[id] = id;

        thread_sleep(1);

        for end: 1 .. 1 {

            // for (iloop = 0; iloop < arg.loops; ++iloop) {
            for iloop: 0 .. arg.loops - 1 {
                heap := default_allocator._heap_acquire();

                // for (ipass = 0; ipass < arg.passes; ++ipass) {
                for ipass: 0 .. arg.passes - 1 {
                    cursize = 4 + arg.datasize[(iloop + ipass + iwait) % arg.num_datasize] + ((iloop + ipass) % 1024);

                    addr[ipass] = default_allocator_heap_alloc(heap, 4 + cursize);
                    if (addr[ipass] == null) {
                        ret = test_fail("Allocation failed");
                        break end;
                    }

                    <<cast(*u32)addr[ipass] = cast(u32)cursize;
                    memcpy(pointer_offset(addr[ipass], 4), data, cursize);

                    // for (icheck = 0; icheck < ipass; ++icheck) {
                    if ipass > 0 for icheck: 0 .. ipass - 1 {
                        if (addr[icheck] == addr[ipass]) {
                            ret = test_fail("Identical pointer returned from allocation");
                            break end;
                        }
                        if (addr[icheck] < addr[ipass]) {
                            if (pointer_offset(addr[icheck], <<cast(*u32)addr[icheck] + 4) > addr[ipass]) {
                                ret = test_fail("Invalid pointer inside another block returned from allocation");
                                break end;
                            }
                        }
                        else if (addr[icheck] > addr[ipass]) {
                            if (pointer_offset(addr[ipass], <<cast(*u32)addr[ipass] + 4) > addr[icheck]) {
                                ret = test_fail("Invalid pointer inside another block returned from allocation");
                                break end;
                            }
                        }
                    }
                }

                // for (ipass = 0; ipass < arg.passes; ++ipass) {
                for ipass: 0 .. arg.passes - 1 {
                    cursize = <<cast(*u32)addr[ipass];

                    if (memcmp(pointer_offset(addr[ipass], 4), data, cursize)) {
                        ret = test_fail("Data corrupted");
                        break end;
                    }
                }

                default_allocator.heap_free_all(heap);
                default_allocator._heap_release(heap);
            }

            default_allocator.heap_free_all(outer_heap);
            default_allocator._heap_release(outer_heap);

        } // end:

        thread_exit(cast(u64)ret);

        return 0;
    }

}

crossallocator_thread :: (thread: *Thread) -> s64 {
    thread_data : *thread_data_t = thread.data;
    arg : allocator_thread_arg_t = <<cast(*allocator_thread_arg_t)thread_data.arg;
    iloop : u32 = 0;
    ipass : u32 = 0;
    cursize : u32;
    iextra : u32 = 0;
    ret : s32 = 0;

    _rpmalloc_thread_initialize();

    thread_sleep(10);

    next_crossthread : _size_t = 0;
    end_crossthread : _size_t = arg.loops * arg.passes;

    extra_pointers : **void = _rpmalloc(size_of(*void) * arg.loops * arg.passes);

    for end: 1 .. 1 {
        // for (iloop = 0; iloop < arg.loops; ++iloop) {
        for iloop: 0 .. arg.loops - 1 {
            // for (ipass = 0; ipass < arg.passes; ++ipass) {
            for ipass: 0 .. arg.passes - 1 {
                iarg : _size_t = (iloop + ipass + iextra) % arg.num_datasize;
                iextra += 1;
                cursize = arg.datasize[iarg] + ((iloop + ipass) % 439);
                first_addr : *void = _rpmalloc(cursize);
                if (first_addr == null) {
                    ret = test_fail("Allocation failed");
                    break end;
                }

                iarg = (iloop + ipass + iextra) % arg.num_datasize;
                iextra += 1;
                cursize = arg.datasize[iarg] + ((iloop + ipass) % 71);
                second_addr : *void = _rpmalloc(cursize);
                if (second_addr == null) {
                    ret = test_fail("Allocation failed");
                    break end;
                }

                iarg = (iloop + ipass + iextra) % arg.num_datasize;
                iextra += 1;
                cursize = arg.datasize[iarg] + ((iloop + ipass) % 751);
                third_addr : *void = _rpmalloc(cursize);
                if (third_addr == null) {
                    ret = test_fail("Allocation failed");
                    break end;
                }

                _rpfree(first_addr);

                arg.pointers[iloop * arg.passes + ipass] = second_addr;
                extra_pointers[iloop * arg.passes + ipass] = third_addr;

                while ((next_crossthread < end_crossthread) &&
                        arg.crossthread_pointers[next_crossthread]) {
                    _rpfree(arg.crossthread_pointers[next_crossthread]);
                    arg.crossthread_pointers[next_crossthread] = null;
                    next_crossthread += 1;
                }
            }
        }

        // for (iloop = 0; iloop < arg.loops; ++iloop) {
        for iloop: 0 .. arg.loops - 1 {
            // for (ipass = 0; ipass < arg.passes; ++ipass) {
            for ipass: 0 .. arg.passes - 1 {
                _rpfree(extra_pointers[(iloop * arg.passes) + ipass]);
            }
        }

        _rpfree(extra_pointers);

        while ((next_crossthread < end_crossthread) && !test_failed) {
            if (arg.crossthread_pointers[next_crossthread]) {
                _rpfree(arg.crossthread_pointers[next_crossthread]);
                arg.crossthread_pointers[next_crossthread] = null;
                next_crossthread += 1;
            } else {
                thread_yield();
            }
        }

    } // end:

    _rpmalloc_thread_finalize(true);

    thread_exit(cast(u64)ret);

    return 0;
}


initfini_thread :: (thread: *Thread) -> s64 {
    thread_data : *thread_data_t = thread.data;
    arg : allocator_thread_arg_t = <<cast(*allocator_thread_arg_t)thread_data.arg;
    iloop : u32;
    ipass : u32;
    icheck : u32;
    id : u32 = 0;
    addr : [4096]*u32;
    blocksize : [4096]u32;
    data : [8192]s8;
    cursize : u32;
    max_datasize : u32 = 0;
    this_size : u32;
    check_size : u32;
    ret : s32 = 0;

    // for (id = 0; id < size_of(data); ++id)
    for id: 0 .. data.count - 1
        data[id] = cast,no_check(s8)id;

    thread_yield();

    if (arg.passes >= addr.count)
        arg.passes = addr.count;

    for end: 1 .. 1 {

        // for (iloop = 0; iloop < arg.loops; ++iloop) {
        for iloop: 0 .. arg.loops - 1 {
            _rpmalloc_thread_initialize();

            max_datasize = 0;
            // for (ipass = 0; ipass < arg.passes; ++ipass) {
            for ipass: 0 .. arg.passes - 1 {
                cursize = arg.datasize[(iloop + ipass) % arg.num_datasize] + ((iloop + ipass) % 1024);
                if (cursize > data.count)
                    cursize = data.count;
                if (cursize > max_datasize)
                    max_datasize = cursize;

                addr[ipass] = _rpmalloc(size_of(u32) + cursize);
                if (addr[ipass] == null) {
                    ret = test_fail("Allocation failed");
                    break end;
                }

                blocksize[ipass] = cast(u32)cursize;
                addr[ipass][0] = cast(u32)cursize;
                memcpy(addr[ipass] + 1, data.data, cursize);

                // for (icheck = 0; icheck < ipass; ++icheck) {
                if ipass > 0 for icheck: 0 .. ipass - 1 {
                    this_size = addr[ipass][0];
                    check_size = addr[icheck][0];
                    if (this_size != cursize) {
                        ret = test_fail("Data corrupted in this block (size)");
                        break end;
                    }
                    if (check_size != blocksize[icheck]) {
                        print("For %:% got previous block size % (%) wanted % (%)\n", iloop, ipass, check_size, check_size, blocksize[icheck], blocksize[icheck]);
                        ret = test_fail("Data corrupted in previous block (size)");
                        break end;
                    }
                    if (addr[icheck] == addr[ipass]) {
                        ret = test_fail("Identical pointer returned from allocation");
                        break end;
                    }
                    if (addr[icheck] < addr[ipass]) {
                        if (pointer_offset(addr[icheck], check_size + size_of(u32)) > cast(*void)addr[ipass]) {
                            ret = test_fail("Invalid pointer inside another block returned from allocation");
                            break end;
                        }
                    } else {
                        if (pointer_offset(addr[ipass], this_size + size_of(u32)) > cast(*void)addr[icheck]) {
                            ret = test_fail("Invalid pointer inside another block returned from allocation");
                            break end;
                        }
                    }
                }
            }

            // for (ipass = 0; ipass < arg.passes; ++ipass) {
            for ipass: 0 .. arg.passes - 1 {
                cursize = addr[ipass][0];

                if (cursize != blocksize[ipass]) {
                    print("For %:% got size % (%) wanted % (%)\n", iloop, ipass, cursize, cursize, blocksize[ipass], blocksize[ipass]);
                    ret = test_fail("Data corrupted (size)");
                    break end;
                }
                if (cursize > max_datasize) {
                    print("For %:% got size % (%) >= %\n", iloop, ipass, cursize, cursize, max_datasize);
                    ret = test_fail("Data corrupted (size)");
                    break end;
                }
                if (memcmp(addr[ipass] + 1, data.data, cursize)) {
                    ret = test_fail("Data corrupted");
                    break end;
                }

                _rpfree(addr[ipass]);
            }

            _rpmalloc_thread_finalize(true);
            thread_yield();
        }

    } // end:

    _rpmalloc_thread_finalize(true);
    thread_exit(cast(u64)ret);

    return 0;
}


test_thread_implementation :: () -> s32 {
    thread : [32]*Thread;
    threadres : [32]u64;
    i : u32;
    num_alloc_threads : _size_t;
    arg : allocator_thread_arg_t;

    num_alloc_threads = hardware_threads;
    if (num_alloc_threads < 2)
        num_alloc_threads = 2;
    if (num_alloc_threads > 32)
        num_alloc_threads = 32;

    arg.datasize[0] = 19;
    arg.datasize[1] = 249;
    arg.datasize[2] = 797;
    arg.datasize[3] = 3058;
    arg.datasize[4] = 47892;
    arg.datasize[5] = 173902;
    arg.datasize[6] = 389;
    arg.datasize[7] = 19;
    arg.datasize[8] = 2493;
    arg.datasize[9] = 7979;
    arg.datasize[10] = 3;
    arg.datasize[11] = 79374;
    arg.datasize[12] = 3432;
    arg.datasize[13] = 548;
    arg.datasize[14] = 38934;
    arg.datasize[15] = 234;
    arg.num_datasize = 16;
//#if defined(__LLP64__) || defined(__LP64__) || defined(_WIN64) {
    arg.loops = 100;
    arg.passes = 4000;
//} else {
//    arg.loops = 30;
//    arg.passes = 1000;
//}
    arg.init_fini_each_loop = 0;

    thread_data : [32]thread_data_t;
    // for (i = 0; i < num_alloc_threads; ++i)
    for i: 0 .. num_alloc_threads - 1 {
        thread_data[i].fn = allocator_thread;
        thread_data[i].arg = *arg;
        thread[i] = thread_run(*thread_data[i]);
    }

    thread_sleep(1000);

    // for (i = 0; i < num_alloc_threads; ++i)
    for i: 0 .. num_alloc_threads - 1
        threadres[i] = thread_join(thread[i]);

    _rpmalloc_finalize();

    // for (i = 0; i < num_alloc_threads; ++i) {
    for i: 0 .. num_alloc_threads - 1 {
        if (threadres[i])
            return -1;
    }

    return 0;
}

test_threaded :: () -> s32 {
    _rpmalloc_initialize();

    ret : s32 = test_thread_implementation();

    _rpmalloc_finalize();

    if (ret == 0)
        print("Memory threaded tests passed\n");

    return ret;
}


test_crossthread :: () -> s32 {
    thread : [32]*Thread;
    arg : [32]allocator_thread_arg_t;
    thread_data : [32]thread_data_t;

    _rpmalloc_initialize();

    num_alloc_threads : _size_t = hardware_threads;
    if (num_alloc_threads < 2)
        num_alloc_threads = 2;
    if (num_alloc_threads > 16)
        num_alloc_threads = 16;

    // for (u32 ithread = 0; ithread < num_alloc_threads; ++ithread) {
    for ithread: 0 .. cast(u32)num_alloc_threads - 1 {
        iadd : u32 = (ithread * (16 + ithread) + ithread) % 128;
        //#if defined(__LLP64__) || defined(__LP64__) || defined(_WIN64) {
        arg[ithread].loops = 50;
        arg[ithread].passes = 1024;
        //} else {
        //        arg[ithread].loops = 20;
        //        arg[ithread].passes = 200;
        //}
        arg[ithread].pointers = _rpmalloc(size_of(*void) * arg[ithread].loops * arg[ithread].passes);
        memset(arg[ithread].pointers, 0, size_of(*void) * arg[ithread].loops * arg[ithread].passes);
        arg[ithread].datasize[0] = 19 + iadd;
        arg[ithread].datasize[1] = 249 + iadd;
        arg[ithread].datasize[2] = 797 + iadd;
        arg[ithread].datasize[3] = 3 + iadd;
        arg[ithread].datasize[4] = 7923 + iadd;
        arg[ithread].datasize[5] = 344 + iadd;
        arg[ithread].datasize[6] = 3892 + iadd;
        arg[ithread].datasize[7] = 19 + iadd;
        arg[ithread].datasize[8] = 154 + iadd;
        arg[ithread].datasize[9] = 9723 + iadd;
        arg[ithread].datasize[10] = 15543 + iadd;
        arg[ithread].datasize[11] = 32493 + iadd;
        arg[ithread].datasize[12] = 34 + iadd;
        arg[ithread].datasize[13] = 1894 + iadd;
        arg[ithread].datasize[14] = 193 + iadd;
        arg[ithread].datasize[15] = 2893 + iadd;
        arg[ithread].num_datasize = 16;

        thread_data[ithread].fn = crossallocator_thread;
        thread_data[ithread].arg = *arg[ithread];
    }

    // for (u32 ithread = 0; ithread < num_alloc_threads; ++ithread) {
    for ithread: 0 .. cast(u32)num_alloc_threads - 1 {
        arg[ithread].crossthread_pointers = arg[(ithread + 1) % num_alloc_threads].pointers;
    }

    // for (s32 iloop = 0; iloop < 32; ++iloop) {
    for iloop: 0 .. cast(s32)31 {
        // for (u32 ithread = 0; ithread < num_alloc_threads; ++ithread)
        for ithread: 0 .. cast(u32)num_alloc_threads - 1
            thread[ithread] = thread_run(*thread_data[ithread]);

        thread_sleep(100);

        // for (u32 ithread = 0; ithread < num_alloc_threads; ++ithread) {
        for ithread: 0 .. cast(u32)num_alloc_threads - 1 {
            if (thread_join(thread[ithread]) != 0)
                return -1;
        }
    }

    // for (u32 ithread = 0; ithread < num_alloc_threads; ++ithread)
    for ithread: 0 .. cast(u32)num_alloc_threads - 1
        _rpfree(arg[ithread].pointers);

    print("Memory cross thread free tests passed\n");

    _rpmalloc_finalize();

    return 0;
}


test_threadspam :: () -> s32 {
    thread : [64]*Thread;
    threadres : [64]u64;
    i, j: u32;
    num_passes, num_alloc_threads: _size_t;
    arg : allocator_thread_arg_t;

    _rpmalloc_initialize();

    num_passes = 100;
    num_alloc_threads = hardware_threads;
    if (num_alloc_threads < 2)
        num_alloc_threads = 2;
    //#if defined(__LLP64__) || defined(__LP64__) || defined(_WIN64) {
    if (num_alloc_threads > 32)
        num_alloc_threads = 32;
    //} else {
    //    if (num_alloc_threads > 16)
    //        num_alloc_threads = 16;
    //}

    arg.loops = 500;
    arg.passes = 10;
    arg.datasize[0] = 19;
    arg.datasize[1] = 249;
    arg.datasize[2] = 797;
    arg.datasize[3] = 3;
    arg.datasize[4] = 79;
    arg.datasize[5] = 34;
    arg.datasize[6] = 389;
    arg.num_datasize = 7;

    thread_data : [64]thread_data_t;
    // for (i = 0; i < num_alloc_threads; ++i)
    for i: 0 .. num_alloc_threads - 1 {
        thread_data[i].fn = initfini_thread;
        thread_data[i].arg = *arg;
        thread[i] = thread_run(*thread_data[i]);
    }

    // for (j = 0; j < num_passes; ++j) {
    for j: 0 .. num_passes - 1 {
        thread_sleep(100);

        // for (i = 0; i < num_alloc_threads; ++i)
        for i: 0 .. num_alloc_threads - 1 {
            threadres[i] = thread_join(thread[i]);
            assert(thread_data[i].done);
            if (threadres[i])
                return -1;
            thread[i] = thread_run(*thread_data[i]);
        }
    }

    thread_sleep(1000);

    // for (i = 0; i < num_alloc_threads; ++i)
    for i: 0 .. num_alloc_threads - 1
        threadres[i] = thread_join(thread[i]);

    _rpmalloc_finalize();

    // for (i = 0; i < num_alloc_threads; ++i) {
    for i: 0 .. num_alloc_threads - 1 {
        if (threadres[i])
            return -1;
    }

    print("Memory thread spam tests passed\n");

    return 0;
}

test_first_class_heaps :: () -> s32 {
    if SPEED_TEST != .NONE  return 0;

    #if RPMALLOC_FIRST_CLASS_HEAPS {
        thread : [32]*Thread;
        threadres : [32]u64;
        i : u32;
        num_alloc_threads : _size_t;
        arg  : [32]allocator_thread_arg_t;

        _rpmalloc_initialize();

        num_alloc_threads = hardware_threads * 2;
        if (num_alloc_threads < 2)
            num_alloc_threads = 2;
        if (num_alloc_threads > 16)
            num_alloc_threads = 16;

        thread_data : [32]thread_data_t;

        // for (i = 0; i < num_alloc_threads; ++i) {
        for i: 0 .. num_alloc_threads - 1 {
            arg[i].datasize[0] = 19;
            arg[i].datasize[1] = 249;
            arg[i].datasize[2] = 797;
            arg[i].datasize[3] = 3058;
            arg[i].datasize[4] = 47892;
            arg[i].datasize[5] = 173902;
            arg[i].datasize[6] = 389;
            arg[i].datasize[7] = 19;
            arg[i].datasize[8] = 2493;
            arg[i].datasize[9] = 7979;
            arg[i].datasize[10] = 3;
            arg[i].datasize[11] = 79374;
            arg[i].datasize[12] = 3432;
            arg[i].datasize[13] = 548;
            arg[i].datasize[14] = 38934;
            arg[i].datasize[15] = 234;
            arg[i].num_datasize = 16;
    //#if defined(__LLP64__) || defined(__LP64__) || defined(_WIN64) {
            arg[i].loops = 100;
            arg[i].passes = 4000;
    //} else {
    //        arg[i].loops = 50;
    //        arg[i].passes = 1000;
    //}
            arg[i].init_fini_each_loop = 1;

            thread_data[i].fn = heap_allocator_thread;
            if ((i % 2) != 0)
                thread_data[i].fn = allocator_thread;
            thread_data[i].arg = *arg[i];

            thread[i] = thread_run(*thread_data[i]);
        }

        thread_sleep(1000);

        // for (i = 0; i < num_alloc_threads; ++i)
        for i: 0 .. num_alloc_threads - 1
            threadres[i] = thread_join(thread[i]);

        _rpmalloc_finalize();

        // for (i = 0; i < num_alloc_threads; ++i) {
        for i: 0 .. num_alloc_threads - 1 {
            if (threadres[i])
                return -1;
        }

        print("First class heap tests passed\n");
    }
    else {
        print("First class heap tests not ran as RPMALLOC_FIRST_CLASS_HEAPS is false.\n");
    }
    return 0;
}

got_error : s32;



#assert !DUMP_STATISTICS || ENABLE_STATISTICS  "You must ENABLE statistics to DUMP them!";

main :: () {
    result : s32;
    count := 0;
    duration, total_duration : float64 = 0;
    while true {
        count += 1;
        #if LOOP  print("%\n", count);
        result, duration = test_run();
        total_duration += duration;
        print_statistics(duration, total_duration / count);
        if result || !LOOP break;
    }
    exit(result);
}

print_statistics :: (last_duration: float64, avg_duration: float64) {
    #if ENABLE_STATISTICS && DUMP_STATISTICS {
        builder : String_Builder;
        builder.allocator = temp;
        default_allocator_dump_statistics(*builder);
        print(builder_to_string(*builder, allocator = temp));
        //print("\nGlobal Stats:\n%\n", default_allocator_global_statistics());
    }
    print("Time: %  Avg. Time: %\n", last_duration, avg_duration);
}


#if OS == .WINDOWS {
    #import "Windows";
    kernel32 :: #system_library "kernel32";
    GetExitCodeThread :: (hThread: HANDLE, lpExitCode: *DWORD) -> BOOL #foreign kernel32;

    test_initialize :: () {
        system_info : SYSTEM_INFO;
        GetSystemInfo(*system_info);
        hardware_threads = cast(_size_t)system_info.dwNumberOfProcessors;
    }

} else #if OS == .LINUX {
    #import "POSIX";
    #import "System";
    //#include <sched.h>
    test_initialize :: () {
        //prevmask, testmask: cpu_set_t;
        //CPU_ZERO(*prevmask);
        //CPU_ZERO(*testmask);
        //sched_getaffinity(0, size_of(prevmask), *prevmask);  //Get current mask
        //sched_setaffinity(0, size_of(testmask), *testmask);  //Set zero mask
        //sched_getaffinity(0, size_of(testmask), *testmask);  //Get mask for all CPUs
        //sched_setaffinity(0, size_of(prevmask), *prevmask);  //Reset current mask
        //num : s32 = CPU_COUNT(*testmask);
        //hardware_threads = cast(_size_t)(ifx num > 1 then num else 1);
        hardware_threads = xx get_number_of_processors(.PERFORMANCE_PHYSICAL);
    }

} else {

    test_initialize :: () {
        hardware_threads = 1;
    }

}


// Threading

threads : [128] Thread;
used_threads : [128] *Thread;

get_thread :: () -> *Thread {
    for active_thread, i: used_threads {
        if !active_thread {
            thread := *threads[i];
            Initialize(thread);
            used_threads[i] = thread;
            return thread;
        }
    }
    return null;
}

release_thread :: (thread: *Thread) {
    for active_thread, i: used_threads {
        if active_thread == thread {
            used_threads[i] = null;
            return;
        }
    }
}


thread_run :: (thread_data: *thread_data_t) -> *Thread {
    thread_data.result = 0;
    thread_data.done = false;
    thread := get_thread();
    if !thread_init(thread, thread_data.fn)
        assert(false, "Failed to init thread!");
    thread.data = thread_data;
    thread_start(thread);
    return thread;
}

thread_exit :: (value: u64) #expand {
    `thread_data.result = value;
    `thread_data.done = true;
}


thread_join :: (thread: *Thread) -> u64 {
    thread_data : *thread_data_t = thread.data;
    while !thread_data.done  sleep_milliseconds(1);
    thread_deinit(thread);
    release_thread(thread);
    return thread_data.result;
}

thread_sleep :: sleep_milliseconds;

thread_yield :: () {
    #if OS == .WINDOWS {
	    SleepEx :: (milliseconds: DWORD, alertable: BOOL) -> void #foreign kernel32;
        SleepEx(0, 1);
    }
    else {
	    sched_yield();
    }
}
