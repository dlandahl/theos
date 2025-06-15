//
// This file was auto-generated using the following command:
//
// jai generate_bindings.jai
//



WORDSIZE :: 64;

NULL :: cast(*void) 0;

UINT8_MAX :: 0xff;
UINT16_MAX :: 0xffff;
UINT32_MAX :: 0xffffffff;
UINT64_MAX :: 0xffffffffffffffff;

WORD_BITS :: 64;
WORD_BYTES :: WORD_BITS / 8;
HWORD_BITS :: 32;
HWORD_BYTES :: HWORD_BITS / 8;

WORD_MAX :: UINT64_MAX;
HWORD_MAX :: UINT32_MAX;

PRIx16 :: "hx";

PRIx64 :: "llx";

PRIu16 :: "hu";

PRIu64 :: "llu";

WORD_MASK :: WORD_MAX;

HWORD_MASK :: HWORD_MAX;

CURVE_WEI25519_P_BITLEN :: 255;

CURVE_WEI25519_CURVE_ORDER_BITLEN :: 256;

CURVE_WEI25519_Q_BITLEN :: 253;

CURVES_MAX_P_BIT_LEN :: CURVE_WEI25519_P_BITLEN;

CURVES_MAX_Q_BIT_LEN :: CURVE_WEI25519_Q_BITLEN;

CURVES_MAX_CURVE_ORDER_BIT_LEN :: CURVE_WEI25519_CURVE_ORDER_BITLEN;

MAX_CURVE_OID_LEN :: 32;

SHA256_STATE_SIZE :: 8;
SHA256_BLOCK_SIZE :: 64;
SHA256_DIGEST_SIZE :: 32;
SHA256_DIGEST_SIZE_BITS :: 256;

MAX_DIGEST_SIZE :: SHA256_DIGEST_SIZE;

MAX_DIGEST_SIZE_BITS :: SHA256_DIGEST_SIZE_BITS;

MAX_BLOCK_SIZE :: SHA256_BLOCK_SIZE;

SHA256_HASH_MAGIC :: cast(word_t) (0x11299a2b32098412);

MAX_HASH_ALG_NAME_LEN :: 7;

NN_MAX_BASE :: CURVES_MAX_CURVE_ORDER_BIT_LEN;

NN_USABLE_MAX_BIT_LEN :: NN_MAX_BASE;

MAX_CURVE_NAME_LEN :: 32;

PRIV_KEY_MAGIC :: cast(word_t) (0x2feb91e938a4855d);

PUB_KEY_MAGIC :: cast(word_t) (0x31327f37741ffb76);

SIG_SIGN_MAGIC :: cast(word_t) (0x4ed73cfe4594dfd3);

SIG_VERIFY_MAGIC :: cast(word_t) (0x7e0d42d13e3159ba);

MAX_SIG_ALG_NAME_LEN :: 8;

X25519_SIZE :: 32;

X448_SIZE :: 56;

/* Sanity check on our guess for primitive types sizes.
* See https://barrgroup.com/Embedded-Systems/How-To/C-Fixed-Width-Integers-C99
*
* TODO: if you get a compilation error at this point, this means that we failed
* at guessing the C primitive types sizes for the current platform. You should
* try to adapt the uint8_t/uint16_t/uint32_t/uint64_t types definitions in this
* file, or find the C99 compliant stdint headers for your compiler/platform
* and include it.
*/
check_data_types :: union {
    uint8_t_incorrect:  [1] u8;
    uint16_t_incorrect: [1] u8;
    uint32_t_incorrect: [1] u8;
    uint64_t_incorrect: [1] u8;
}

word_t :: u64;
hword_t :: u32;

bitcnt_t :: u16;

/* Signature algorithm types */
ec_alg_type :: enum u32 {
    UNKNOWN_ALG :: 0;

    ECKCDSA     :: 2;

    X25519      :: 16;
}

/* Hash algorithm types */
hash_alg_type :: enum u32 {
    UNKNOWN_HASH_ALG :: 0;

    SHA256           :: 2;
}

/* All curves we support */
ec_curve_type :: enum u32 {
    UNKNOWN_CURVE :: 0;

    WEI25519      :: 14;
}

ec_str_param :: struct {
    buf:    *u8;
    buflen: u8;
}

ec_str_params :: struct {
    /*
    * Prime p:
    *  o p_bitlen = bitsizeof(p)
    */
    p:                *ec_str_param;
    p_bitlen:         *ec_str_param;

    /*
    * Precomputed Montgomery parameters:
    *  o r = 2^bitsizeof(p) mod p
    *  o r_square = 2^(2*bitsizeof(p)) mod p
    *  o mpinv = -p^-1 mod B
    * where B = 2^(bitsizeof(word_t))
    */
    r:                *ec_str_param;
    r_square:         *ec_str_param;
    mpinv:            *ec_str_param;

    /*
    * Precomputed division parameters:
    *  o p_shift = nn_clz(p)
    *  o p_normalized =  p << p_shift
    *  o p_reciprocal = floor(B^3/(DMSW(p_normalized) + 1)) - B
    * where B = 2^(bitsizeof(word_t))
    */
    p_shift:          *ec_str_param;
    p_normalized:     *ec_str_param;
    p_reciprocal:     *ec_str_param;

    /* Curve coefficients and number of points */
    a:                *ec_str_param;
    b:                *ec_str_param;
    curve_order:      *ec_str_param;

    /*
    * Projective coordinates of generator
    * and order and cofactor of associated subgroup.
    */
    gx:               *ec_str_param;
    gy:               *ec_str_param;
    gz:               *ec_str_param;
    gen_order:        *ec_str_param;
    gen_order_bitlen: *ec_str_param;
    cofactor:         *ec_str_param;

    /*
    * Optional transfert coefficients to Montgomery curve.
    */
    alpha_montgomery: *ec_str_param;
    gamma_montgomery: *ec_str_param;

    /*
    * Optional transfert coefficient to Edwards curve.
    */
    alpha_edwards:    *ec_str_param;

    /* OID and pretty name */
    oid:              *ec_str_param;
    name:             *ec_str_param;
}

ec_mapping :: struct {
    type:   ec_curve_type;
    params: *ec_str_params;
}

are_equal :: (a: *void, b: *void, len: u32, check: *s32) -> s32 #foreign libarith;
local_memcpy :: (dst: *void, src: *void, n: u32) -> s32 #foreign libarith;
local_memset :: (v: *void, c: u8, n: u32) -> s32 #foreign libarith;
are_str_equal :: (s1: *u8, s2: *u8, check: *s32) -> s32 #foreign libarith;
are_str_equal_nlen :: (s1: *u8, s2: *u8, maxlen: u32, check: *s32) -> s32 #foreign libarith;
local_strlen :: (s: *u8, len: *u32) -> s32 #foreign libarith;
local_strnlen :: (s: *u8, maxlen: u32, len: *u32) -> s32 #foreign libarith;
local_strncpy :: (dst: *u8, src: *u8, n: u32) -> s32 #foreign libarith;
local_strncat :: (dest: *u8, src: *u8, n: u32) -> s32 #foreign libarith;

sha256_context :: struct {
    /* Number of bytes processed */
    sha256_total:  u64;

    /* Internal state */
    sha256_state:  [8] u32;

    /* Internal buffer to handle updates in a block */
    sha256_buffer: [64] u8;

    /* Initialization magic value */
    magic:         word_t;
}

sha256_init :: (ctx: *sha256_context) -> s32 #foreign libsign;
sha256_update :: (ctx: *sha256_context, input: *u8, ilen: u32) -> s32 #foreign libsign;
sha256_final :: (ctx: *sha256_context, output: *[32] u8) -> s32 #foreign libsign;
sha256_scattered :: (inputs: **u8, ilens: *u32, output: *[32] u8) -> s32 #foreign libsign;

sha256 :: (input: *u8, ilen: u32, output: *[32] u8) -> s32 #foreign libsign;

hash_context :: union {
    sha256: sha256_context;
}

