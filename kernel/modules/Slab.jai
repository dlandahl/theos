// Document: In addition to obvious copy avoidance advantages, here we also
// get the benefit that items don't move in memory, so you can take pointers to them.

Slab :: struct (type: Type, items_per_bucket: int, always_iterate_by_pointer := false) {
    count: s64;

    allocator: Allocator;

    My_Bucket :: Bucket(type, items_per_bucket);  // Type alias; types are first-class.

    all_buckets:    [..] *My_Bucket;
    unfull_buckets: [..] *My_Bucket;
}

Bucket :: struct (type: Type, items_per_bucket: int) {
    occupied: [items_per_bucket] bool;  // Could make this an array of u64 and use one bit for each dude.
    data:     [items_per_bucket] type = ---;

    lowest_maybe_not_occupied: s32; // Index that _may_ not be occupied, to decrease search space when adding elements.
    bucket_index: u32;

    count := 0;
}

slab_reset :: (using slab: *Slab) {
    for all_buckets free(it,, allocator);
    array_reset(*all_buckets);
    array_reset(*unfull_buckets);

    count = 0;
}

slab_add :: (using slab: *Slab, item: slab.type) -> (Bucket_Locator, pointer: *slab.type) {
    pointer, locator := find_and_occupy_empty_slot(array, initialize=false);
    <<pointer = item;

    return locator, pointer;
}

slab_find :: (using slab: *Slab, locator: Bucket_Locator) -> slab.type {
    bucket := all_buckets[locator.bucket_index];
    assert(bucket.occupied[locator.slot_index] == true);
    result := bucket.data[locator.slot_index];
    return result;
}

slab_remove :: (using slab: *Slab, locator: Bucket_Locator) {
    bucket := all_buckets[locator.bucket_index];
    assert(bucket.occupied[locator.slot_index] == true);

    was_full := (bucket.count == bucket.items_per_bucket);

    bucket.occupied[locator.slot_index] = false;

    if locator.slot_index < bucket.lowest_maybe_not_occupied {
        bucket.lowest_maybe_not_occupied = cast(s32) locator.slot_index;
    }

    bucket.count -= 1;
    array.count  -= 1;

    if was_full {
        assert(array_find(array.unfull_buckets, bucket) == false);
        array_add(*array.unfull_buckets, bucket);
    }
}

find_and_occupy_empty_slot :: (using slab: *Slab, $initialize := true) -> *slab.type, Bucket_Locator {
    if !unfull_buckets.count  add_bucket(array);
    assert(unfull_buckets.count > 0);  // @Incomplete: Some kind of error handling!

    bucket := unfull_buckets[0];

    index := -1;
    for bucket.lowest_maybe_not_occupied..bucket.items_per_bucket-1 {
        if !bucket.occupied[it] {       // @Speed: We can record the first non-empty index in the occupied list?
            index = it;
            break;
        }
    }

    assert(index != -1);

    bucket.occupied[index] = true;
    bucket.count += 1;
    bucket.lowest_maybe_not_occupied = cast(s32)(index+1);
    assert(bucket.count <= bucket.items_per_bucket);

    memory := *bucket.data[index];
    #if initialize {
        ini :: initializer_of(bucket.type);
        #if ini ini(memory);
        else memset(memory, 0, size_of(bucket.type));
    }

    array.count  += 1;

    if bucket.count == bucket.items_per_bucket {
        removed := array_unordered_remove_by_value(*array.unfull_buckets, bucket);
        assert(removed == 1);
    }

    locator: Bucket_Locator;
    locator.bucket_index  = bucket.bucket_index;
    locator.slot_index    = cast(s32) index;

    return memory, locator;
}


for_expansion :: (array: *$T/Slab, body: Code, flags: For_Flags) #expand {
    `it_index: int;

    REVERSE :: cast(bool) (flags & .REVERSE);

    #if REVERSE it_index = array.count;
    else        it_index = -1;

    DO_POINTER :: (flags & .POINTER) || array.always_iterate_by_pointer;

    for <=REVERSE bucket, bi: array.all_buckets {
        for <=REVERSE *=DO_POINTER  `it, i: bucket.data {
            if !bucket.occupied[i] continue;

            #if REVERSE  it_index -= 1;
            else         it_index += 1;

            #insert (break=break bucket, remove={locator: Bucket_Locator; locator.bucket_index = cast(u32) bi; locator.slot_index = cast(s32) i; slab_remove(array, locator);}) body;
        }
    }
}

operator *[] :: (using slab: Slab, index: int) -> *slab.type {
    bucket := all_buckets[bucket_index];
    assert(bucket.occupied[slot_index] == true);
    result := *bucket.data[slot_index];
    return result;
}

#scope_file

#import "Basic";  // For assert, array_*, New.


compose_index :: (bucket_index: int, slot_index: int) -> int {

}

decompose_index :: (index: int) -> bucket_index: int, slot_index: int {
    bucket_index := index / items_per_bucket;
    slot_index := index % items_per_bucket;
}

add_bucket :: (using slab: *Slab) -> *slab.My_Bucket {
    assert(unfull_buckets.count == 0);

    if !all_buckets.count {  // Therefore this is the first call.
        if allocator.proc {
            all_buckets.allocator    = allocator;
            unfull_buckets.allocator = allocator;
        }
    }

    // We don't need to push a new context because we changed the allocators on the arrays manually,
    // and we are passing allocator arguments explicitly to New.

    new_bucket := New(My_Bucket,, allocator);
    new_bucket.bucket_index = cast(u32) all_buckets.count;
    assert(new_bucket.bucket_index == all_buckets.count);  // Will assert if we overflowed.
    
    array_add(*all_buckets,    new_bucket);
    array_add(*unfull_buckets, new_bucket);

    return new_bucket;
}
