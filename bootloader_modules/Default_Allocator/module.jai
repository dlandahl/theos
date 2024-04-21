#module_parameters (
    ENABLE_ASSERTS       := true,  // Enable asserts
    ENABLE_VALIDATE_ARGS := true   // Enable validation of args to public entry points
)();

/*
    This is a stripped-down version of rpmalloc, with its thread cache removed,
    for simplicity. This impacts the performance somewhat (about 25% slower in
    threaded scenarios?) If you want a general heap allocator that performs better
    under this kind of use, you can swap in the full modules/rpmalloc, which is
    about twice as much code (but still smaller and simpler than most other
    malloc implementations).

    For advanced heap use or implementation hints, see how_to/800_allocators.jai.

    Because this code is compiled into everything, and we would like it to be fast
    and also small and understandable, we removed the ENABLE_STATISTICS code since
    it was pretty large, and the statistics most people care about are available
    in a broader, cross-allocator way (because it is overlaid on top of allocators)
    by #importing Basic with MEMORY_DEBUGGER=true or using modules/Codex.
    But if you want the statistics code, we have left it here as a backup,
    in Default_Allocator_with_statistics.jai (the compiler does not load this).
    This code will probably decay very quicly over time, but it is there for your info.

*/

#if OS == .KRAMPOS {

unmap_os :: (address: *void, size: s64, release: s64) {
    
}

mmap_os :: (size: s64, offset: *s64) -> *void {
    return null;
}

get_page_size :: () -> int { return 0x1000; }
}

allocator :: Allocator.{allocator_proc, null};
allocator_default_heap : *Heap;

allocator_proc :: (mode: Allocator_Mode, requested_size: s64, old_size: s64, old_memory: *void, allocator_data: *void) -> *void {
    initialize_if_needed();    // :InitIfNeeded
    heap := ifx allocator_data then xx allocator_data else allocator_default_heap;

    if #complete mode == {
        case .ALLOCATE;
        #if ENABLE_VALIDATE_ARGS  if requested_size >= MAX_ALLOC_SIZE  return null;
        return allocate(heap, requested_size);

        case .RESIZE;
        #if ENABLE_VALIDATE_ARGS  if requested_size >= MAX_ALLOC_SIZE  return null;
        return reallocate(heap, old_memory, requested_size, 0);

        case .FREE;
        deallocate(old_memory);
        return null;

        case .STARTUP;
        // :InitIfNeeded
        // We initialize_if_needed on every entry right now, because
        // compile-time execution does not call .STARTUP (maybe this
        // should get fixed? Dunno).
        // initialize_if_needed();
        return null;

        case .SHUTDOWN;
        allocator_default_heap = null;
        return null;

        case .THREAD_START;
        return null;

        case .THREAD_STOP;
        return null;

        case .CREATE_HEAP;
        return _heap_acquire();

        case .DESTROY_HEAP;
        _heap_release(allocator_data);
        return null;

        case .IS_THIS_YOURS;
        result := is_this_yours(heap, old_memory);
        return cast(*void) cast(s64) result;

        case .CAPS;
        if old_memory { <<cast(*string)old_memory = CAPS_VERSION_STRING; }
        return cast(*void)(Allocator_Caps.HINT_I_AM_A_GENERAL_HEAP_ALLOCATOR|.MULTIPLE_THREADS|.CREATE_HEAP|.FREE|.ACTUALLY_RESIZE|.IS_THIS_YOURS);

        case;
        context.handling_assertion_failure = true;
        context.assertion_failed(#location(), "Invalid or corrupt mode passed to rpmalloc allocator.\n");
        context.handling_assertion_failure = false;
        return null;
    }
}

initialize_if_needed :: inline () -> did_init: bool {
    return _initialize_if_needed(*allocator_default_heap);
}

finalize :: () {
    _finalize();
    allocator_default_heap = null;
}

// This function is only used in the child process after a fork() to make sure we’re not waiting on a lock that we inherited from the parent process.
// It’s not intended to be called in any other situation.
unsafe_reset :: inline () {
    initialized = false;
    allocator_default_heap = null;
    atomic_store(*memory_global_lock, 0);
    atomic_store(*memory_init_lock, 0);
}

#scope_module
CAPS_VERSION_STRING :: "stripped-down rpmalloc 1.4.4 intended as Default_Allocator";

#if ENABLE_ASSERTS {
    assert :: (truth: bool, message: string, location := #caller_location) {
        if truth  return;

        if context.handling_assertion_failure  return;  // Avoid infinite loops.
        context.handling_assertion_failure = true;
        context.assertion_failed(location, message);
        context.handling_assertion_failure = false;
    }
} else {
    assert :: ($truth: Code, message: string) #expand { }
}


#if OS == .WINDOWS {
    kernel32 :: #system_library "kernel32";

    VirtualAlloc :: (lpAddress: *void, dwSize: u64, flAllocationType: u32, flProtect: u32) -> *void #foreign kernel32;
    VirtualFree :: (lpAddress: *void, dwSize: u64, dwFreeType: u32) -> s32 #foreign kernel32;
    GetSystemInfo :: (lpSystemInfo : *SYSTEM_INFO) -> void #foreign kernel32;

    SYSTEM_INFO :: struct {
        _pad0: u32;      dwPageSize : u32;
        _pad1: [8] u32;  dwAllocationGranularity : u32;
        _pad2: u32;
    }
} else #if OS == .LINUX || OS == .MACOS {
    #if OS == .MACOS {
        SYSCALL_BASE :: 0x2000000;
    }

    get_page_size :: () -> s64 {
        return 4096;  // @Incomplete: Query for this in some way that is reasonable and works.
    }

    madvise :: (addr: *void, len: s64, advice: s32) -> s32 {
        result : s32 = ---;
        #if OS == .LINUX {
            SYS_MADVISE :: 28;
        } else #if OS == .MACOS {
            SYS_MADVISE :: SYSCALL_BASE + 75;
        }

        #asm SYSCALL_SYSRET {
            mov.q rcx: gpr === c,  0;
            mov.q r11: gpr === 11, 0;
            mov.q rax: gpr === a,  SYS_MADVISE;
            mov.q rdi: gpr === di, addr;
            mov.q rsi: gpr === si, len;
            mov.d rdx: gpr === d,  advice;
            syscall rcx, r11, rax, rdi, rsi, rdx;
            mov.q result, rax;
        }
        return result;
    }

    munmap :: (addr: *void, len: s64) -> s32 {
        result : s32 = ---;
        #if OS == .LINUX {
            SYS_MUNMAP :: 11;
        } else #if OS == .MACOS {
            SYS_MUNMAP :: SYSCALL_BASE + 73;
        }
        #asm SYSCALL_SYSRET {
            mov.q rcx: gpr === c,  0;
            mov.q r11: gpr === 11, 0;
            mov.q rax: gpr === a,  SYS_MUNMAP;
            mov.q rdi: gpr === di, addr;
            mov.q rsi: gpr === si, len;
            syscall rcx, r11, rax, rdi, rsi;
            mov.d result, rax;
        }
        return result;
    }

    mmap :: (addr: *void, len: s64, prot: s32, flags: s32, fildes: s32, offset: s64) -> *void, error: s64 {
        result : s64 = ---;
        #if OS == .LINUX {
            SYS_MMAP :: 9;
        } else #if OS == .MACOS {
            SYS_MMAP :: SYSCALL_BASE + 197;
        }

        #asm SYSCALL_SYSRET {
            mov.q rcx: gpr === c,  0;
            mov.q r11: gpr === 11, 0;
            mov.q rax: gpr === a,  SYS_MMAP;
            mov.q rdi: gpr === di, addr;
            mov.q rsi: gpr === si, len;
            mov.d rdx: gpr === d,  prot;
            mov.d r10: gpr === 10, flags;
            mov.q r9:  gpr === 9,  offset;
            mov.d r8:  gpr === 8,  fildes;
            syscall rcx, r11, rax, rdi, rsi, rdx, r10, r9, r8;
            mov.q result, rax;
        }
        if -4096 < result && result < 0
            return null, -result;
        else
            return cast(*void)result, 0;
    }
}


///
/// Atomic access abstraction
///

// I am avoiding polymorphism here because it's a little more taxing on the compiler,
// and we want this to load maximally fast. Maybe it doesn't matter in the long term though.
atomic_load  :: inline (src: *s32) -> s32 { return <<src; }
atomic_load  :: inline (src: **void) -> *void { return <<src; }

atomic_store :: inline (dest: *s32, value: s32) {
    #asm { lock_xchg.d value, [dest]; }
}

atomic_store :: inline (dest: **void, value: *void) {
    #asm { lock_xchg.q value, [dest]; }
}

atomic_inc :: inline (dest: *s32) -> s32 {
    return atomic_add(dest, +1);
}

atomic_dec :: inline (dest: *s32) -> s32 {
    return atomic_add(dest, -1);
}

atomic_add :: inline (dest: *s32, value: s32) -> s32 {
    increment := value;
    #asm { lock_xadd.d [dest], value; }
    return value + increment;
}

atomic_exchange :: inline (dest: **void, value: *void) -> *void {
    #asm { lock_xchg.q value, [dest]; }
    return value;
}