_hfunc_init :: #type (hctx: *hash_context) -> s32 #c_call;
_hfunc_update :: #type (hctx: *hash_context, chunk: *u8, chunklen: u32) -> s32 #c_call;

_hfunc_finalize :: #type (hctx: *hash_context, output: *u8) -> s32 #c_call;
_hfunc_scattered :: #type (inputs: **u8, ilens: *u32, output: *u8) -> s32 #c_call;

_sha256_init :: (hctx: *hash_context) -> s32 #foreign libsign;
_sha256_update :: (hctx: *hash_context, chunk: *u8, chunklen: u32) -> s32 #foreign libsign;
_sha256_final :: (hctx: *hash_context, output: *u8) -> s32 #foreign libsign;

/*
* All the hash algorithms we support are abstracted using the following
* structure (and following map) which provides for each hash alg its
* digest size, its block size and the associated scattered function.
*/
hash_mapping :: struct {
    type:            hash_alg_type;
    name:            *u8;
    digest_size:     u8;
    block_size:      u8;
    hfunc_init:      _hfunc_init;
    hfunc_update:    _hfunc_update;
    hfunc_finalize:  _hfunc_finalize;
    hfunc_scattered: _hfunc_scattered;
}

get_hash_by_name :: (hash_name: *u8, hm: **hash_mapping) -> s32 #foreign libsign;
get_hash_by_type :: (hash_type: hash_alg_type, hm: **hash_mapping) -> s32 #foreign libsign;
get_hash_sizes :: (hash_type: hash_alg_type, digest_size: *u8, block_size: *u8) -> s32 #foreign libsign;
hash_mapping_callbacks_sanity_check :: (h: *hash_mapping) -> s32 #foreign libsign;

nn_consistency_check_maxbitlen_256_wordsize_64_complete_formulas_32 :: () -> void #foreign libarith;

/*
* Our nn type contains an array of words, which is of a fixed given storage
* size defined in nn_lib_ecc_config.h.
*
* Each word in this array is in local endianness whereas the words
* in the array are ordered in a little endian way with regard to their
* indices. That is: the word at index 0 in the array contains the least
* significant word of the nn.
*
* Except explicitly specified (some functions may provide automatic
* initialization of output params), initialization is usually required
* before nn can be used.
*
* After initialization, the 'wlen' attribute provides at each moment
* an upper bound on the position of last non-zero word in the array.
* All words after that point are always guaranteed to be 0 after any
* manipulation by a function of this module.
* Functions use this assumption to optimize operations by avoiding to
* process leading zeros.
* Nevertheless, some functions still access words past the 'wlen' index
* and return correct results only if these words are 0.
*
* Note that functions with parameters not explicitly marked as const may
* modify the value of the 'wlen' attribute if they see fit.
* And indeed most of them set the output 'wlen' attribute to the maximal
* possible value given the inputs 'wlen' attributes.
* The most notable exceptions are the logical functions whose result
* depends on the preset value of the output 'wlen' attribute.
*/
nn :: struct {
    val:   [12] word_t;
    magic: word_t;
    wlen:  u8;
}

nn_t :: *nn;
nn_src_t :: *nn;

nn_check_initialized :: (A: nn_src_t) -> s32 #foreign libarith;

nn_zero :: (A: nn_t) -> s32 #foreign libarith;
nn_one :: (A: nn_t) -> s32 #foreign libarith;
nn_set_word_value :: (A: nn_t, val: word_t) -> s32 #foreign libarith;
nn_uninit :: (A: nn_t) -> void #foreign libarith;
nn_init :: (A: nn_t, len: u16) -> s32 #foreign libarith;
nn_init_from_buf :: (A: nn_t, buf: *u8, buflen: u16) -> s32 #foreign libarith;
nn_cnd_swap :: (cnd: s32, in1: nn_t, in2: nn_t) -> s32 #foreign libarith;
nn_set_wlen :: (A: nn_t, new_wlen: u8) -> s32 #foreign libarith;
nn_iszero :: (A: nn_src_t, iszero: *s32) -> s32 #foreign libarith;
nn_isone :: (A: nn_src_t, isone: *s32) -> s32 #foreign libarith;
nn_isodd :: (A: nn_src_t, isodd: *s32) -> s32 #foreign libarith;
nn_cmp_word :: (in: nn_src_t, w: word_t, cmp: *s32) -> s32 #foreign libarith;
nn_cmp :: (A: nn_src_t, B: nn_src_t, cmp: *s32) -> s32 #foreign libarith;
nn_copy :: (dst_nn: nn_t, src_nn: nn_src_t) -> s32 #foreign libarith;
nn_normalize :: (in1: nn_t) -> s32 #foreign libarith;
nn_export_to_buf :: (buf: *u8, buflen: u16, in_nn: nn_src_t) -> s32 #foreign libarith;
nn_tabselect :: (out: nn_t, idx: u8, tab: *nn_src_t, tabsize: u8) -> s32 #foreign libarith;

/* WARNING: use with care, this is useful when "fast" but somehow unsafe
* random must be provided.
*/
get_unsafe_random :: (buf: *u8, len: u16) -> s32 #foreign libarith;

nn_rshift_fixedlen :: (out: nn_t, in: nn_src_t, cnt: bitcnt_t) -> s32 #foreign libarith;
nn_rshift :: (out: nn_t, in: nn_src_t, cnt: bitcnt_t) -> s32 #foreign libarith;
nn_lshift_fixedlen :: (out: nn_t, in: nn_src_t, cnt: bitcnt_t) -> s32 #foreign libarith;
nn_lshift :: (out: nn_t, in: nn_src_t, cnt: bitcnt_t) -> s32 #foreign libarith;
nn_rrot :: (out: nn_t, in: nn_src_t, cnt: bitcnt_t, bitlen: bitcnt_t) -> s32 #foreign libarith;
nn_lrot :: (out: nn_t, in: nn_src_t, cnt: bitcnt_t, bitlen: bitcnt_t) -> s32 #foreign libarith;
nn_xor :: (B: nn_t, C: nn_src_t, A: nn_src_t) -> s32 #foreign libarith;
nn_or :: (B: nn_t, C: nn_src_t, A: nn_src_t) -> s32 #foreign libarith;
nn_and :: (B: nn_t, C: nn_src_t, A: nn_src_t) -> s32 #foreign libarith;
nn_not :: (B: nn_t, A: nn_src_t) -> s32 #foreign libarith;
nn_clz :: (A: nn_src_t, lz: *bitcnt_t) -> s32 #foreign libarith;
nn_bitlen :: (A: nn_src_t, blen: *bitcnt_t) -> s32 #foreign libarith;
nn_getbit :: (in: nn_src_t, bit: bitcnt_t, bitval: *u8) -> s32 #foreign libarith;

nn_cnd_add :: (cnd: s32, out: nn_t, in1: nn_src_t, in2: nn_src_t) -> s32 #foreign libarith;
nn_cnd_sub :: (cnd: s32, out: nn_t, in1: nn_src_t, in2: nn_src_t) -> s32 #foreign libarith;
nn_add :: (out: nn_t, in1: nn_src_t, in2: nn_src_t) -> s32 #foreign libarith;
nn_inc :: (out: nn_t, in1: nn_src_t) -> s32 #foreign libarith;
nn_sub :: (out: nn_t, in1: nn_src_t, in2: nn_src_t) -> s32 #foreign libarith;
nn_dec :: (out: nn_t, in1: nn_src_t) -> s32 #foreign libarith;
nn_mod_add :: (out: nn_t, in1: nn_src_t, in2: nn_src_t, p: nn_src_t) -> s32 #foreign libarith;
nn_mod_inc :: (out: nn_t, in1: nn_src_t, p: nn_src_t) -> s32 #foreign libarith;
nn_mod_sub :: (out: nn_t, in1: nn_src_t, in2: nn_src_t, p: nn_src_t) -> s32 #foreign libarith;
nn_mod_dec :: (out: nn_t, in1: nn_src_t, p: nn_src_t) -> s32 #foreign libarith;
nn_mod_neg :: (out: nn_t, in: nn_src_t, p: nn_src_t) -> s32 #foreign libarith;

