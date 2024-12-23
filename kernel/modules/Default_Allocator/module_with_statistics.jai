#module_parameters (
    ENABLE_STATISTICS    := true,  // Enable statistics collection
    ENABLE_ASSERTS       := true,  // Enable asserts
    ENABLE_VALIDATE_ARGS := true   // Enable validation of args to public entry points
)();


allocator :: Allocator.{allocator_proc, null};
allocator_default_heap : *Heap;


allocator_proc :: (mode: Allocator_Mode, requested_size: s64, old_size: s64, old_memory_pointer: *void, allocator_data: *void) -> *void {
    initialize_if_needed();

    heap := ifx allocator_data then xx allocator_data else allocator_default_heap;

    if #complete mode == {
        case .ALLOCATE;
        return heap_alloc(heap, requested_size);

        case .RESIZE;
        return heap_realloc(heap, old_memory_pointer, requested_size);

        case .FREE;
        heap_free(heap, xx old_memory_pointer);
        return null;

        case .STARTUP;
        initialize_if_needed();
        return null;
        
        case .SHUTDOWN;
        allocator_default_heap = null;
        return null;
        
        case .THREAD_START;
        return null;
        
        case .THREAD_STOP;
        return null;
        
        case .CREATE_HEAP;
        heap := heap_acquire();
        return heap;
        
        case .DESTROY_HEAP;
        heap_release(allocator_data);
        return null;
        
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


#load "Default_Allocator.jai";


/*

    Exported procedures:

        heap_acquire
        heap_release
        heap_free_all

        is_initialized
        usable_size

        global_statistics
        heap_statistics

*/