atomic_compare_and_swap :: inline (dest: *s32, new: s32, old: s32) -> bool {
    result : bool = ---;
    #asm {
        old === a;
        lock_cmpxchg.d old, [dest], new;
        setz t:; // The extra temporary/move here is to work around a bug in the compiler @AsmRWTracking
        mov result, t;
    }
    return result;
}

atomic_compare_and_swap :: inline (dest: **void, new: *void, old: *void) -> bool {
    result : bool = ---;
    #asm {
        old === a;
        lock_cmpxchg.q old, [dest], new;
        setz t:; // The extra temporary/move here is to work around a bug in the compiler @AsmRWTracking
        mov result, t;
    }
    return result;
}


///
/// Preconfigured limits and sizes:
///

SMALL_GRANULARITY        :: 16;  // Granularity of a small allocation block (must be power of two)
SMALL_GRANULARITY_SHIFT  :: 4;   // Small granularity shift count
SMALL_CLASS_COUNT        :: 65;  // Number of small block size classes
SMALL_SIZE_LIMIT         :: SMALL_GRANULARITY * (SMALL_CLASS_COUNT - 1); // Maximum size of a small block

MEDIUM_GRANULARITY       :: 512;  // Granularity of a medium allocation block
MEDIUM_GRANULARITY_SHIFT :: 9;    // Medium granularity shift count
MEDIUM_CLASS_COUNT       :: 61;   // Number of medium block size classes
SIZE_CLASS_COUNT         :: SMALL_CLASS_COUNT + MEDIUM_CLASS_COUNT; // Total number of small + medium size classes
MEDIUM_SIZE_LIMIT        :: SMALL_SIZE_LIMIT + (MEDIUM_GRANULARITY * MEDIUM_CLASS_COUNT); // Maximum size of a medium block

LARGE_CLASS_COUNT        :: 63;   // Number of large block size classes
LARGE_SIZE_LIMIT         :: (LARGE_CLASS_COUNT * MEMORY_SPAN_SIZE) - SPAN_HEADER_SIZE;   // Maximum size of a large block
SPAN_HEADER_SIZE         :: 128;  // Size of a span header (must be a multiple of SMALL_GRANULARITY and a power of two)

#assert (SMALL_GRANULARITY & (SMALL_GRANULARITY - 1)) == 0  "Small granularity must be power of two";
#assert (SPAN_HEADER_SIZE & (SPAN_HEADER_SIZE - 1)) == 0  "Span header size must be power of two";

#if ENABLE_VALIDATE_ARGS {
    MAX_ALLOC_SIZE :: 0x7fff_ffff_ffff_ffff - MEMORY_SPAN_SIZE; // Maximum allocation size to avoid integer overflow
}


pointer_offset :: (ptr: *$T, ofs: $U) -> *void #expand {
    return cast(*void)(cast(*u8)ptr + cast(s64)ofs);
}

pointer_diff :: (first: *$T, second: *$U) -> s64 #expand {
    return cast(s64)(cast(*u8)first - cast(*u8)second);
}


INVALID_POINTER  :: cast(*void) -1;
SIZE_CLASS_LARGE :: SIZE_CLASS_COUNT;
SIZE_CLASS_HUGE  :: cast,no_check(u32) -1;


///
/// Data types
///

// A span can either represent a single span of memory pages with size declared by span_map_count configuration variable,
// or a set of spans in a continuous region, a super span. Any reference to the term "span" usually refers to both a single
// span or a super span. A super span can further be divided into multiple spans (or this, super spans), where the first
// (super)span is the master and subsequent (super)spans are subspans. The master span keeps track of how many subspans
// that are still alive and mapped in virtual memory, and once all subspans and master have been unmapped the entire
// superspan region is released and unmapped (on Windows for example, the entire superspan range has to be released
// in the same call to release the virtual memory range, but individual subranges can be decommitted individually
// to reduce physical memory use).
Span :: struct {
    free_list : *void;                // Free list
    block_count : u32;                // Total block count of size class
    size_class : u32;                 // Size class
    free_list_limit : u32;            // Index of last block initialized in free list
    used_count : u32;                 // Number of used blocks remaining when in partial state
    free_list_deferred : *void;       // Deferred free list
    list_size : u32;                  // Size of deferred free list, or list of spans when part of a cache list
    block_size : u32;                 // Size of a block

    flags : enum_flags u32 {  // Flags and counters
        MASTER ::          1; // Span is the first (master) span of a split superspan
        SUBSPAN ::         2; // Span is a secondary (sub) span of a split superspan
        ALIGNED_BLOCKS ::  4; // Span has blocks with increased alignment
        UNMAPPED_MASTER :: 8; // An unmapped master span
    };

    span_count : u32;              // Number of spans
    total_spans : u32;             // Total span counter for master spans
    offset_from_master : u32;      // Offset from master span for subspans
    remaining_spans : s32;  // Remaining span counter, for master spans
    align_offset : u32;            // Alignment offset
    heap : *Heap;                // Owning heap
    next : *Span;                // Next span
    prev : *Span;                // Previous span
}

#assert size_of(Span) <= SPAN_HEADER_SIZE  "span size mismatch";


// Control structure for a heap, either a thread heap or a first class heap if enabled
Heap :: struct {
    lock : *void;
    is_orphaned : bool;                               // Has heap been orphaned
    size_class : [SIZE_CLASS_COUNT] Heap_Size_Class;  // Free lists for each size class
    span_free_deferred : *void;                       // List of deferred free spans (single linked list)
    full_span_count : s64;                            // Number of full spans
    span_reserve : *Span;                             // Mapped but unused spans
    span_reserve_master : *Span;                      // Master span for mapped but unused spans
    spans_reserved : u32;                             // Number of mapped but unused spans
    child_count : s32;                                // Child count
    next_heap : *Heap;                                // Next heap in id list
    next_orphan : *Heap;                              // Next heap in orphan list
    id : s32;                                         // Heap ID
    finalize : s32;                                   // Finalization state flag
    master_heap : *Heap;                              // Master heap owning the memory pages

    // Double linked list of fully utilized spans with free blocks for each size class.
    // Previous span pointer in head points to tail span of list.
    full_span : [SIZE_CLASS_COUNT] *Span;
    large_huge_span : *Span;  // Double linked list of large and huge spans allocated by this heap
}


Heap_Size_Class :: struct {
    free_list : *void; // Free list of active span

    // Double linked list of partially used spans with free blocks.
    // Previous span pointer in head points to tail span of list.
    partial_span : *Span;

    cache : *Span; // Early level cache of fully free spans
}


// Size class for defining a block size bucket
Size_Class :: struct {
    block_size : u32;   // Size of blocks in this class
    block_count : u16;  // Number of blocks in each chunk
    class_idx : u16;    // Class index this class is merged with
}

#assert size_of(Size_Class) == 8  "Size class size mismatch";


Global_Statistics :: struct {  // In this version of this code, this is all a dummy and means nothing.
    mapped:          s64;
    mapped_peak:     s64;
    cached:          s64;
    huge_alloc:      s64;
    huge_alloc_peak: s64;
    mapped_total:    s64;
    unmapped_total:  s64;
}

Heap_Statistics :: struct {
    sizecache:        s64;
    spancache:        s64;
}

///
/// Global data
///

HEAP_ARRAY_SIZE :: 47;          // Size of heap hashmap
DEFAULT_SPAN_MAP_COUNT  :: 64;  // Default number of spans to map in call to map more virtual memory (default values yield 4MiB here)

// Default span size (64KiB)
MEMORY_SPAN_SIZE :: 64 * 1024;
MEMORY_SPAN_SIZE_SHIFT :: 16;
MEMORY_SPAN_MASK :: ~(MEMORY_SPAN_SIZE - 1);

initialized : bool;            // Initialized flag
memory_page_size : s64;        // Memory page size
memory_page_size_shift : s64;  // Shift to divide by page size
memory_map_granularity : s64;  // Granularity at which memory pages are mapped by OS

memory_span_map_count : s64;                        // Number of spans to map in each map call
memory_heap_reserve_count : s64;                    // Number of spans to keep reserved in each heap
memory_size_class : [SIZE_CLASS_COUNT] Size_Class;  // Global size classes
memory_heap_id : s32;                               // Heap ID counter

memory_global_reserve : *Span;            // Global reserved spans
memory_global_reserve_count : s64;        // Global reserved count
memory_global_reserve_master : *Span;     // Global reserved master
memory_heaps : [HEAP_ARRAY_SIZE] *Heap;   // All heaps
memory_global_lock : s32;                 // Used to restrict access to mapping memory for huge pages
memory_init_lock : s32;                   // Used to allow automatic initialization
memory_orphan_heaps : *Heap;              // Orphaned heaps

///
/// Low level memory map/unmap
///