nn_mul :: (out: nn_t, in1: nn_src_t, in2: nn_src_t) -> s32 #foreign libarith;
nn_sqr :: (out: nn_t, in: nn_src_t) -> s32 #foreign libarith;
nn_mul_word :: (out: nn_t, in: nn_src_t, w: word_t) -> s32 #foreign libarith;

nn_compute_redc1_coefs :: (r: nn_t, r_square: nn_t, p_in: nn_src_t, mpinv: *word_t) -> s32 #foreign libarith;

nn_mul_redc1 :: (out: nn_t, in1: nn_src_t, in2: nn_src_t, p: nn_src_t, mpinv: word_t) -> s32 #foreign libarith;

nn_mod_mul :: (out: nn_t, in1: nn_src_t, in2: nn_src_t, p: nn_src_t) -> s32 #foreign libarith;

/* Compute quotient q and remainder r for given a and b such that a = q*b + r */
nn_divrem :: (q: nn_t, r: nn_t, a: nn_src_t, b: nn_src_t) -> s32 #foreign libarith;

/* Compute r = a mod b */
nn_mod :: (r: nn_t, a: nn_src_t, b: nn_src_t) -> s32 #foreign libarith;

/* Compute gcd of a and b */
nn_gcd :: (d: nn_t, a: nn_src_t, b: nn_src_t, sign: *s32) -> s32 #foreign libarith;
nn_xgcd :: (g: nn_t, u: nn_t, v: nn_t, a: nn_src_t, b: nn_src_t, sign: *s32) -> s32 #foreign libarith;

nn_modinv :: (out: nn_t, x: nn_src_t, m: nn_src_t) -> s32 #foreign libarith;
nn_modinv_2exp :: (out: nn_t, in: nn_src_t, exp: bitcnt_t, in_isodd: *s32) -> s32 #foreign libarith;
nn_modinv_word :: (out: nn_t, w: word_t, m: nn_src_t) -> s32 #foreign libarith;
nn_modinv_fermat :: (out: nn_t, x: nn_src_t, p: nn_src_t) -> s32 #foreign libarith;
nn_modinv_fermat_redc :: (out: nn_t, x: nn_src_t, p: nn_src_t, r: nn_src_t, r_square: nn_src_t, mpinv: word_t) -> s32 #foreign libarith;

nn_mod_pow_redc :: (out: nn_t, base: nn_src_t, exp: nn_src_t, mod: nn_src_t, r: nn_src_t, r_square: nn_src_t, mpinv: word_t) -> s32 #foreign libarith;
nn_mod_pow :: (out: nn_t, base: nn_src_t, exp: nn_src_t, mod: nn_src_t) -> s32 #foreign libarith;

nn_get_random_len :: (out: nn_t, len: u16) -> s32 #foreign libarith;
nn_get_random_maxlen :: (out: nn_t, max_len: u16) -> s32 #foreign libarith;
nn_get_random_mod :: (out: nn_t, q: nn_src_t) -> s32 #foreign libarith;

nn_print :: (msg: *u8, a: nn_src_t) -> void #foreign libarith;

/*
* First, definition of our Fp context, containing all the elements
* needed to efficiently implement Fp operations.
*/
fp_ctx :: struct {
    /*
    * Value of p (extended by one word to handle
    * overflows in Fp). p_bitlen provides its
    * length in bit.
    */
    p:            nn;
    p_bitlen:     bitcnt_t;

    /* -p^-1 mod 2^(bitsizeof(word_t)) */
    mpinv:        word_t;

    /* 2^bitsizeof(p) mod p */
    r:            nn;

    /* 2^(2*bitsizeof(p)) mod p */
    r_square:     nn;

    /* clz(p) */
    p_shift:      bitcnt_t;

    /* p << p_shift */
    p_normalized: nn;

    /* floor(B^3/(DMSW(p_normalized) + 1)) - B */
    p_reciprocal: word_t;

    magic:        word_t;
}

fp_ctx_t :: *fp_ctx;
fp_ctx_src_t :: *fp_ctx;

fp_ctx_check_initialized :: (ctx: fp_ctx_src_t) -> s32 #foreign libarith;
fp_ctx_init :: (ctx: fp_ctx_t, p: nn_src_t, p_bitlen: bitcnt_t, r: nn_src_t, r_square: nn_src_t, mpinv: word_t, p_shift: bitcnt_t, p_normalized: nn_src_t, p_reciprocal: word_t) -> s32 #foreign libarith;

fp_ctx_init_from_p :: (ctx: fp_ctx_t, p: nn_src_t) -> s32 #foreign libarith;

/*
* Then the definition of our Fp elements
*/
fp :: struct {
    fp_val: nn;
    ctx:    fp_ctx_src_t;
    magic:  word_t;
}

fp_t :: *fp;
fp_src_t :: *fp;

fp_check_initialized :: (in: fp_src_t) -> s32 #foreign libarith;
fp_init :: (A: fp_t, fpctx: fp_ctx_src_t) -> s32 #foreign libarith;
fp_init_from_buf :: (A: fp_t, fpctx: fp_ctx_src_t, buf: *u8, buflen: u16) -> s32 #foreign libarith;
fp_uninit :: (A: fp_t) -> void #foreign libarith;
fp_set_nn :: (out: fp_t, in: nn_src_t) -> s32 #foreign libarith;
fp_zero :: (out: fp_t) -> s32 #foreign libarith;
fp_one :: (out: fp_t) -> s32 #foreign libarith;
fp_set_word_value :: (out: fp_t, val: word_t) -> s32 #foreign libarith;
fp_cmp :: (in1: fp_src_t, in2: fp_src_t, cmp: *s32) -> s32 #foreign libarith;
fp_iszero :: (in: fp_src_t, iszero: *s32) -> s32 #foreign libarith;
fp_copy :: (out: fp_t, in: fp_src_t) -> s32 #foreign libarith;
fp_tabselect :: (out: fp_t, idx: u8, tab: *fp_src_t, tabsize: u8) -> s32 #foreign libarith;
fp_eq_or_opp :: (in1: fp_src_t, in2: fp_src_t, eq_or_opp: *s32) -> s32 #foreign libarith;
fp_import_from_buf :: (out_fp: fp_t, buf: *u8, buflen: u16) -> s32 #foreign libarith;
fp_export_to_buf :: (buf: *u8, buflen: u16, in_fp: fp_src_t) -> s32 #foreign libarith;

fp_add :: (out: fp_t, in1: fp_src_t, in2: fp_src_t) -> s32 #foreign libarith;
fp_inc :: (out: fp_t, in: fp_src_t) -> s32 #foreign libarith;
fp_sub :: (out: fp_t, in1: fp_src_t, in2: fp_src_t) -> s32 #foreign libarith;
fp_dec :: (out: fp_t, in: fp_src_t) -> s32 #foreign libarith;
fp_neg :: (out: fp_t, in: fp_src_t) -> s32 #foreign libarith;

fp_mul :: (out: fp_t, in1: fp_src_t, in2: fp_src_t) -> s32 #foreign libarith;
fp_sqr :: (out: fp_t, in: fp_src_t) -> s32 #foreign libarith;
fp_inv :: (out: fp_t, in: fp_src_t) -> s32 #foreign libarith;
fp_inv_word :: (out: fp_t, w: word_t) -> s32 #foreign libarith;
fp_div :: (out: fp_t, num: fp_src_t, den: fp_src_t) -> s32 #foreign libarith;

fp_mul_redc1 :: (out: fp_t, in1: fp_src_t, in2: fp_src_t) -> s32 #foreign libarith;
fp_sqr_redc1 :: (out: fp_t, in: fp_src_t) -> s32 #foreign libarith;
fp_redcify :: (out: fp_t, in: fp_src_t) -> s32 #foreign libarith;
fp_unredcify :: (out: fp_t, in: fp_src_t) -> s32 #foreign libarith;

