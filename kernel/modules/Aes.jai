
// It might seem reasonable to use the Int128 module here, but in fact we need none of the operations implemented there and it would create a dependency on Basic.

i128 :: union {
    struct {low, high: u64;};
    bytes: [16]u8;
    dwords: [4]u32;
}

aes128_expand_key :: (key: i128) -> [11]i128 {

    key_schedule: [11] i128;
    key_schedule[0] = key;

    GenerateRoundKey :: (key: i128, $round: u8) -> i128 {
        t1, t2, t3: i128;

        #asm {
            movdqa t1, key;
            aeskeygenassist t2, t1, round;

            pshufd t2, t2, 0xff;
            movdqa t3, t1;
            pslldq t3, 0x4;
            pxor   t1, t3;
            pslldq t3, 0x4;
            pxor   t1, t3;
            pslldq t3, 0x4;
            pxor   t1, t3;
            pxor   t1, t2;
        }

        return t1;
    }

    key_schedule[1]  = GenerateRoundKey(key_schedule[0], 0x1);
    key_schedule[2]  = GenerateRoundKey(key_schedule[1], 0x2);
    key_schedule[3]  = GenerateRoundKey(key_schedule[2], 0x4);
    key_schedule[4]  = GenerateRoundKey(key_schedule[3], 0x8);
    key_schedule[5]  = GenerateRoundKey(key_schedule[4], 0x10);
    key_schedule[6]  = GenerateRoundKey(key_schedule[5], 0x20);
    key_schedule[7]  = GenerateRoundKey(key_schedule[6], 0x40);
    key_schedule[8]  = GenerateRoundKey(key_schedule[7], 0x80);
    key_schedule[9]  = GenerateRoundKey(key_schedule[8], 0x1b);
    key_schedule[10] = GenerateRoundKey(key_schedule[9], 0x36);

    return key_schedule;
}

aes128_encrypt_block :: (plaintext: i128, key_schedule: [11]i128) -> cipher: i128 {
    text := plaintext;

    whitening_key := key_schedule[0];
    #asm {pxor text, whitening_key;}

    for 1..9 {
        key := key_schedule[it];
        #asm {aesenc text, key;}
    }

    key := key_schedule[10];
    #asm {aesenclast text, key;}

    return text;
}

aes128_gcm_encrypt_stream_in_place :: (padded_stream: []u8, key: i128, nonce: [3]u32, authenticated_data: []u8) -> auth_tag: i128 {

    counter := i128.{
        dwords = .[1, nonce[0], nonce[1], nonce[2]]
    };

    key_schedule := aes128_expand_key(key);

    blocks: []i128;
    blocks.data = cast(*i128)padded_stream.data;
    blocks.count = padded_stream.count / 16;

    for 0..blocks.count-1 {
        E_k := aes128_encrypt_block(counter, key_schedule);

        blocks[it] ^= E_k;

        inc32(*counter);
    }

    return .{};
}

#scope_file

galois_multiply :: (X: i128, Y: i128) -> i128 {
    R: i128;
    R.bytes[15] = 0xe1;

    V := X;
    Z: i128;

    for 0..127 {
        bit := (127 - it).(u64);

        is_set := ifx bit < 64
            then Y.low  & (1 << bit).(u64)
            else Y.high & (1 << (bit - 64)).(u64);

        if is_set Z ^= V;

        V = shr(V);

        if V.low & 1 V ^= R;
    }

    return Z;
}

inc32 :: (a: *i128) {
    #no_abc {
        a.dwords[0] += 1;
    }
}

operator^ :: (a: i128, b: i128) -> i128 {
    c: i128;
    c.low = a.low ^ b.low;
    c.high = a.high ^ b.high;
    return c;
}

shr :: (a: i128) -> i128 {
    b: i128;
    b.low = a.low >> 1;
    b.high = a.high >> 1;

    b.low |= a.high << 63;
    return b;
}

#if false galois_test :: () {
    #import "Basic";

    X, Y: i128;
    X.high = 1234000000000;
    Y.high = 5678000000000;
    Z := galois_multiply(X, Y);

    log("Result: %1%2", formatInt(Z.high, minimum_digits=16, base=16), formatInt(Z.low, minimum_digits=16, base=16));

    assert(Z.low  == 0x199579502ce00000);
    assert(Z.high == 0x00000000000a967b);
}