// Map more virtual memory
// size is number of bytes to map
// offset receives the offset in bytes from start of mapped region
// returns address to start of mapped region to use
_mmap :: (size: s64, offset: *s64) -> *void {
    assert(!(size % memory_page_size), "Invalid mmap size");
    assert(size >= memory_page_size, "Invalid mmap size");

    // Either size is a heap (a single page) or a (multiple) span - we only need to align spans, and only if larger than map granularity
    padding := ifx size >= MEMORY_SPAN_SIZE && MEMORY_SPAN_SIZE > memory_map_granularity then MEMORY_SPAN_SIZE else 0;
    assert(size >= memory_page_size, "Invalid mmap size");

    address := mmap_os(size + padding, offset);

    if padding {
        final_padding := padding - (cast(s64) address & ~MEMORY_SPAN_MASK);
        assert(final_padding <= MEMORY_SPAN_SIZE, "Internal failure in padding");
        assert(final_padding <= padding,          "Internal failure in padding");
        assert(!(final_padding % 8),              "Internal failure in padding");
        address = pointer_offset(address, final_padding);
        <<offset = final_padding >> 3;
    }
    assert((size < MEMORY_SPAN_SIZE) || !(cast(u64) address & ~MEMORY_SPAN_MASK), "Internal failure in padding");

    return address;
}


// Unmap virtual memory
// address is the memory address to unmap, as returned from memory_map
// size is the number of bytes to unmap, which might be less than full region for a partial unmap
// offset is the offset in bytes to the actual mapped region, as set by memory_map
// release is set to 0 for partial unmap, or size of entire range for a full unmap
unmap :: (address: *void, size: s64, offset: s64, release: s64) {
    assert(!release || (release >= size), "Invalid unmap size");
    assert(!release || (release >= memory_page_size), "Invalid unmap size");
    if release {
        assert(!(release % memory_page_size), "Invalid unmap size");
    }

    assert(release || offset == 0, "Invalid unmap size");
    assert(size >= memory_page_size, "Invalid unmap size");

    adjusted_address := address;
    adjusted_release := release;
    if release && offset {
        adjusted_offset := offset << 3;
        adjusted_address = pointer_offset(address, -cast(s32)adjusted_offset);
        if (release >= MEMORY_SPAN_SIZE) && (MEMORY_SPAN_SIZE > memory_map_granularity)
            adjusted_release += MEMORY_SPAN_SIZE; //Padding is always one span size
    }

    unmap_os(adjusted_address, size, adjusted_release);
}


// Default implementation to map new pages to virtual memory
// Map memory pages for the given number of bytes. The returned address MUST be
// aligned to the rpmalloc span size, which will always be a power of two.
// Optionally the function can store an alignment offset in the offset variable
// in case it performs alignment and the returned pointer is offset from the
// actual start of the memory region due to this alignment. The alignment offset
// will be passed to the memory unmap function. The alignment offset MUST NOT be
// larger than 65535 (storable in an u16), if it is you must use natural
// alignment to shift it into 16 bits. This function must be thread safe, it can be
// called by multiple threads simultaneously.
#if OS == .WINDOWS || OS == .LINUX || OS == .MACOS {
    mmap_os :: (size: s64, offset: *s64) -> *void {
        assert(size >= memory_page_size, "Invalid mmap size");
        #if OS == .WINDOWS {
            // Ok to MEM_COMMIT - according to MSDN, "actual physical pages are not allocated unless/until the virtual addresses are actually accessed"
            MEM_COMMIT ::  0x00001000;
            MEM_RESERVE :: 0x00002000;
            PAGE_READWRITE :: 0x04;
            ptr := VirtualAlloc(null, xx size, MEM_RESERVE | MEM_COMMIT, PAGE_READWRITE);
            if !ptr {
                assert(ptr != null, "Failed to map virtual memory block");
                return null;
            }
        } else {
            PROT_READ  :: 0x01;
            PROT_WRITE :: 0x02;
            prot : s32 : PROT_READ | PROT_WRITE;

            MAP_PRIVATE ::   0x0002;
            #if OS == .LINUX {
                MAP_ANONYMOUS :: 0x0020;
            } else #if OS == .MACOS {
                MAP_ANONYMOUS :: 0x1000;
            }

            flags : s32 : MAP_PRIVATE | MAP_ANONYMOUS;

            #if OS == .MACOS {
                VM_MAKE_TAG :: (val: s32) -> s32 { return val << 24; }
                fd := cast(s32) VM_MAKE_TAG(240);
                ptr, error := mmap(null, xx size, prot, flags, fd, 0);
            } else #if OS == .LINUX {
                ptr, error := mmap(null, xx size, prot, flags, -1, 0);
            } else {
                #assert false "Better implement that new OS!";
            }

            MAP_FAILED :: cast(*void) -1;
            ENOMEM :: 12;
            if ptr == MAP_FAILED || !ptr {
                if error != ENOMEM
                    assert((ptr != MAP_FAILED) && ptr, "Failed to map virtual memory block");
                return null;
            }
        }

        return ptr;
    }
}


// Default implementation to unmap pages from virtual memory
// Unmap the memory pages starting at address and spanning the given number of bytes.
// If release is set to non-zero, the unmap is for an entire span range as returned by
// a previous call to memory_map and that the entire range should be released. The
// release argument holds the size of the entire span range. If release is set to 0,
// the unmap is a partial decommit of a subset of the mapped memory range.
// This function must be thread safe, it can be called by multiple threads simultaneously.
#if OS == .WINDOWS {
    unmap_os :: (address: *void, size: s64, release: s64) {
        MEM_DECOMMIT :: 0x00004000;
        MEM_RELEASE ::  0x00008000;
        release_or_commit := cast(u32) ifx release then MEM_RELEASE else MEM_DECOMMIT;
        if !VirtualFree(address, xx ifx release then 0 else size, release_or_commit) {
            assert(false, "Failed to unmap virtual memory block");
        }
    }
} else #if OS == .LINUX || OS == .MACOS {
    unmap_os :: (address: *void, size: s64, release: s64) {
        if release {
            if munmap(address, xx release)
                assert(false, "Failed to unmap virtual memory block");
        } else {
            MADV_DONTNEED    ::  4;
            err := madvise(address, xx size, MADV_DONTNEED);
            assert(err == 0, "Failed to madvise virtual memory block as free");
        }
    }
}


// Use global reserved spans to fulfill a memory map request (reserve size must be checked by caller)
global_get_reserved_spans :: (span_count: s64) -> *Span {
    span := memory_global_reserve;
    span_mark_as_subspan_unless_master(memory_global_reserve_master, span, span_count);
    memory_global_reserve_count -= span_count;
    if memory_global_reserve_count
        memory_global_reserve = cast(*Span) pointer_offset(span, span_count << MEMORY_SPAN_SIZE_SHIFT);
    else
        memory_global_reserve = null;
    return span;
}


// Store the given spans as global reserve (must only be called from within new heap allocation, not thread safe)
global_set_reserved_spans :: (master: *Span, reserve: *Span, reserve_span_count: s64) {
    memory_global_reserve_master = master;
    memory_global_reserve_count = reserve_span_count;
    memory_global_reserve = reserve;
}


///
/// Span linked list management
///

// Add a span to double linked list at the head
span_double_link_list_add :: (head: **Span, span: *Span) {
    if <<head {
        (<<head).prev = span;
    }
    span.next = <<head;
    <<head = span;
}


// Pop head span from double linked list
span_double_link_list_pop_head :: (head: **Span, span: *Span) {
    assert(<<head == span, "Linked list corrupted");

    span = <<head;
    <<head = span.next;
}


// Remove a span from double linked list
span_double_link_list_remove :: (head: **Span, span: *Span) {
    assert(<<head != null, "Linked list corrupted");

    if <<head == span {
        <<head = span.next;
    } else {
        next_span := span.next;
        prev_span := span.prev;
        prev_span.next = next_span;
        if next_span  next_span.prev = prev_span;
    }
}


///
/// Span control
///

spin :: inline () {
    #asm { pause; }
}


// Declare the span to be a subspan and store distance from master span and span count
span_mark_as_subspan_unless_master :: (master: *Span, subspan: *Span, span_count: s64) {
    assert((subspan != master) || ((subspan.flags & .MASTER) != 0), "Span master pointer and/or flag mismatch");
    if subspan != master {
        subspan.flags = .SUBSPAN;
        subspan.offset_from_master = cast(u32)(cast(u64)pointer_diff(subspan, master) >> MEMORY_SPAN_SIZE_SHIFT);
        subspan.align_offset = 0;
    }
    subspan.span_count = cast(u32)span_count;
}


// Use reserved spans to fulfill a memory map request (reserve size must be checked by caller)
span_map_from_reserve :: (heap: *Heap, span_count: s64) -> *Span {
    //Update the heap span reserve
    span : *Span = heap.span_reserve;
    heap.span_reserve = cast(*Span) pointer_offset(span, span_count * MEMORY_SPAN_SIZE);
    heap.spans_reserved -= cast(u32)span_count;

    span_mark_as_subspan_unless_master(heap.span_reserve_master, span, span_count);

    return span;
}


// Get the aligned number of spans to map in based on wanted count, configured mapping granularity and the page size
span_align_count :: (span_count: s64) -> s64 {
    request_count := ifx span_count > memory_span_map_count then span_count else memory_span_map_count;
    if (memory_page_size > MEMORY_SPAN_SIZE) && ((request_count * MEMORY_SPAN_SIZE) % memory_page_size)
        request_count += memory_span_map_count - (request_count % memory_span_map_count);
    return request_count;
}