fp_add_monty :: (out: fp_t, in1: fp_src_t, in2: fp_src_t) -> s32 #foreign libarith;
fp_sub_monty :: (out: fp_t, in1: fp_src_t, in2: fp_src_t) -> s32 #foreign libarith;
fp_mul_monty :: (out: fp_t, in1: fp_src_t, in2: fp_src_t) -> s32 #foreign libarith;
fp_sqr_monty :: (out: fp_t, in: fp_src_t) -> s32 #foreign libarith;
fp_div_monty :: (out: fp_t, in1: fp_src_t, in2: fp_src_t) -> s32 #foreign libarith;

fp_pow :: (out: fp_t, base: fp_src_t, exp: nn_src_t) -> s32 #foreign libarith;

fp_sqrt :: (sqrt1: fp_t, sqrt2: fp_t, n: fp_src_t) -> s32 #foreign libarith;

fp_get_random :: (out: fp_t, ctx: fp_ctx_src_t) -> s32 #foreign libarith;

fp_ctx_print :: (msg: *u8, ctx: fp_ctx_src_t) -> void #foreign libarith;

fp_print :: (msg: *u8, a: fp_src_t) -> void #foreign libarith;

fp_print_all :: (msg: *u8, a: fp_src_t) -> void #foreign libarith;

ec_shortw_crv :: struct {
    a:        fp;
    b:        fp;
    a_monty:  fp;

    b3:       fp;
    b_monty:  fp;
    b3_monty: fp;

    order:    nn; /* curve order */
    magic:    word_t;
}

ec_shortw_crv_t :: *ec_shortw_crv;
ec_shortw_crv_src_t :: *ec_shortw_crv;

ec_shortw_crv_check_initialized :: (crv: ec_shortw_crv_src_t) -> s32 #foreign libec;
ec_shortw_crv_init :: (crv: ec_shortw_crv_t, a: fp_src_t, b: fp_src_t, order: nn_src_t) -> s32 #foreign libec;
ec_shortw_crv_uninit :: (crv: ec_shortw_crv_t) -> void #foreign libec;

ec_montgomery_crv :: struct {
    A:     fp;
    B:     fp;
    order: nn;
    magic: word_t;
}

ec_montgomery_crv_t :: *ec_montgomery_crv;
ec_montgomery_crv_src_t :: *ec_montgomery_crv;

ec_montgomery_crv_check_initialized :: (crv: ec_montgomery_crv_src_t) -> s32 #foreign libec;
ec_montgomery_crv_init :: (crv: ec_montgomery_crv_t, a: fp_src_t, b: fp_src_t, order: nn_src_t) -> s32 #foreign libec;
ec_montgomery_crv_uninit :: (crv: ec_montgomery_crv_t) -> void #foreign libec;

ec_edwards_crv :: struct {
    a:     fp;
    d:     fp;
    order: nn;
    magic: word_t;
}

ec_edwards_crv_t :: *ec_edwards_crv;
ec_edwards_crv_src_t :: *ec_edwards_crv;

ec_edwards_crv_check_initialized :: (crv: ec_edwards_crv_src_t) -> s32 #foreign libec;
ec_edwards_crv_init :: (crv: ec_edwards_crv_t, a: fp_src_t, b: fp_src_t, order: nn_src_t) -> s32 #foreign libec;
ec_edwards_crv_uninit :: (crv: ec_edwards_crv_t) -> void #foreign libec;

aff_pt :: struct {
    x:     fp;
    y:     fp;
    crv:   ec_shortw_crv_src_t;
    magic: word_t;
}

aff_pt_t :: *aff_pt;
aff_pt_src_t :: aff_pt_t;

aff_pt_check_initialized :: (in: aff_pt_src_t) -> s32 #foreign libec;
aff_pt_init :: (in: aff_pt_t, curve: ec_shortw_crv_src_t) -> s32 #foreign libec;
aff_pt_init_from_coords :: (in: aff_pt_t, curve: ec_shortw_crv_src_t, xcoord: fp_src_t, ycoord: fp_src_t) -> s32 #foreign libec;

aff_pt_uninit :: (in: aff_pt_t) -> void #foreign libec;
aff_pt_y_from_x :: (y1: fp_t, y2: fp_t, x: fp_src_t, curve: ec_shortw_crv_src_t) -> s32 #foreign libec;
is_on_shortw_curve :: (x: fp_src_t, y: fp_src_t, curve: ec_shortw_crv_src_t, on_curve: *s32) -> s32 #foreign libec;
aff_pt_is_on_curve :: (pt: aff_pt_src_t, on_curve: *s32) -> s32 #foreign libec;
ec_shortw_aff_copy :: (out: aff_pt_t, in: aff_pt_src_t) -> s32 #foreign libec;
ec_shortw_aff_cmp :: (in1: aff_pt_src_t, in2: aff_pt_src_t, cmp: *s32) -> s32 #foreign libec;
ec_shortw_aff_eq_or_opp :: (in1: aff_pt_src_t, in2: aff_pt_src_t, eq_or_opp: *s32) -> s32 #foreign libec;

aff_pt_import_from_buf :: (pt: aff_pt_t, pt_buf: *u8, pt_buf_len: u16, crv: ec_shortw_crv_src_t) -> s32 #foreign libec;

aff_pt_export_to_buf :: (pt: aff_pt_src_t, pt_buf: *u8, pt_buf_len: u32) -> s32 #foreign libec;

/*** Edwards curves related ***/
aff_pt_edwards :: struct {
    x:     fp;
    y:     fp;
    crv:   ec_edwards_crv_src_t;
    magic: word_t;
}

aff_pt_edwards_t :: *aff_pt_edwards;
aff_pt_edwards_src_t :: aff_pt_edwards_t;

aff_pt_edwards_check_initialized :: (in: aff_pt_edwards_src_t) -> s32 #foreign libec;
aff_pt_edwards_init :: (in: aff_pt_edwards_t, curve: ec_edwards_crv_src_t) -> s32 #foreign libec;
aff_pt_edwards_init_from_coords :: (in: aff_pt_edwards_t, curve: ec_edwards_crv_src_t, ucoord: fp_src_t, vcoord: fp_src_t) -> s32 #foreign libec;

aff_pt_edwards_uninit :: (in: aff_pt_edwards_t) -> void #foreign libec;
is_on_edwards_curve :: (u: fp_src_t, v: fp_src_t, curve: ec_edwards_crv_src_t, on_curve: *s32) -> s32 #foreign libec;
aff_pt_edwards_is_on_curve :: (pt: aff_pt_edwards_src_t, on_curve: *s32) -> s32 #foreign libec;
ec_edwards_aff_copy :: (out: aff_pt_edwards_t, in: aff_pt_edwards_src_t) -> s32 #foreign libec;
ec_edwards_aff_cmp :: (in1: aff_pt_edwards_src_t, in2: aff_pt_edwards_src_t, cmp: *s32) -> s32 #foreign libec;
aff_pt_edwards_import_from_buf :: (pt: aff_pt_edwards_t, pt_buf: *u8, pt_buf_len: u16, crv: ec_edwards_crv_src_t) -> s32 #foreign libec;

aff_pt_edwards_export_to_buf :: (pt: aff_pt_edwards_src_t, pt_buf: *u8, pt_buf_len: u32) -> s32 #foreign libec;

curve_edwards_to_montgomery :: (edwards_crv: ec_edwards_crv_src_t, montgomery_crv: ec_montgomery_crv_t, alpha_edwards: fp_src_t) -> s32 #foreign libec;
curve_edwards_montgomery_check :: (edwards_crv: ec_edwards_crv_src_t, montgomery_crv: ec_montgomery_crv_src_t, alpha_edwards: fp_src_t) -> s32 #foreign libec;

