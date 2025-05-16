
// It might seem reasonable to use the Int128 module here, but in fact we need none of the operations implemented there and it would create a dependency on Basic.

i128 :: union {
    struct {low, high: u64;};
    array: [16]u8;
}

inc_i128 :: (a: *i128) {
    #no_abc { a.low += 1; }
    a.high += (a.low == 0).(u64);
}

aes128_expand_key :: (key: i128) -> [11]i128 {

    key_schedule: [11] i128;
    key_schedule[0] = key;

    GenerateRoundKey :: (key: i128, $round: u8) -> i128 {
        t1, t2, t3: i128;

        #asm {
            movdqa.128 t1, key;
            aeskeygenassist t2, t1, round;

            pshufd.128 t2, t2, 0xff;
            movdqa.128 t3, t1;
            pslldq.128 t3, 0x4;
            pxor  .128 t1, t3;
            pslldq.128 t3, 0x4;
            pxor  .128 t1, t3;
            pslldq.128 t3, 0x4;
            pxor  .128 t1, t3;
            pxor  .128 t1, t2;
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

aes128_encrypt_block :: (plaintext: *i128, key_schedule: [11]i128) -> cipher: i128 {
    text := plaintext.*;

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