// Setup a newly mapped span
span_initialize :: (span: *Span, total_span_count: s64, span_count: s64, align_offset: s64) {
    span.total_spans = cast(u32)total_span_count;
    span.span_count = cast(u32)span_count;
    span.align_offset = cast(u32)align_offset;
    span.flags = .MASTER;
    atomic_store(*span.remaining_spans, cast(s32)total_span_count);
}


// Map an aligned set of spans, taking configured mapping granularity and the page size into account
span_map_aligned_count :: (heap: *Heap, span_count: s64) -> *Span {
    // If we already have some, but not enough, reserved spans, release those to heap cache and map a new
    // full set of spans. Otherwise we would waste memory if page size > span size (huge pages)
    aligned_span_count := span_align_count(span_count);
    align_offset := 0;
    span := cast(*Span) _mmap(aligned_span_count * MEMORY_SPAN_SIZE, *align_offset);
    if !span  return null;

    span_initialize(span, aligned_span_count, span_count, align_offset);

    if aligned_span_count > span_count {
        reserved_spans := cast(*Span) pointer_offset(span, span_count * MEMORY_SPAN_SIZE);
        reserved_count := aligned_span_count - span_count;

        if heap.spans_reserved {
            span_mark_as_subspan_unless_master(heap.span_reserve_master, heap.span_reserve, heap.spans_reserved);
            heap_cache_insert(heap, heap.span_reserve);
        }

        if reserved_count > memory_heap_reserve_count {
            // If huge pages or eager spam map count, the global reserve spin lock is held by caller, span_map
            assert(atomic_load(*memory_global_lock) == 1, "Global spin lock not held as expected");

            remain_count := reserved_count - memory_heap_reserve_count;
            reserved_count = memory_heap_reserve_count;
            remain_span : *Span = pointer_offset(reserved_spans, reserved_count * MEMORY_SPAN_SIZE);

            if memory_global_reserve {
                span_mark_as_subspan_unless_master(memory_global_reserve_master, memory_global_reserve, memory_global_reserve_count);
                span_unmap(memory_global_reserve);
            }

            global_set_reserved_spans(span, remain_span, remain_count);
        }

        heap_set_reserved_spans(heap, span, reserved_spans, reserved_count);
    }

    return span;
}


// Map in memory pages for the given number of spans (or use previously reserved pages)
span_map :: (heap: *Heap, span_count: s64) -> *Span {
    if span_count <= heap.spans_reserved
        return span_map_from_reserve(heap, span_count);

    span : *Span = null;
    use_global_reserve := (memory_page_size > MEMORY_SPAN_SIZE) || (memory_span_map_count > memory_heap_reserve_count);
    if use_global_reserve {
        // If huge pages, make sure only one thread maps more memory to avoid bloat
        while !atomic_compare_and_swap(*memory_global_lock, 1, 0)
            spin();

        if memory_global_reserve_count >= span_count {
            reserve_count := ifx !heap.spans_reserved then memory_heap_reserve_count else span_count;
            if memory_global_reserve_count < reserve_count
                reserve_count = memory_global_reserve_count;

            span = global_get_reserved_spans(reserve_count);
            if span {
                if reserve_count > span_count {
                    reserved_span := cast(*Span) pointer_offset(span, span_count << MEMORY_SPAN_SIZE_SHIFT);
                    heap_set_reserved_spans(heap, memory_global_reserve_master, reserved_span, reserve_count - span_count);
                }

                // Already marked as subspan in global_get_reserved_spans
                span.span_count = cast(u32)span_count;
            }
        }
    }

    if !span  span = span_map_aligned_count(heap, span_count);

    if use_global_reserve
        atomic_store(*memory_global_lock, 0);

    return span;
}


// Unmap memory pages for the given number of spans (or mark as unused if no partial unmappings)
span_unmap :: (span: *Span) {
    assert((span.flags & .MASTER) || (span.flags & .SUBSPAN), "Span flag corrupted");
    assert(!(span.flags & .MASTER) || !(span.flags & .SUBSPAN), "Span flag corrupted");

    is_master := span.flags & .MASTER;
    master := ifx is_master then span else cast(*Span) pointer_offset(span, -(cast(s64)span.offset_from_master * MEMORY_SPAN_SIZE));
    assert(is_master || (span.flags & .SUBSPAN), "Span flag corrupted");
    assert((master.flags & .MASTER) != 0, "Span flag corrupted");

    span_count := span.span_count;
    if !is_master {
        //Directly unmap subspans (unless huge pages, in which case we defer and unmap entire page range with master)
        assert(span.align_offset == 0, "Span align offset corrupted");
        if MEMORY_SPAN_SIZE >= memory_page_size
            unmap(span, span_count * MEMORY_SPAN_SIZE, 0, 0);
    }
    else {
        //Special double flag to denote an unmapped master
        //It must be kept in memory since span header must be used
        span.flags |= type_of(span.flags).MASTER | .SUBSPAN | .UNMAPPED_MASTER;
    }

    if atomic_add(*master.remaining_spans, -cast(s32)span_count) <= 0 {
        //Everything unmapped, unmap the master span with release flag to unmap the entire range of the super span
        assert((master.flags & .MASTER) && (master.flags & .SUBSPAN), "Span flag corrupted");

        unmap_count := master.span_count;
        if MEMORY_SPAN_SIZE < memory_page_size
            unmap_count = master.total_spans;

        unmap(master, unmap_count * MEMORY_SPAN_SIZE, master.align_offset, master.total_spans * MEMORY_SPAN_SIZE);
    }
}


// Move the span (used for small or medium allocations) to the heap thread cache
span_release_to_cache :: (heap: *Heap, span: *Span) {
    assert(heap == span.heap, "Span heap pointer corrupted");
    assert(span.size_class < SIZE_CLASS_COUNT, "Invalid span size class");
    assert(span.span_count == 1, "Invalid span count");

    if !heap.finalize {
        if heap.size_class[span.size_class].cache
            heap_cache_insert(heap, heap.size_class[span.size_class].cache);

        heap.size_class[span.size_class].cache = span;
    }
    else {
        span_unmap(span);
    }
}


// Initialize a (partial) free list up to next system memory page, while reserving the first block
// as allocated, returning number of blocks in list
free_list_partial_init :: (list: **void, first_block: **void, page_start: *void, block_start: *void, block_count: u32, block_size: u32) -> u32 {
    assert(block_count > 0, "Internal failure");

    <<first_block = block_start;
    if block_count > 1 {
        free_block := pointer_offset(block_start, block_size);
        block_end := pointer_offset(block_start, block_size * block_count);
        //If block size is less than half a memory page, bound init to next memory page boundary
        if block_size < (memory_page_size >> 1) {
            page_end := pointer_offset(page_start, memory_page_size);
            if page_end < block_end
                block_end = page_end;
        }
        <<list = free_block;
        block_count = 2;
        next_block := pointer_offset(free_block, block_size);
        while next_block < block_end {
            <<cast(**void)free_block = next_block;
            free_block = next_block;
            block_count += 1;
            next_block = pointer_offset(next_block, block_size);
        }
        <<cast(**void)free_block = null;
    }
    else {
        <<list = null;
    }
    return block_count;
}


// Initialize an unused span (from cache or mapped) to be new active span, putting the initial free list in heap class free list
span_initialize_new :: (heap: *Heap, heap_size_class: *Heap_Size_Class, span: *Span, class_idx: u32) -> *void {
    assert(span.span_count == 1, "Internal failure");

    size_class : *Size_Class = memory_size_class.data + class_idx;
    span.size_class = class_idx;
    span.heap = heap;
    span.flags &= ~.ALIGNED_BLOCKS;
    span.block_size = size_class.block_size;
    span.block_count = size_class.block_count;
    span.free_list = null;
    span.list_size = 0;
    atomic_store(*span.free_list_deferred, null);

    //Setup free list. Only initialize one system page worth of free blocks in list
    block : *void;
    span.free_list_limit = free_list_partial_init(*heap_size_class.free_list,
                                                  *block,
                                                  span,
                                                  pointer_offset(span, SPAN_HEADER_SIZE),
                                                  size_class.block_count,
                                                  size_class.block_size);
    //Link span as partial if there remains blocks to be initialized as free list, or full if fully initialized
    if span.free_list_limit < span.block_count {
        span_double_link_list_add(*heap_size_class.partial_span, span);
        span.used_count = span.free_list_limit;
    }
    else {
        span_double_link_list_add(*heap.full_span[class_idx], span);
        heap.full_span_count += 1;
        span.used_count = span.block_count;
    }

    return block;
}


span_extract_free_list_deferred :: (span: *Span) {
    // We need acquire semantics on the CAS operation since we are interested in the list size
    // Refer to deallocate_defer_small_or_medium for further comments on this dependency
    while true {
        span.free_list = atomic_exchange(*span.free_list_deferred, INVALID_POINTER);
        if span.free_list != INVALID_POINTER  break;
    }
    span.used_count -= span.list_size;
    span.list_size = 0;
    atomic_store(*span.free_list_deferred, null);
}


span_is_fully_utilized :: (span: *Span) -> bool {
    assert(span.free_list_limit <= span.block_count, "Span free list corrupted");
    return !span.free_list && (span.free_list_limit >= span.block_count);
}