curve_montgomery_to_edwards :: (montgomery_crv: ec_montgomery_crv_src_t, edwards_crv: ec_edwards_crv_t, alpha_edwards: fp_src_t) -> s32 #foreign libec;

curve_edwards_to_shortw :: (edwards_crv: ec_edwards_crv_src_t, shortw_crv: ec_shortw_crv_t, alpha_edwards: fp_src_t) -> s32 #foreign libec;
curve_edwards_shortw_check :: (edwards_crv: ec_edwards_crv_src_t, shortw_crv: ec_shortw_crv_src_t, alpha_edwards: fp_src_t) -> s32 #foreign libec;
curve_shortw_to_edwards :: (shortw_crv: ec_shortw_crv_src_t, edwards_crv: ec_edwards_crv_t, alpha_montgomery: fp_src_t, gamma_montgomery: fp_src_t, alpha_edwards: fp_src_t) -> s32 #foreign libec;

aff_pt_edwards_to_shortw :: (in_edwards: aff_pt_edwards_src_t, shortw_crv: ec_shortw_crv_src_t, out_shortw: aff_pt_t, alpha_edwards: fp_src_t) -> s32 #foreign libec;
aff_pt_shortw_to_edwards :: (in_shortw: aff_pt_src_t, edwards_crv: ec_edwards_crv_src_t, out_edwards: aff_pt_edwards_t, alpha_edwards: fp_src_t) -> s32 #foreign libec;

aff_pt_edwards_y_from_x :: (y1: fp_t, y2: fp_t, x: fp_src_t, crv: ec_edwards_crv_src_t) -> s32 #foreign libec;
aff_pt_edwards_x_from_y :: (x1: fp_t, x2: fp_t, y: fp_src_t, crv: ec_edwards_crv_src_t) -> s32 #foreign libec;

/*** Montgomery curves related ***/
aff_pt_montgomery :: struct {
    u:     fp;
    v:     fp;
    crv:   ec_montgomery_crv_src_t;
    magic: word_t;
}

aff_pt_montgomery_t :: *aff_pt_montgomery;
aff_pt_montgomery_src_t :: aff_pt_montgomery_t;

aff_pt_montgomery_check_initialized :: (in: aff_pt_montgomery_src_t) -> s32 #foreign libec;
aff_pt_montgomery_init :: (in: aff_pt_montgomery_t, curve: ec_montgomery_crv_src_t) -> s32 #foreign libec;
aff_pt_montgomery_init_from_coords :: (in: aff_pt_montgomery_t, curve: ec_montgomery_crv_src_t, ucoord: fp_src_t, vcoord: fp_src_t) -> s32 #foreign libec;

aff_pt_montgomery_uninit :: (in: aff_pt_montgomery_t) -> void #foreign libec;
is_on_montgomery_curve :: (u: fp_src_t, v: fp_src_t, curve: ec_montgomery_crv_src_t, on_curve: *s32) -> s32 #foreign libec;
aff_pt_montgomery_is_on_curve :: (pt: aff_pt_montgomery_src_t, on_curve: *s32) -> s32 #foreign libec;
ec_montgomery_aff_copy :: (out: aff_pt_montgomery_t, in: aff_pt_montgomery_src_t) -> s32 #foreign libec;
ec_montgomery_aff_cmp :: (in1: aff_pt_montgomery_src_t, in2: aff_pt_montgomery_src_t, cmp: *s32) -> s32 #foreign libec;
aff_pt_montgomery_import_from_buf :: (pt: aff_pt_montgomery_t, pt_buf: *u8, pt_buf_len: u16, crv: ec_montgomery_crv_src_t) -> s32 #foreign libec;

aff_pt_montgomery_export_to_buf :: (pt: aff_pt_montgomery_src_t, pt_buf: *u8, pt_buf_len: u32) -> s32 #foreign libec;

curve_montgomery_to_shortw :: (montgomery_crv: ec_montgomery_crv_src_t, shortw_crv: ec_shortw_crv_t) -> s32 #foreign libec;

curve_montgomery_shortw_check :: (montgomery_crv: ec_montgomery_crv_src_t, shortw_crv: ec_shortw_crv_src_t) -> s32 #foreign libec;
curve_shortw_to_montgomery :: (shortw_crv: ec_shortw_crv_src_t, montgomery_crv: ec_montgomery_crv_t, alpha_montgomery: fp_src_t, gamma_montgomery: fp_src_t) -> s32 #foreign libec;

aff_pt_montgomery_to_shortw :: (in_montgomery: aff_pt_montgomery_src_t, shortw_crv: ec_shortw_crv_src_t, out_shortw: aff_pt_t) -> s32 #foreign libec;
aff_pt_shortw_to_montgomery :: (in_shortw: aff_pt_src_t, montgomery_crv: ec_montgomery_crv_src_t, out_montgomery: aff_pt_montgomery_t) -> s32 #foreign libec;

/*****/
aff_pt_edwards_to_montgomery :: (in_edwards: aff_pt_edwards_src_t, montgomery_crv: ec_montgomery_crv_src_t, out_montgomery: aff_pt_montgomery_t, alpha: fp_src_t) -> s32 #foreign libec;
aff_pt_montgomery_to_edwards :: (in_montgomery: aff_pt_montgomery_src_t, edwards_crv: ec_edwards_crv_src_t, out_edwards: aff_pt_edwards_t, alpha: fp_src_t) -> s32 #foreign libec;

aff_pt_montgomery_v_from_u :: (v1: fp_t, v2: fp_t, u: fp_src_t, crv: ec_montgomery_crv_src_t) -> s32 #foreign libec;

prj_pt :: struct {
    X:     fp;
    Y:     fp;
    Z:     fp;
    crv:   ec_shortw_crv_src_t;
    magic: word_t;
}

prj_pt_t :: *prj_pt;
prj_pt_src_t :: *prj_pt;

prj_pt_sensitivity :: enum u32 {
    PUBLIC_PT  :: 0;
    PRIVATE_PT :: 1;
}

prj_pt_check_initialized :: (in: prj_pt_src_t) -> s32 #foreign libec;
prj_pt_init :: (in: prj_pt_t, curve: ec_shortw_crv_src_t) -> s32 #foreign libec;
prj_pt_init_from_coords :: (in: prj_pt_t, curve: ec_shortw_crv_src_t, xcoord: fp_src_t, ycoord: fp_src_t, zcoord: fp_src_t) -> s32 #foreign libec;

prj_pt_uninit :: (in: prj_pt_t) -> void #foreign libec;
prj_pt_zero :: (out: prj_pt_t) -> s32 #foreign libec;
prj_pt_iszero :: (in: prj_pt_src_t, iszero: *s32) -> s32 #foreign libec;
prj_pt_is_on_curve :: (in: prj_pt_src_t, on_curve: *s32) -> s32 #foreign libec;
prj_pt_copy :: (out: prj_pt_t, in: prj_pt_src_t) -> s32 #foreign libec;
prj_pt_to_aff :: (out: aff_pt_t, in: prj_pt_src_t) -> s32 #foreign libec;
prj_pt_unique :: (out: prj_pt_t, in: prj_pt_src_t) -> s32 #foreign libec;
ec_shortw_aff_to_prj :: (out: prj_pt_t, in: aff_pt_src_t) -> s32 #foreign libec;
prj_pt_cmp :: (in1: prj_pt_src_t, in2: prj_pt_src_t, cmp: *s32) -> s32 #foreign libec;
prj_pt_eq_or_opp :: (in1: prj_pt_src_t, in2: prj_pt_src_t, eq_or_opp: *s32) -> s32 #foreign libec;
prj_pt_neg :: (out: prj_pt_t, in: prj_pt_src_t) -> s32 #foreign libec;
prj_pt_add :: (sum: prj_pt_t, in1: prj_pt_src_t, in2: prj_pt_src_t) -> s32 #foreign libec;
prj_pt_dbl :: (dbl: prj_pt_t, in: prj_pt_src_t) -> s32 #foreign libec;
prj_pt_mul :: (out: prj_pt_t, m: nn_src_t, in: prj_pt_src_t) -> s32 #foreign libec;
prj_pt_mul_blind :: (out: prj_pt_t, m: nn_src_t, in: prj_pt_src_t) -> s32 #foreign libec;

