// A simple bit array.

Bit_Array :: struct {
    slots: [] s64;
    count: int;

    allocator: Allocator;
}


set_bit :: (using array: *Bit_Array, i: int) {
    // assert(i < count);
    slots[i >> 6] |= (1 << (i & 63));    
}

clear_bit :: (using array: *Bit_Array, i: int) {
    // assert(i < count);
    slots[i >> 6] &= ~(1 << (i & 63));
}

toggle_bit :: (using array: *Bit_Array, i: int) {
    // assert(i < count);
    slots[i >> 6] ^= (1 << (i & 63));
}

set_bit_to :: (using array: *Bit_Array, i: int, value: bool) {
    // assert(i < count);
    slots[i >> 6] = set_bits(slots[i >> 6], 1 << (i & 63), value);
    // assert((<<array)[i] == value);
}

operator [] :: (a: Bit_Array, i: int) -> bool {
    // assert(i < a.count);
    return cast(bool) (a.slots[i >> 6] & (1 << (i & 63)));
}

operator []= :: inline (a: *Bit_Array, i: int, value: bool) {
    inline set_bit_to(a, i, value);
}


clear_all_bits :: (using array: *Bit_Array) {
    memset(slots.data, 0, slots.count * size_of(s64));
}

set_all_bits :: (using array: *Bit_Array) {
    memset(slots.data, 0xFF, slots.count * size_of(s64));
}

toggle_all_bits :: (using array: *Bit_Array) {
    for * slots { <<it ^= 0xFFFFFFFF_FFFFFFFF; }
}



// for_expansion generates 'it' as a boolean, true or false for each bit.
// A little more code, a little easier to understand?

for_expansion :: (array: *Bit_Array, body: Code, flags: For_Flags) #expand {
    #assert(flags == 0);  // No options are supported.

    // Avoid variable-shift in order to be fast. Just left-shift by 1 each time.

    for slot, slot_index: array.slots {
        base_index := slot_index * 64;
        limit      := Basic.min(array.count - base_index - 1, 63);  // Don't go past the number of bits that are actually stored.

        bit := 1;
        for i: 0..limit {
            `it := (slot & bit) != 0;
            bit <<= 1;
            `it_index := base_index + i;

            #insert (remove=#assert(false), break=break slot) body;
        }            
    }
}

/*
// Modern Programmer Version that even supports reversal.
// It would be interesting to see how good the codegen ends up being here.

for_expansion :: (array: Bit_Array, body: Code, flags: For_Flags) #expand {
    #// assert(!(flags & .POINTER));
    
    for <=cast(bool)(flags & .REVERSE) `it_index: 0..array.count-1 {
        `it := inline array[it_index];
        #// insert (remove=#assert(false)) body;
    }
}
*/

#scope_file

// See "Conditionally set or clear bits without branching" at http://graphics.stanford.edu/~seander/bithacks.html
set_bits :: inline (w: s64, m: s64, b: bool) -> s64 {
    return (w & ~m) | ((-cast(s64)b) & m);
}



// This file contains fixes placed into the public domain by Matija.