span_finalize :: (heap: *Heap, iclass: s64, span: *Span, list_head: **Span) -> unmapped: bool {
    free_list := heap.size_class[iclass].free_list;
    class_span := cast(*Span)(cast(u64)free_list & MEMORY_SPAN_MASK);
    if span == class_span {
        // Adopt the heap class free list back into the span free list
        block := span.free_list;
        last_block : *void = null;
        while block {
            last_block = block;
            block = <<cast(**void)block;
        }

        free_count : u32 = 0;
        block = free_list;
        while block {
            free_count += 1;
            block = <<cast(**void)block;
        }

        if last_block {
            <<cast(**void)last_block = free_list;
        }
        else {
            span.free_list = free_list;
        }

        heap.size_class[iclass].free_list = null;
        span.used_count -= free_count;
    }

    //If this assert triggers you have memory leaks
    assert(span.list_size == span.used_count, "Memory leak detected");
    if span.list_size == span.used_count {
        // This function only used for spans in double linked lists
        if list_head
            span_double_link_list_remove(list_head, span);
        span_unmap(span);
        return true;
    }

    return false;
}


///
/// Heap control
///

// Store the given spans as reserve in the given heap
heap_set_reserved_spans :: (heap: *Heap, master: *Span, reserve: *Span, reserve_span_count: s64) {
    heap.span_reserve_master = master;
    heap.span_reserve = reserve;
    heap.spans_reserved = cast(u32)reserve_span_count;
}


// Adopt the deferred span cache list, optionally extracting the first single span for immediate re-use
heap_cache_adopt_deferred :: (heap: *Heap, single_span: **Span) {
    span := cast(*Span) atomic_exchange(*heap.span_free_deferred, null);
    while span {
        next_span := cast(*Span)span.free_list;
        assert(span.heap == heap, "Span heap pointer corrupted");

        if span.size_class < SIZE_CLASS_COUNT {
            assert(heap.full_span_count > 0, "Heap span counter corrupted");

            heap.full_span_count -= 1;
            span_double_link_list_remove(*heap.full_span[span.size_class], span);

            if single_span && !<<single_span {
                <<single_span = span;
            } else {
                heap_cache_insert(heap, span);
            }
        } else {
            if span.size_class == SIZE_CLASS_HUGE {
                deallocate_huge(span);
            } else {
                assert(span.size_class == SIZE_CLASS_LARGE, "Span size class invalid");
                assert(heap.full_span_count > 0, "Heap span counter corrupted");

                heap.full_span_count -= 1;
                span_double_link_list_remove(*heap.large_huge_span, span);

                idx : u32 = span.span_count - 1;

                if !idx && single_span && !<<single_span {
                    <<single_span = span;
                } else {
                    heap_cache_insert(heap, span);
                }
            }
        }
        span = next_span;
    }
}


heap_unmap :: (heap: *Heap) {
    if !heap.master_heap {
        if (heap.finalize > 1) && !atomic_load(*heap.child_count) {
            span := cast(*Span)(cast(u64)heap & MEMORY_SPAN_MASK);
            span_unmap(span);
        }
    } else {
        if atomic_dec(*heap.master_heap.child_count) == 0 {
            heap_unmap(heap.master_heap);
        }
    }
}


heap_global_finalize :: (heap: *Heap) {
    if heap.finalize > 1  return;
    heap.finalize += 1;

    heap_finalize(heap);

    if heap.full_span_count {
        heap.finalize -= 1;
        return;
    }

    for iclass: 0 .. SIZE_CLASS_COUNT - 1 {
        if heap.size_class[iclass].free_list || heap.size_class[iclass].partial_span {
            heap.finalize -= 1;
            return;
        }
    }

    //Heap is now completely free, unmap and remove from heap list
    list_idx := heap.id % HEAP_ARRAY_SIZE;
    list_heap := memory_heaps[list_idx];
    if list_heap == heap {
        memory_heaps[list_idx] = heap.next_heap;
    } else {
        while list_heap.next_heap != heap
            list_heap = list_heap.next_heap;
        list_heap.next_heap = heap.next_heap;
    }

    heap_unmap(heap);
}


// Insert a single span into thread heap cache, releasing to global cache if overflow
heap_cache_insert :: (heap: *Heap, span: *Span) {
    if heap.finalize != 0 {
        span_unmap(span);
        heap_global_finalize(heap);
        return;
    }

    span_unmap(span);
}


heap_thread_cache_deferred_extract :: (heap: *Heap, span_count: s64) -> *Span {
    span : *Span = null;
    if span_count == 1
        heap_cache_adopt_deferred(heap, *span);
    else
        heap_cache_adopt_deferred(heap, null);
    return span;
}


heap_reserved_extract :: (heap: *Heap, span_count: s64) -> *Span {
    if heap.spans_reserved >= span_count
        return span_map(heap, span_count);
    return null;
}

// Get a span from one of the cache levels (thread cache, reserved, global cache) or fallback to mapping more memory
heap_extract_new_span :: (heap: *Heap, heap_size_class: *Heap_Size_Class, span_count: s64, class_idx: u32) -> *Span {
    span : *Span = ---;

    // Allow 50% overhead to increase cache hits
    base_span_count := span_count;
    limit_span_count := ifx span_count > 2 then span_count + (span_count >> 1) else span_count;
    if limit_span_count > LARGE_CLASS_COUNT
        limit_span_count = LARGE_CLASS_COUNT;

    while true {
        span = heap_thread_cache_deferred_extract(heap, span_count);
        if span  return span;

        span = heap_reserved_extract(heap, span_count);
        if span  return span;

        span_count += 1;
        if span_count > limit_span_count  break;
    }

    //Final fallback, map in more virtual memory
    span = span_map(heap, base_span_count);
    return span;
}


heap_initialize :: (heap: *Heap) {
    memset(heap, 0, size_of(Heap));
    //Get a new heap ID
    heap.id = 1 + atomic_inc(*memory_heap_id);

    //Link in heap in heap ID map
    list_idx := heap.id % HEAP_ARRAY_SIZE;
    heap.next_heap = memory_heaps[list_idx];
    memory_heaps[list_idx] = heap;
}


heap_orphan :: (heap: *Heap) {
    heap.is_orphaned = true;
    heap_list := *memory_orphan_heaps;
    heap.next_orphan = <<heap_list;
    <<heap_list = heap;
}


// Allocate a new heap from newly mapped memory pages
heap_allocate_new :: () -> *Heap {
    // Map in pages for 16 heaps. If page size is greater than required size for this, map a page and
    // use first part for heaps and remaining part for spans for allocations. Adds a lot of complexity,
    // but saves a lot of memory on systems where page size > 64 spans (4MiB)
    heap_size := size_of(Heap);
    aligned_heap_size := 16 * ((heap_size + 15) / 16);
    request_heap_count := 16;
    heap_span_count := ((aligned_heap_size * request_heap_count) + size_of(Span) + MEMORY_SPAN_SIZE - 1) / MEMORY_SPAN_SIZE;
    block_size := MEMORY_SPAN_SIZE * heap_span_count;
    span_count := heap_span_count;
    span : *Span = null;

    // If there are global reserved spans, use these first
    if memory_global_reserve_count >= heap_span_count {
        span = global_get_reserved_spans(heap_span_count);
    }

    if !span {
        if memory_page_size > block_size {
            span_count = memory_page_size / MEMORY_SPAN_SIZE;
            block_size = memory_page_size;
            // If using huge pages, make sure to grab enough heaps to avoid reallocating a huge page just to serve new heaps
            possible_heap_count := (block_size - size_of(Span)) / aligned_heap_size;
            if possible_heap_count >= (request_heap_count * 16)
                request_heap_count *= 16;
            else if possible_heap_count < request_heap_count
                request_heap_count = possible_heap_count;
            heap_span_count = ((aligned_heap_size * request_heap_count) + size_of(Span) + MEMORY_SPAN_SIZE - 1) / MEMORY_SPAN_SIZE;
        }

        align_offset := 0;
        span = cast(*Span) _mmap(block_size, *align_offset);
        if !span  return null;

        // Master span will contain the heaps
        span_initialize(span, span_count, heap_span_count, align_offset);
    }

    remain_size := MEMORY_SPAN_SIZE - size_of(Span);
    heap : *Heap = pointer_offset(span, size_of(Span));
    heap_initialize(heap);

    // Put extra heaps as orphans
    num_heaps := remain_size / aligned_heap_size;
    if num_heaps < request_heap_count
        num_heaps = request_heap_count;
    atomic_store(*heap.child_count, cast(s32)num_heaps - 1);
    extra_heap : *Heap = pointer_offset(heap, aligned_heap_size);

    while num_heaps > 1 {
        heap_initialize(extra_heap);
        extra_heap.master_heap = heap;
        heap_orphan(extra_heap);
        extra_heap = pointer_offset(extra_heap, aligned_heap_size);
        num_heaps -= 1;
    }

    if span_count > heap_span_count {
        // Cap reserved spans
        remain_count := span_count - heap_span_count;
        reserve_count := ifx remain_count > memory_heap_reserve_count then memory_heap_reserve_count else remain_count;
        remain_span : *Span = pointer_offset(span, heap_span_count * MEMORY_SPAN_SIZE);
        heap_set_reserved_spans(heap, span, remain_span, reserve_count);

        if remain_count > reserve_count {
            // Set to global reserved spans
            remain_span = pointer_offset(remain_span, reserve_count * MEMORY_SPAN_SIZE);
            reserve_count = remain_count - reserve_count;
            global_set_reserved_spans(span, remain_span, reserve_count);
        }
    }

    return heap;
}