/* XXX: WARNING: this function must only be used on public points! */
_prj_pt_unprotected_mult :: (out: prj_pt_t, cofactor: nn_src_t, public_in: prj_pt_src_t) -> s32 #foreign libec;
check_prj_pt_order :: (in_shortw: prj_pt_src_t, in_isorder: nn_src_t, s: prj_pt_sensitivity, check: *s32) -> s32 #foreign libec;
prj_pt_import_from_buf :: (pt: prj_pt_t, pt_buf: *u8, pt_buf_len: u16, crv: ec_shortw_crv_src_t) -> s32 #foreign libec;

prj_pt_import_from_aff_buf :: (pt: prj_pt_t, pt_buf: *u8, pt_buf_len: u16, crv: ec_shortw_crv_src_t) -> s32 #foreign libec;

prj_pt_export_to_buf :: (pt: prj_pt_src_t, pt_buf: *u8, pt_buf_len: u32) -> s32 #foreign libec;
prj_pt_export_to_aff_buf :: (pt: prj_pt_src_t, pt_buf: *u8, pt_buf_len: u32) -> s32 #foreign libec;
aff_pt_edwards_to_prj_pt_shortw :: (in_edwards: aff_pt_edwards_src_t, shortw_crv: ec_shortw_crv_src_t, out_shortw: prj_pt_t, alpha: fp_src_t) -> s32 #foreign libec;

aff_pt_montgomery_to_prj_pt_shortw :: (in_montgomery: aff_pt_montgomery_src_t, shortw_crv: ec_shortw_crv_src_t, out_shortw: prj_pt_t) -> s32 #foreign libec;

prj_pt_shortw_to_aff_pt_edwards :: (in_shortw: prj_pt_src_t, edwards_crv: ec_edwards_crv_src_t, out_edwards: aff_pt_edwards_t, alpha: fp_src_t) -> s32 #foreign libec;

prj_pt_shortw_to_aff_pt_montgomery :: (in_shortw: prj_pt_src_t, montgomery_crv: ec_montgomery_crv_src_t, out_montgomery: aff_pt_montgomery_t) -> s32 #foreign libec;

/*
* Elliptic curves parameters. We only support
* curves defined on prime fields (i.e. Fp,
* with p prime).
*/
ec_params :: struct {
    /* Fp */
    ec_fp:               fp_ctx;

    /* Curve */
    ec_curve:            ec_shortw_crv;

    /*
    * Generator G defining our group, in projective
    * coordinates.
    */
    ec_gen:              prj_pt;

    /* Number of points on group generated by G */
    ec_gen_order:        nn;
    ec_gen_order_bitlen: bitcnt_t;

    /* Curve cofactor */
    ec_gen_cofactor:     nn;

    /* Optional transfer coefficients with Montgomery curves */
    ec_alpha_montgomery: fp;
    ec_gamma_montgomery: fp;

    /* Optional transfer coefficient with Edwards curves */
    ec_alpha_edwards:    fp;

    /* Object Identifier for the curve */
    curve_oid:           [32] u8;

    /* Short name for the curve */
    curve_name:          [32] u8;

    /* Type of the curve */
    curve_type:          ec_curve_type;
}

import_params :: (out_params: *ec_params, in_str_params: *ec_str_params) -> s32 #foreign libec;

ec_get_curve_params_by_name :: (ec_name: *u8, ec_name_len: u8, ec_params: **ec_str_params) -> s32 #foreign libec;

ec_get_curve_params_by_type :: (ec_type: ec_curve_type, ec_params: **ec_str_params) -> s32 #foreign libec;

ec_get_curve_type_by_name :: (ec_name: *u8, ec_name_len: u8, ec_type: *ec_curve_type) -> s32 #foreign libec;

ec_get_curve_name_by_type :: (ec_type: ec_curve_type, out: *u8, outlen: u8) -> s32 #foreign libec;
ec_check_curve_type_and_name :: (ec_type: ec_curve_type, ec_name: *u8, ec_name_len: u8) -> s32 #foreign libec;

ec_point_print :: (msg: *u8, prj_pt: prj_pt_src_t) -> void #foreign libec;

ec_montgomery_point_print :: (msg: *u8, pt: aff_pt_montgomery_src_t) -> void #foreign libec;

ec_edwards_point_print :: (msg: *u8, pt: aff_pt_edwards_src_t) -> void #foreign libec;

/* Enum for exported keys */
ec_key_type :: enum u32 {
    EC_PUBKEY  :: 0;
    EC_PRIVKEY :: 1;
}

ec_priv_key :: struct {
    /* A key type can only be used for a given sig alg */
    key_type: ec_alg_type;

    /* Elliptic curve parameters */
    params:   *ec_params;

    /*
    * Private key (usually an integer in ]0,q[, where q is
    * the order of G, the generator of the group
    * on the curve, or a derivative of this).
    *
    * For the specific case of EdDSA, this value will instead hold the
    * digest derivation of the secret value sk that is twice the size of
    * the digest size.
    */
    x:        nn;

    magic:    word_t;
}

priv_key_check_initialized :: (A: *ec_priv_key) -> s32 #foreign libsign;
priv_key_check_initialized_and_type :: (A: *ec_priv_key, sig_type: ec_alg_type) -> s32 #foreign libsign;

ec_priv_key_import_from_buf :: (priv_key: *ec_priv_key, params: *ec_params, priv_key_buf: *u8, priv_key_buf_len: u8, ec_key_alg: ec_alg_type) -> s32 #foreign libsign;

ec_priv_key_export_to_buf :: (priv_key: *ec_priv_key, priv_key_buf: *u8, priv_key_buf_len: u8) -> s32 #foreign libsign;

ec_structured_priv_key_import_from_buf :: (priv_key: *ec_priv_key, params: *ec_params, priv_key_buf: *u8, priv_key_buf_len: u8, ec_key_alg: ec_alg_type) -> s32 #foreign libsign;

ec_structured_priv_key_export_to_buf :: (priv_key: *ec_priv_key, priv_key_buf: *u8, priv_key_buf_len: u8) -> s32 #foreign libsign;

ec_pub_key :: struct {
    /* A key type can only be used for a given sig alg */
    key_type: ec_alg_type;

    /* Elliptic curve parameters */
    params:   *ec_params;

    /* Public key, i.e. y = xG mod p */
    y:        prj_pt;

    magic:    word_t;
}

pub_key_check_initialized :: (A: *ec_pub_key) -> s32 #foreign libsign;
pub_key_check_initialized_and_type :: (A: *ec_pub_key, sig_type: ec_alg_type) -> s32 #foreign libsign;

ec_pub_key_import_from_buf :: (pub_key: *ec_pub_key, params: *ec_params, pub_key_buf: *u8, pub_key_buf_len: u8, ec_key_alg: ec_alg_type) -> s32 #foreign libsign;

ec_pub_key_export_to_buf :: (pub_key: *ec_pub_key, pub_key_buf: *u8, pub_key_buf_len: u8) -> s32 #foreign libsign;

ec_pub_key_import_from_aff_buf :: (pub_key: *ec_pub_key, params: *ec_params, pub_key_buf: *u8, pub_key_buf_len: u8, ec_key_alg: ec_alg_type) -> s32 #foreign libsign;

ec_pub_key_export_to_aff_buf :: (pub_key: *ec_pub_key, pub_key_buf: *u8, pub_key_buf_len: u8) -> s32 #foreign libsign;

ec_structured_pub_key_import_from_buf :: (pub_key: *ec_pub_key, params: *ec_params, pub_key_buf: *u8, pub_key_buf_len: u8, ec_key_alg: ec_alg_type) -> s32 #foreign libsign;

ec_structured_pub_key_export_to_buf :: (pub_key: *ec_pub_key, pub_key_buf: *u8, pub_key_buf_len: u8) -> s32 #foreign libsign;

/*
* Declarations for EC key pairs
*/
ec_key_pair :: struct {
    priv_key: ec_priv_key;
    pub_key:  ec_pub_key;
}

key_pair_check_initialized :: (A: *ec_key_pair) -> s32 #foreign libsign;

key_pair_check_initialized_and_type :: (A: *ec_key_pair, sig_type: ec_alg_type) -> s32 #foreign libsign;

ec_key_pair_import_from_priv_key_buf :: (kp: *ec_key_pair, params: *ec_params, priv_key: *u8, priv_key_len: u8, ec_key_alg: ec_alg_type) -> s32 #foreign libsign;

ec_key_pair_gen :: (kp: *ec_key_pair, params: *ec_params, ec_key_alg: ec_alg_type) -> s32 #foreign libsign;

ec_structured_key_pair_import_from_priv_key_buf :: (kp: *ec_key_pair, params: *ec_params, priv_key_buf: *u8, priv_key_buf_len: u8, ec_key_alg: ec_alg_type) -> s32 #foreign libsign;

/*
* NOTE: please use the following API with care as it does not check the consistency
* between the private and public keys! On one side, this "saves" a costly
* scalar multiplication when there is confidence in the source of the buffers,
* but on the other side the user of the API MUST check the source (integrity)
* of the private/public key pair. If unsure, it is advised to use the
* ec_structured_key_pair_import_from_priv_key_buf API that safely derives the
* public key from the private key.
*
*/
ec_structured_key_pair_import_from_buf :: (kp: *ec_key_pair, params: *ec_params, priv_key_buf: *u8, priv_key_buf_len: u8, pub_key_buf: *u8, pub_key_buf_len: u8, ec_key_alg: ec_alg_type) -> s32 #foreign libsign;

generic_gen_priv_key :: (priv_key: *ec_priv_key) -> s32 #foreign libsign;

/* Type used for batch verification */
verify_batch_scratch_pad :: struct {
    number: nn;
    point:  prj_pt;
    index:  u32;
}

eckcdsa_init_pub_key :: (out_pub: *ec_pub_key, in_priv: *ec_priv_key) -> s32 #foreign libsign;

eckcdsa_siglen :: (p_bit_len: u16, q_bit_len: u16, hsize: u8, blocksize: u8, siglen: *u8) -> s32 #foreign libsign;

eckcdsa_sign_data :: struct {
    h_ctx: hash_context;
    magic: word_t;
}

_eckcdsa_sign_init :: (ctx: *ec_sign_context) -> s32 #foreign libsign;

_eckcdsa_sign_update :: (ctx: *ec_sign_context, chunk: *u8, chunklen: u32) -> s32 #foreign libsign;

_eckcdsa_sign_finalize :: (ctx: *ec_sign_context, sig: *u8, siglen: u8) -> s32 #foreign libsign;

eckcdsa_verify_data :: struct {
    h_ctx: hash_context;
    r:     [32] u8;
    s:     nn;
    magic: word_t;
}

_eckcdsa_verify_init :: (ctx: *ec_verify_context, sig: *u8, siglen: u8) -> s32 #foreign libsign;

_eckcdsa_verify_update :: (ctx: *ec_verify_context, chunk: *u8, chunklen: u32) -> s32 #foreign libsign;

_eckcdsa_verify_finalize :: (ctx: *ec_verify_context) -> s32 #foreign libsign;

/*
* All the signature algorithms we support are abstracted using the following
* structure (and following map) which provides for each hash alg its
* digest size, its block size and the associated scattered function.
*/
ec_sig_mapping :: struct {
    type:            ec_alg_type;
    name:            *u8;

    siglen:          #type (p_bit_len: u16, q_bit_len: u16, hsize: u8, blocksize: u8, siglen: *u8) -> s32 #c_call;

    gen_priv_key:    #type (priv_key: *ec_priv_key) -> s32 #c_call;
    init_pub_key:    #type (pub_key: *ec_pub_key, priv_key: *ec_priv_key) -> s32 #c_call;

    sign_init:       #type (ctx: *ec_sign_context) -> s32 #c_call;
    sign_update:     #type (ctx: *ec_sign_context, chunk: *u8, chunklen: u32) -> s32 #c_call;

    sign_finalize:   #type (ctx: *ec_sign_context, sig: *u8, siglen: u8) -> s32 #c_call;

    sign:            #type (sig: *u8, siglen: u8, key_pair: *ec_key_pair, m: *u8, mlen: u32, rand: #type (out: nn_t, q: nn_src_t) -> s32 #c_call, sig_type: ec_alg_type, hash_type: hash_alg_type, adata: *u8, adata_len: u16) -> s32 #c_call;

    verify_init:     #type (ctx: *ec_verify_context, sig: *u8, siglen: u8) -> s32 #c_call;

    verify_update:   #type (ctx: *ec_verify_context, chunk: *u8, chunklen: u32) -> s32 #c_call;

    verify_finalize: #type (ctx: *ec_verify_context) -> s32 #c_call;
    verify:          #type (sig: *u8, siglen: u8, pub_key: *ec_pub_key, m: *u8, mlen: u32, sig_type: ec_alg_type, hash_type: hash_alg_type, adata: *u8, adata_len: u16) -> s32 #c_call;

    verify_batch:    #type (s: **u8, s_len: *u8, pub_keys: **ec_pub_key, m: **u8, m_len: *u32, num: u32, sig_type: ec_alg_type, hash_type: hash_alg_type, adata: **u8, adata_len: *u16, scratch_pad_area: *verify_batch_scratch_pad, scratch_pad_area_len: *u32) -> s32 #c_call;
}

/*
* Each specific signature scheme need to maintain some specific
* data between calls to init()/update()/finalize() functions.
*
* Each scheme provides a specific structure for that purpose
* (in its .h file) which we include in the union below. A field
* of that type (.sign_data) is then included in the generic
* struct ec_sign_context below.
*
* The purpose of that work is to allow static declaration and
* allocation of common struct ec_sign_context with enough room
* available for all supported signature types.
*/
sig_sign_data :: union {
    eckcdsa: eckcdsa_sign_data;
}

/*
* The 'struct ec_sign_context' below provides a persistent state
* between successive calls to ec_sign_{init,update,finalize}().
*/
ec_sign_context :: struct {
    ctx_magic: word_t;
    key_pair:  *ec_key_pair;
    rand:      #type (out: nn_t, q: nn_src_t) -> s32 #c_call;
    h:         *hash_mapping;
    sig:       *ec_sig_mapping;

    sign_data: sig_sign_data;

    /* Optional ancillary data. This data is
    * optionnally used by the signature algorithm.
    */
    adata:     *u8;
    adata_len: u16;
}

sig_verify_data :: union {
    eckcdsa: eckcdsa_verify_data;
}

/*
* The 'struct ec_verify_context' below provides a persistent state
* between successive calls to ec_verify_{init,update,finalize}().
*/
ec_verify_context :: struct {
    ctx_magic:   word_t;
    pub_key:     *ec_pub_key;
    h:           *hash_mapping;
    sig:         *ec_sig_mapping;

    verify_data: sig_verify_data;

    /* Optional ancillary data. This data is
    * optionnally used by the signature algorithm.
    */
    adata:       *u8;
    adata_len:   u16;
}