heap_extract_orphan :: (heap_list: **Heap) -> *Heap {
    heap := <<heap_list;
    <<heap_list = ifx heap then heap.next_orphan else null;
    return heap;
}


// Allocate a new heap, potentially reusing a previously orphaned heap
heap_allocate :: () -> *Heap {
    heap : *Heap = null;
    while !atomic_compare_and_swap(*memory_global_lock, 1, 0)
        spin();

    if !heap  heap = heap_extract_orphan(*memory_orphan_heaps);
    if !heap  heap = heap_allocate_new();

    atomic_store(*memory_global_lock, 0);

    if heap  heap_cache_adopt_deferred(heap, null);

    return heap;
}


_heap_release :: (heapptr: *void) {
    if !heapptr  return;

    heap: *Heap = heapptr;

    // Release thread cache spans back to global cache
    heap_cache_adopt_deferred(heap, null);

    while !atomic_compare_and_swap(*memory_global_lock, 1, 0)
        spin();

    heap_orphan(heap);

    atomic_store(*memory_global_lock, 0);
}

heap_finalize :: (heap: *Heap) {
    if heap.spans_reserved {
        span := span_map(heap, heap.spans_reserved);
        span_unmap(span);
        heap.spans_reserved = 0;
    }

    heap_cache_adopt_deferred(heap, null);

    for iclass: 0 .. SIZE_CLASS_COUNT - 1 {
        if heap.size_class[iclass].cache
            span_unmap(heap.size_class[iclass].cache);
        heap.size_class[iclass].cache = null;

        span := heap.size_class[iclass].partial_span;
        while span {
            next := span.next;
            span_finalize(heap, iclass, span, *heap.size_class[iclass].partial_span);
            span = next;
        }

        // If class still has a free list it must be a full span
        if heap.size_class[iclass].free_list {
            class_span := cast(*Span)(heap.size_class[iclass].free_list & MEMORY_SPAN_MASK);
            list := *heap.full_span[iclass];
            heap.full_span_count -= 1;
            if !span_finalize(heap, iclass, class_span, list) {
                if list  span_double_link_list_remove(list, class_span);
                span_double_link_list_add(*heap.size_class[iclass].partial_span, class_span);
            }
        }
    }

    assert(!atomic_load(*heap.span_free_deferred), "Heaps still active during finalization");
}


/// Allocation entry points

// Pop first block from a free list
free_list_pop :: inline (list: **void) -> *void {
    block := <<list;
    <<list = <<cast(**void)block;
    return block;
}


// Allocate a small/medium sized memory block from the given heap
allocate_from_heap_fallback :: (heap: *Heap, heap_size_class: *Heap_Size_Class, class_idx: u32) -> *void {
    span := heap_size_class.partial_span;
    if span {
        assert(span.block_count == memory_size_class[span.size_class].block_count, "Span block count corrupted");
        assert(!span_is_fully_utilized(span), "Internal failure");

        block : *void;
        if span.free_list {
            //Span local free list is not empty, swap to size class free list
            block = free_list_pop(*span.free_list);
            heap_size_class.free_list = span.free_list;
            span.free_list = null;
        }
        else {
            //If the span did not fully initialize free list, link up another page worth of blocks
            block_start := pointer_offset(span, SPAN_HEADER_SIZE + (span.free_list_limit * span.block_size));
            span.free_list_limit += free_list_partial_init(*heap_size_class.free_list,
                                                           *block,
                                                           cast(*void)(block_start & ~(memory_page_size - 1)),
                                                           block_start,
                                                           span.block_count - span.free_list_limit, span.block_size);
        }

        assert(span.free_list_limit <= span.block_count, "Span block count corrupted");
        span.used_count = span.free_list_limit;

        //Swap in deferred free list if present
        if atomic_load(*span.free_list_deferred)
            span_extract_free_list_deferred(span);

        //If span is still not fully utilized keep it in partial list and early return block
        if !span_is_fully_utilized(span)
            return block;

        //The span is fully utilized, unlink from partial list and add to fully utilized list
        span_double_link_list_pop_head(*heap_size_class.partial_span, span);
        span_double_link_list_add(*heap.full_span[class_idx], span);

        heap.full_span_count += 1;
        return block;
    }

    //Find a span in one of the cache levels
    span = heap_extract_new_span(heap, heap_size_class, 1, class_idx);
    if span {
        //Mark span as owned by this heap and set base data, return first block
        return span_initialize_new(heap, heap_size_class, span, class_idx);
    }

    return null;
}


// Allocate a small sized memory block from the given heap
allocate_small :: (heap: *Heap, size: s64) -> *void {
    assert(heap != null, "No thread heap");

    //Small sizes have unique size classes
    class_idx := cast(u32)((size + (SMALL_GRANULARITY - 1)) >> SMALL_GRANULARITY_SHIFT);
    heap_size_class : *Heap_Size_Class = heap.size_class.data + class_idx;
    if heap_size_class.free_list
        return free_list_pop(*heap_size_class.free_list);
    return allocate_from_heap_fallback(heap, heap_size_class, class_idx);
}


// Allocate a medium sized memory block from the given heap
allocate_medium :: (heap: *Heap, size: s64) -> *void {
    assert(heap != null, "No thread heap");
    assert(size > SMALL_SIZE_LIMIT, "Calling allocate_medium with something that should be allocate_small");

    //Calculate the size class index and do a dependent lookup of the final class index (in case of merged classes)
    base_idx := cast(u32)(SMALL_CLASS_COUNT + ((size - (SMALL_SIZE_LIMIT + 1)) >> MEDIUM_GRANULARITY_SHIFT));
    class_idx : u32 = memory_size_class[base_idx].class_idx;
    heap_size_class : *Heap_Size_Class = heap.size_class.data + class_idx;
    if heap_size_class.free_list
        return free_list_pop(*heap_size_class.free_list);
    return allocate_from_heap_fallback(heap, heap_size_class, class_idx);
}


// Allocate a large sized memory block from the given heap
allocate_large :: (heap: *Heap, size: s64) -> *void {
    assert(heap != null, "No thread heap");
    assert(size > MEDIUM_SIZE_LIMIT, "Calling allocate_large with something that should be allocate_medium");

    //Calculate number of needed max sized spans (including header)
    //Since this function is never called if size > LARGE_SIZE_LIMIT
    //the span_count is guaranteed to be <= LARGE_CLASS_COUNT
    size += SPAN_HEADER_SIZE;
    span_count := size >> MEMORY_SPAN_SIZE_SHIFT;
    if size & (MEMORY_SPAN_SIZE - 1)
        span_count += 1;

    //Find a span in one of the cache levels
    span := heap_extract_new_span(heap, null, span_count, cast(u32)SIZE_CLASS_LARGE);
    if !span  return null;

    //Mark span as owned by this heap and set base data
    assert(span.span_count >= span_count, "Internal failure");
    span.size_class = cast(u32)SIZE_CLASS_LARGE;
    span.heap = heap;

    span_double_link_list_add(*heap.large_huge_span, span);

    heap.full_span_count += 1;

    return pointer_offset(span, SPAN_HEADER_SIZE);
}


// Allocate a huge block by mapping memory pages directly
allocate_huge :: (heap: *Heap, size: s64) -> *void {
    assert(heap != null, "No thread heap");

    heap_cache_adopt_deferred(heap, null);
    size += SPAN_HEADER_SIZE;
    num_pages := size >> memory_page_size_shift;
    if size & (memory_page_size - 1)
        num_pages += 1;
    align_offset := 0;
    span : *Span = _mmap(num_pages * memory_page_size, *align_offset);
    if !span  return null;

    //Store page count in span_count
    span.size_class = SIZE_CLASS_HUGE;
    span.span_count = cast(u32)num_pages;
    span.align_offset = cast(u32)align_offset;
    span.heap = heap;

    span_double_link_list_add(*heap.large_huge_span, span);

    heap.full_span_count += 1;

    return pointer_offset(span, SPAN_HEADER_SIZE);
}