/* Generic signature and verification APIs that will in fact call init / update / finalize in
* backend. Used for signature and verification functions that support these streaming APIs.
*
*/
generic_ec_sign :: (sig: *u8, siglen: u8, key_pair: *ec_key_pair, m: *u8, mlen: u32, rand: #type (out: nn_t, q: nn_src_t) -> s32 #c_call, sig_type: ec_alg_type, hash_type: hash_alg_type, adata: *u8, adata_len: u16) -> s32 #foreign libsign;

generic_ec_verify :: (sig: *u8, siglen: u8, pub_key: *ec_pub_key, m: *u8, mlen: u32, sig_type: ec_alg_type, hash_type: hash_alg_type, adata: *u8, adata_len: u16) -> s32 #foreign libsign;

/* Generic init / update / finalize functions returning an error and telling that they are
* unsupported.
*/
unsupported_sign_init :: (ctx: *ec_sign_context) -> s32 #foreign libsign;
unsupported_sign_update :: (ctx: *ec_sign_context, chunk: *u8, chunklen: u32) -> s32 #foreign libsign;

unsupported_sign_finalize :: (ctx: *ec_sign_context, sig: *u8, siglen: u8) -> s32 #foreign libsign;

is_sign_streaming_mode_supported :: (sig_type: ec_alg_type, check: *s32) -> s32 #foreign libsign;

unsupported_verify_init :: (ctx: *ec_verify_context, sig: *u8, siglen: u8) -> s32 #foreign libsign;

unsupported_verify_update :: (ctx: *ec_verify_context, chunk: *u8, chunklen: u32) -> s32 #foreign libsign;

unsupported_verify_finalize :: (ctx: *ec_verify_context) -> s32 #foreign libsign;

is_verify_streaming_mode_supported :: (sig_type: ec_alg_type, check: *s32) -> s32 #foreign libsign;

is_sign_deterministic :: (sig_type: ec_alg_type, check: *s32) -> s32 #foreign libsign;

is_verify_batch_mode_supported :: (sig_type: ec_alg_type, check: *s32) -> s32 #foreign libsign;

unsupported_verify_batch :: (s: **u8, s_len: *u8, pub_keys: **ec_pub_key, m: **u8, m_len: *u32, num: u32, sig_type: ec_alg_type, hash_type: hash_alg_type, adata: **u8, adata_len: *u16, scratch_pad_area: *verify_batch_scratch_pad, scratch_pad_area_len: *u32) -> s32 #foreign libsign;

/* Private key generation function specific to each scheme */
gen_priv_key :: (priv_key: *ec_priv_key) -> s32 #foreign libsign;

/*
* Generic function to init a uninitialized public key from an initialized
* private key. The function uses the expected logic to derive the key
* (e.g. Y=xG, Y=(x^-1)G, etc). It returns -1 on error (i.e. if the signature
* alg is unknown) in which case the public key has not been initialized.
*/
init_pubkey_from_privkey :: (pub_key: *ec_pub_key, priv_key: *ec_priv_key) -> s32 #foreign libsign;

get_sig_by_name :: (ec_sig_name: *u8, sig_mapping: **ec_sig_mapping) -> s32 #foreign libsign;
get_sig_by_type :: (sig_type: ec_alg_type, sig_mapping: **ec_sig_mapping) -> s32 #foreign libsign;

/* Sanity checks for calbacks */
ec_sig_mapping_callbacks_sanity_check :: (sig: *ec_sig_mapping) -> s32 #foreign libsign;
ec_sig_ctx_callbacks_sanity_check :: (sig_ctx: *ec_sign_context) -> s32 #foreign libsign;
ec_verify_ctx_callbacks_sanity_check :: (verify_ctx: *ec_verify_context) -> s32 #foreign libsign;

/*
* Compute generic effective signature length depending on the curve parameters,
* the signature algorithm and the hash function
*/
ec_get_sig_len :: (params: *ec_params, sig_type: ec_alg_type, hash_type: hash_alg_type, siglen: *u8) -> s32 #foreign libsign;

/* Generic signature init/update/finalize */
_ec_sign_init :: (ctx: *ec_sign_context, key_pair: *ec_key_pair, rand: #type (out: nn_t, q: nn_src_t) -> s32 #c_call, sig_type: ec_alg_type, hash_type: hash_alg_type, adata: *u8, adata_len: u16) -> s32 #foreign libsign;

ec_sign_init :: (ctx: *ec_sign_context, key_pair: *ec_key_pair, sig_type: ec_alg_type, hash_type: hash_alg_type, adata: *u8, adata_len: u16) -> s32 #foreign libsign;

ec_sign_update :: (ctx: *ec_sign_context, chunk: *u8, chunklen: u32) -> s32 #foreign libsign;

ec_sign_finalize :: (ctx: *ec_sign_context, sig: *u8, siglen: u8) -> s32 #foreign libsign;

_ec_sign :: (sig: *u8, siglen: u8, key_pair: *ec_key_pair, m: *u8, mlen: u32, rand: #type (out: nn_t, q: nn_src_t) -> s32 #c_call, sig_type: ec_alg_type, hash_type: hash_alg_type, adata: *u8, adata_len: u16) -> s32 #foreign libsign;

ec_sign :: (sig: *u8, siglen: u8, key_pair: *ec_key_pair, m: *u8, mlen: u32, sig_type: ec_alg_type, hash_type: hash_alg_type, adata: *u8, adata_len: u16) -> s32 #foreign libsign;

/* Generic signature verification init/update/finalize */
ec_verify_init :: (ctx: *ec_verify_context, pub_key: *ec_pub_key, sig: *u8, siglen: u8, sig_type: ec_alg_type, hash_type: hash_alg_type, adata: *u8, adata_len: u16) -> s32 #foreign libsign;

ec_verify_update :: (ctx: *ec_verify_context, chunk: *u8, chunklen: u32) -> s32 #foreign libsign;

ec_verify_finalize :: (ctx: *ec_verify_context) -> s32 #foreign libsign;

ec_verify :: (sig: *u8, siglen: u8, pub_key: *ec_pub_key, m: *u8, mlen: u32, sig_type: ec_alg_type, hash_type: hash_alg_type, adata: *u8, adata_len: u16) -> s32 #foreign libsign;

ec_verify_batch :: (s: **u8, s_len: *u8, pub_keys: **ec_pub_key, m: **u8, m_len: *u32, num: u32, sig_type: ec_alg_type, hash_type: hash_alg_type, adata: **u8, adata_len: *u16, scratch_pad_area: *verify_batch_scratch_pad, scratch_pad_area_len: *u32) -> s32 #foreign libsign;

/* Generic signature import and export functions */
ec_structured_sig_import_from_buf :: (sig: *u8, siglen: u32, out_buf: *u8, outlen: u32, sig_type: *ec_alg_type, hash_type: *hash_alg_type, curve_name: *[32] u8) -> s32 #foreign libsign;

ec_structured_sig_export_to_buf :: (sig: *u8, siglen: u32, out_buf: *u8, outlen: u32, sig_type: ec_alg_type, hash_type: hash_alg_type, curve_name: *[32] u8) -> s32 #foreign libsign;

ec_verify_bos_coster :: (elements: *verify_batch_scratch_pad, num: u32, bits: bitcnt_t) -> s32 #foreign libsign;

priv_key_print :: (msg: *u8, priv: *ec_priv_key) -> void #foreign libsign;

pub_key_print :: (msg: *u8, pub: *ec_pub_key) -> void #foreign libsign;

buf_print :: (msg: *u8, buf: *u8, buflen: u16) -> void #foreign libarith;

/* The X25519 function as specified in RFC7748.
*
* NOTE: the user of this primitive should be warned and aware that is is not fully compliant with the
* RFC7748 description as u coordinates on the quadratic twist of the curve are rejected as well as non
* canonical u.
* See the explanations in the implementation of the function for more context and explanations.
*/
x25519 :: (k: *[32] u8, u: *[32] u8, res: *[32] u8) -> s32 #foreign libsign;

x25519_gen_priv_key :: (priv_key: *[32] u8) -> s32 #foreign libsign;

x25519_init_pub_key :: (priv_key: *[32] u8, pub_key: *[32] u8) -> s32 #foreign libsign;

x25519_derive_secret :: (priv_key: *[32] u8, peer_pub_key: *[32] u8, shared_secret: *[32] u8) -> s32 #foreign libsign;

#scope_file

libarith :: #library,no_dll "./libarith";
libec :: #library,no_dll "./libec";
libsign :: #library,no_dll "./libsign";