lock_for_scope :: (heap: *Heap) #expand {
    _heap := heap;

    //
    // In order to support recursion, we use the addres of the Context as our unique
    // lock handle. This will fail if you can somehow push the same address as the context
    // in multiple threads... hopefully there is not a way to do that! But honestly
    // I have thought about letting people push a pointer as the context, which would
    // open this up to being a huge problem. So, uhhh.... to be thought about.
    //

    pointer := *context.base; // We could just do *context, but I am being paranoid for now...

    already_holding_the_lock := atomic_load(*heap.lock) == pointer;

    if !already_holding_the_lock {
        while !atomic_compare_and_swap(*_heap.lock, pointer, null)  spin();
    }

    `defer if !already_holding_the_lock atomic_store(*_heap.lock, null);
}


// Allocate a block of the given size
allocate :: (heap: *Heap, size: s64) -> *void {
    lock_for_scope(heap);

    if size <= SMALL_SIZE_LIMIT
        return allocate_small(heap, size);
    else if size <= MEDIUM_SIZE_LIMIT
        return allocate_medium(heap, size);
    else if size <= LARGE_SIZE_LIMIT
        return allocate_large(heap, size);
    else
        return allocate_huge(heap, size);
}


///
/// Deallocation entry points
///

// Deallocate the given small/medium memory block in the current thread local heap
deallocate_direct_small_or_medium :: (span: *Span, block: *void) {
    heap := span.heap;
    assert(!heap.is_orphaned || heap.finalize, "Internal failure");

    //Add block to free list
    if span_is_fully_utilized(span) {
        span.used_count = span.block_count;
        span_double_link_list_remove(*heap.full_span[span.size_class], span);
        span_double_link_list_add(*heap.size_class[span.size_class].partial_span, span);
        heap.full_span_count -= 1;
    }

    <<cast(**void)block = span.free_list;
    span.used_count -= 1;
    span.free_list = block;
    if span.used_count == span.list_size {
        // If there are no used blocks it is guaranteed that no other external thread is accessing the span
        if span.used_count {
            // Make sure we have synchronized the deferred list and list size by using acquire semantics
            // and guarantee that no external thread is accessing span concurrently
            free_list : *void = ---;
            while true {
                free_list = atomic_exchange(*span.free_list_deferred, INVALID_POINTER);
                if free_list != INVALID_POINTER  break;
            }
            atomic_store(*span.free_list_deferred, free_list);
        }
        span_double_link_list_remove(*heap.size_class[span.size_class].partial_span, span);
        span_release_to_cache(heap, span);
    }
}


deallocate_defer_free_span :: (heap: *Heap, span: *Span) {
    //This list does not need ABA protection, no mutable side state
    while true {
        span.free_list = atomic_load(*heap.span_free_deferred);
        if atomic_compare_and_swap(*heap.span_free_deferred, span, span.free_list) break;
    }
}


// Put the block in the deferred free list of the owning span
deallocate_defer_small_or_medium :: (span: *Span, block: *void) {
    // The memory ordering here is a bit tricky, to avoid having to ABA protect
    // the deferred free list to avoid desynchronization of list and list size
    // we need to have acquire semantics on successful CAS of the pointer to
    // guarantee the list_size variable validity + release semantics on pointer store
    free_list : *void = ---;
    while true {
        free_list = atomic_exchange(*span.free_list_deferred, INVALID_POINTER);
        if free_list != INVALID_POINTER break;
    }
    <<cast(**void)block = free_list;
    span.list_size += 1;
    free_count : u32 = span.list_size;
    all_deferred_free := (free_count == span.block_count);
    atomic_store(*span.free_list_deferred, block);
    if all_deferred_free {
        // Span was completely freed by this block. Due to the INVALID_POINTER spin lock
        // no other thread can reach this state simultaneously on this span.
        // Safe to move to owner heap deferred cache
        deallocate_defer_free_span(span.heap, span);
    }
}


deallocate_small_or_medium :: (span: *Span, p: *void) {
    if span.flags & .ALIGNED_BLOCKS {
        //Realign pointer to block start
        blocks_start := pointer_offset(span, SPAN_HEADER_SIZE);
        block_offset := cast(u32)pointer_diff(p, blocks_start);
        p = pointer_offset(p, -cast(s32)(block_offset % span.block_size));
    }

    //Check if block belongs to this heap or if deallocation should be deferred
    do_defer := span.heap.is_orphaned && !span.heap.finalize;
    if !do_defer
        deallocate_direct_small_or_medium(span, p);
    else
        deallocate_defer_small_or_medium(span, p);
}


// Deallocate the given large memory block to the current heap
deallocate_large :: (span: *Span) {
    assert(span.size_class == SIZE_CLASS_LARGE, "Bad span size class");
    assert(!(span.flags & .MASTER) || !(span.flags & .SUBSPAN), "Span flag corrupted");
    assert((span.flags & .MASTER) || (span.flags & .SUBSPAN), "Span flag corrupted");

    //We must always defer (unless finalizing) if from another heap since we cannot touch the list or counters of another heap
    do_defer := span.heap.is_orphaned && !span.heap.finalize;
    if do_defer {
        deallocate_defer_free_span(span.heap, span);
        return;
    }

    assert(span.heap.full_span_count > 0, "Heap span counter corrupted");
    span.heap.full_span_count -= 1;
    span_double_link_list_remove(*span.heap.large_huge_span, span);

    heap := span.heap;
    assert(heap != null, "No thread heap");

    if (span.span_count > 1) && !heap.finalize && !heap.spans_reserved {
        heap.span_reserve = span;
        heap.spans_reserved = span.span_count;
        if span.flags & .MASTER {
            heap.span_reserve_master = span;
        } else {  // .SUBSPAN
            master : *Span = pointer_offset(span, -(cast(s64)span.offset_from_master * MEMORY_SPAN_SIZE));
            heap.span_reserve_master = master;
            assert((master.flags & .MASTER) != 0, "Span flag corrupted");
            assert(atomic_load(*master.remaining_spans) >= cast(s32)span.span_count, "Master span count corrupted");
        }
    } else {
        //Insert into cache list
        heap_cache_insert(heap, span);
    }
}


// Deallocate the given huge span
deallocate_huge :: (span: *Span) {
    assert(span.heap != null, "No span heap");

    do_defer := (span.heap.is_orphaned && !span.heap.finalize);
    if do_defer {
        deallocate_defer_free_span(span.heap, span);
        return;
    }

    assert(span.heap.full_span_count > 0, "Heap span counter corrupted");

    span.heap.full_span_count -= 1;
    span_double_link_list_remove(*span.heap.large_huge_span, span);

    //Oversized allocation, page count is stored in span_count
    num_pages := span.span_count;
    unmap(span, num_pages * memory_page_size, span.align_offset, num_pages * memory_page_size);
}


// Deallocate the given block
deallocate :: (p: *void) {
    //Grab the span (always at start of span, using span alignment)
    span := cast(*Span)(cast(u64)p & MEMORY_SPAN_MASK);
    if !span  return;

    lock_for_scope(span.heap);

    if span.size_class < SIZE_CLASS_COUNT
        deallocate_small_or_medium(span, p);
    else if span.size_class == SIZE_CLASS_LARGE
        deallocate_large(span);
    else
        deallocate_huge(span);
}


///
/// Reallocation entry points
///

// Reallocate the given block to the given size
reallocate :: (heap: *Heap, p: *void, size: s64, oldsize: s64) -> *void {
    if p {
        //Grab the span using guaranteed span alignment
        span := cast(*Span)(cast(s64)p & MEMORY_SPAN_MASK);
        if span.size_class < SIZE_CLASS_COUNT {
            //Small/medium sized block
            assert(span.span_count == 1, "Span counter corrupted");
            blocks_start := pointer_offset(span, SPAN_HEADER_SIZE);
            block_offset := cast(u32) pointer_diff(p, blocks_start);
            block_idx := block_offset / span.block_size;
            block := pointer_offset(blocks_start, block_idx * span.block_size);
            if !oldsize  oldsize = (span.block_size - pointer_diff(p, block));

            if span.block_size >= size {
                //Still fits in block, never mind trying to save memory, but preserve data if alignment changed
                if p != block
                    memcpy(block, p, oldsize);
                return block;
            }
        } else if span.size_class == SIZE_CLASS_LARGE {
            //Large block
            total_size := size + SPAN_HEADER_SIZE;
            num_spans := total_size >> MEMORY_SPAN_SIZE_SHIFT;
            if total_size & (MEMORY_SPAN_MASK - 1)
                num_spans += 1;

            current_spans := span.span_count;
            block := pointer_offset(span, SPAN_HEADER_SIZE);
            if !oldsize  oldsize = (current_spans * MEMORY_SPAN_SIZE) - pointer_diff(p, block) - SPAN_HEADER_SIZE;

            if (current_spans >= num_spans) && (total_size >= (oldsize / 2)) {
                //Still fits in block, never mind trying to save memory, but preserve data if alignment changed
                if p != block
                    memcpy(block, p, oldsize);
                return block;
            }
        } else {
            //Oversized block
            total_size := size + SPAN_HEADER_SIZE;
            num_pages := total_size >> memory_page_size_shift;
            if total_size & (memory_page_size - 1)
                num_pages += 1;

            //Page count is stored in span_count
            current_pages := span.span_count;
            block := pointer_offset(span, SPAN_HEADER_SIZE);
            if !oldsize  oldsize = (current_pages * memory_page_size) - pointer_diff(p, block) - SPAN_HEADER_SIZE;
            if (current_pages >= num_pages) && (num_pages >= (current_pages / 2)) {
                //Still fits in block, never mind trying to save memory, but preserve data if alignment changed
                if p != block
                    memcpy(block, p, oldsize);
                return block;
            }
        }
    } else {
        oldsize = 0;
    }

    //Size is greater than block size, need to allocate a new block and deallocate the old
    //Avoid hysteresis by overallocating if increase is small (below 37%)
    lower_bound := oldsize + (oldsize >> 2) + (oldsize >> 3);
    new_size := ifx size > lower_bound then size else (ifx size > oldsize then lower_bound else size);
    block := allocate(heap, new_size);
    if p && block {
        memcpy(block, p, ifx oldsize < new_size then oldsize else new_size);
        deallocate(p);
    }

    return block;
}


///
/// Initialization, finalization and utility
///


// Get the usable size of the given block
get_usable_size :: (p: *void) -> s64 {
    //Grab the span using guaranteed span alignment
    span := cast(*Span)(cast(u64)p & MEMORY_SPAN_MASK);
    if span.size_class < SIZE_CLASS_COUNT {
        //Small/medium block
        blocks_start : *void = pointer_offset(span, SPAN_HEADER_SIZE);
        return span.block_size - (pointer_diff(p, blocks_start) % span.block_size);
    }

    if span.size_class == SIZE_CLASS_LARGE {
        //Large block
        current_spans := span.span_count;
        return (current_spans * MEMORY_SPAN_SIZE) - pointer_diff(p, span);
    }

    //Oversized block, page count is stored in span_count
    current_pages := span.span_count;
    return (current_pages * memory_page_size) - pointer_diff(p, span);
}


// Adjust and optimize the size class properties for the given class
adjust_size_class :: (iclass: s64) {
    block_size := memory_size_class[iclass].block_size;
    block_count := (MEMORY_SPAN_SIZE - SPAN_HEADER_SIZE) / block_size;

    memory_size_class[iclass].block_count = cast(u16)block_count;
    memory_size_class[iclass].class_idx = cast(u16)iclass;

    //Check if previous size classes can be merged
    if iclass >= SMALL_CLASS_COUNT {
        prevclass := iclass;
        while prevclass > 0 {
            prevclass -= 1;
            //A class can be merged if number of pages and number of blocks are equal
            if memory_size_class[prevclass].block_count == memory_size_class[iclass].block_count
                memcpy(memory_size_class.data + prevclass, memory_size_class.data + iclass, size_of(type_of(memory_size_class[iclass])));
            else
                break;
        }
    }
}

// Initialize the allocator and setup global data
_initialize_if_needed :: inline (default_heap: **Heap) -> did_init: bool {
    if initialized  return false;

    while !atomic_compare_and_swap(*memory_init_lock, 1, 0)
        spin();
    defer atomic_store(*memory_init_lock, 0);

    if initialized  return false;

    #if OS == .WINDOWS {
        system_info : SYSTEM_INFO;
        GetSystemInfo(*system_info);
        memory_map_granularity = xx system_info.dwAllocationGranularity;
        memory_page_size = system_info.dwPageSize;
    } else {
        memory_map_granularity = get_page_size();
        memory_page_size = memory_map_granularity;
    }

    min_span_size :: 256;
    max_page_size :: 4096 * 1024 * 1024;

    if memory_page_size < min_span_size
        memory_page_size = min_span_size;
    if memory_page_size > max_page_size
        memory_page_size = max_page_size;
    memory_page_size_shift = 0;
    page_size_bit := memory_page_size;
    while page_size_bit != 1 {
        memory_page_size_shift += 1;
        page_size_bit >>= 1;
    }
    memory_page_size = 1 << memory_page_size_shift;

    memory_span_map_count = DEFAULT_SPAN_MAP_COUNT;
    if (MEMORY_SPAN_SIZE * memory_span_map_count) < memory_page_size
        memory_span_map_count = (memory_page_size / MEMORY_SPAN_SIZE);
    if (memory_page_size >= MEMORY_SPAN_SIZE) && ((memory_span_map_count * MEMORY_SPAN_SIZE) % memory_page_size)
        memory_span_map_count = (memory_page_size / MEMORY_SPAN_SIZE);
    memory_heap_reserve_count = ifx memory_span_map_count > DEFAULT_SPAN_MAP_COUNT then DEFAULT_SPAN_MAP_COUNT else memory_span_map_count;

    //Setup all small and medium size classes
    memory_size_class[0].block_size = SMALL_GRANULARITY;
    adjust_size_class(0);
    for iclass: 1 .. SMALL_CLASS_COUNT - 1 {
        size := iclass * SMALL_GRANULARITY;
        memory_size_class[iclass].block_size = cast(u32)size;
        adjust_size_class(iclass);
    }

    for iclass: 0 .. MEDIUM_CLASS_COUNT - 1 {
        size := SMALL_SIZE_LIMIT + ((iclass + 1) * MEDIUM_GRANULARITY);
        if size > MEDIUM_SIZE_LIMIT
            break;
        memory_size_class[SMALL_CLASS_COUNT + iclass].block_size = cast(u32)size;
        adjust_size_class(SMALL_CLASS_COUNT + iclass);
    }

    memory_orphan_heaps = null;

    memset(memory_heaps.data, 0, size_of(type_of(memory_heaps)));

    if !<<default_heap {
        <<default_heap = _heap_acquire();
    }

    initialized = true;

    return true;
}

// Finalize the allocator
_finalize :: () {
    if memory_global_reserve {
        atomic_add(*memory_global_reserve_master.remaining_spans, -cast(s32)memory_global_reserve_count);
        memory_global_reserve_master = null;
        memory_global_reserve_count = 0;
        memory_global_reserve = null;
    }
    atomic_store(*memory_global_lock, 0);

    // Free all thread caches and fully free spans
    for list_idx: 0 .. HEAP_ARRAY_SIZE - 1 {
        heap := memory_heaps[list_idx];
        while heap {
            next_heap := heap.next_heap;
            heap.finalize = 1;
            heap_global_finalize(heap);
            heap = next_heap;
        }
    }

    initialized = false;
}

_heap_acquire :: inline () -> *Heap {
    // Must be a pristine heap from newly mapped memory pages, or else memory blocks
    // could already be allocated from the heap which would (wrongly) be released when
    // heap is cleared with default_allocator_heap_free_all(). Also heaps guaranteed to be
    // pristine from the dedicated orphan list can be used.
    heap := heap_allocate();
    heap.is_orphaned = false;
    return heap;
}

#scope_export

is_initialized :: inline () -> bool {
    return initialized;
}

usable_size :: inline (ptr: *void) -> s64 {
    return ifx initialized && ptr then get_usable_size(ptr) else 0;
}

is_this_yours :: (heap: *Heap, memory: *void) -> bool {
    is_in_span :: inline (memory: *void, span: *Span) -> bool {
        base := cast(*void) span;
        end := base + span.span_count * MEMORY_SPAN_SIZE;
        return (memory >= base) && (memory < end);
    }

    lock_for_scope(heap);

    for iclass: 0 .. SIZE_CLASS_COUNT - 1 {
        span := heap.size_class[iclass].partial_span;
        while span {
            if is_in_span(memory, span) return true;
            span = span.next;
        }

        span = heap.full_span[iclass];
        while span {
            if is_in_span(memory, span) return true;
            span = span.next;
        }
    }

    span := heap.large_huge_span;
    if span && is_in_span(memory, span) return true;

    return false;
}

heap_free_all :: (heap: *Heap) { // We may add a FREE_ALL to Allocator_Mode, which would just call this directly... otherwise we could remove!
    span : *Span = ---;
    next_span : *Span = ---;

    heap_cache_adopt_deferred(heap, null);

    for iclass: 0 .. SIZE_CLASS_COUNT - 1 {
        span = heap.size_class[iclass].partial_span;
        while span {
            next_span = span.next;
            heap_cache_insert(heap, span);
            span = next_span;
        }
        heap.size_class[iclass].partial_span = null;
        span = heap.full_span[iclass];
        while span {
            next_span = span.next;
            heap_cache_insert(heap, span);
            span = next_span;
        }
    }
    memset(heap.size_class.data, 0, size_of(type_of(heap.size_class)));
    memset(heap.full_span.data, 0, size_of(type_of(heap.full_span)));

    span = heap.large_huge_span;
    while span {
        next_span = span.next;
        if span.size_class == SIZE_CLASS_HUGE
            deallocate_huge(span);
        else
            heap_cache_insert(heap, span);
        span = next_span;
    }
    heap.large_huge_span = null;
    heap.full_span_count = 0;
}

global_statistics :: () -> Global_Statistics {
    return .{};
}

heap_statistics :: (heap: *Heap) -> Heap_Statistics {
    stats : Heap_Statistics;
    if !heap  return stats;

    for iclass: 0 .. SIZE_CLASS_COUNT - 1 {
        size_class := memory_size_class.data + iclass;
        span := heap.size_class[iclass].partial_span;
        while span {
            free_count : s64 = span.list_size;
            block_count : s64 = size_class.block_count;
            if span.free_list_limit < block_count
                block_count = span.free_list_limit;
            free_count += (block_count - span.used_count);
            stats.sizecache = free_count * size_class.block_size;
            span = span.next;
        }
    }

    deferred := cast(*Span) atomic_load(*heap.span_free_deferred);
    while deferred {
        if deferred.size_class != SIZE_CLASS_HUGE
            stats.spancache = deferred.span_count * MEMORY_SPAN_SIZE;
        deferred = cast(*Span)deferred.free_list;
    }

    return stats;
}

#if OS == .PS5 {
    #load "ps5.jai";
}
