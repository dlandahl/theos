/*
 *  Copyright (C) 2017 - This file is part of libecc project
 *
 *  Authors:
 *      Ryad BENADJILA <ryadbenadjila@gmail.com>
 *      Arnaud EBALARD <arnaud.ebalard@ssi.gouv.fr>
 *      Jean-Pierre FLORI <jean-pierre.flori@ssi.gouv.fr>
 *
 *  Contributors:
 *      Nicolas VIVET <nicolas.vivet@ssi.gouv.fr>
 *      Karim KHALFALLAH <karim.khalfallah@ssi.gouv.fr>
 *
 *  This software is licensed under a dual BSD and GPL v2 license.
 *  See LICENSE file at the root folder of the project.
 */
#ifndef __LOGICAL_H__
#define __LOGICAL_H__
#include <libecc/nn/nn.h>
/*
 * Used for the get bit masking.
 */
#include <libecc/utils/utils_rand.h>

ATTRIBUTE_WARN_UNUSED_RET int nn_rshift_fixedlen(nn_t out, nn_src_t in, bitcnt_t cnt);
ATTRIBUTE_WARN_UNUSED_RET int nn_rshift(nn_t out, nn_src_t in, bitcnt_t cnt);
ATTRIBUTE_WARN_UNUSED_RET int nn_lshift_fixedlen(nn_t out, nn_src_t in, bitcnt_t cnt);
ATTRIBUTE_WARN_UNUSED_RET int nn_lshift(nn_t out, nn_src_t in, bitcnt_t cnt);
ATTRIBUTE_WARN_UNUSED_RET int nn_rrot(nn_t out, nn_src_t in, bitcnt_t cnt, bitcnt_t bitlen);
ATTRIBUTE_WARN_UNUSED_RET int nn_lrot(nn_t out, nn_src_t in, bitcnt_t cnt, bitcnt_t bitlen);
ATTRIBUTE_WARN_UNUSED_RET int nn_xor(nn_t B, nn_src_t C, nn_src_t A);
ATTRIBUTE_WARN_UNUSED_RET int nn_or(nn_t B, nn_src_t C, nn_src_t A);
ATTRIBUTE_WARN_UNUSED_RET int nn_and(nn_t B, nn_src_t C, nn_src_t A);
ATTRIBUTE_WARN_UNUSED_RET int nn_not(nn_t B, nn_src_t A);
ATTRIBUTE_WARN_UNUSED_RET int nn_clz(nn_src_t A, bitcnt_t *lz);
ATTRIBUTE_WARN_UNUSED_RET int nn_bitlen(nn_src_t A, bitcnt_t *blen);
ATTRIBUTE_WARN_UNUSED_RET int nn_getbit(nn_src_t in, bitcnt_t bit, u8 *bitval);
/*
 * This is a masked version to be used in sensitive contexts.
 * This directly returns the bit value after some masking.
 * The input retval contains the return status: 0 on success and -1 on error.
 * The output is meaningless in case of error.
 */
ATTRIBUTE_WARN_UNUSED_RET static inline word_t nn_getbit_masked(nn_src_t in, bitcnt_t bit, int *retval)
{
        bitcnt_t widx = bit / WORD_BITS;
        u8 bidx = bit % WORD_BITS;
        word_t r;
        /* NOTE: volatile to avoid optimization by the compiler */
        volatile word_t r_mask = 0;
        volatile word_t shift = 1;
        int ret;

        /* Sanity check */
        ret = nn_check_initialized(in); EG(ret, err);
        MUST_HAVE((bit < NN_MAX_BIT_LEN), ret, err);
        MUST_HAVE((retval != NULL), ret, err);

        /* Get a random value for masking */
        ret = get_unsafe_random((u8*)&r, sizeof(r));
        r_mask = r;

err:
        if(retval != NULL){
                (*retval) = ret;
        }
        if(!ret){
                /* bidx is less than WORD_BITS so shift operations below are ok */
                REGISTER word_t a = ((word_t)(in->val[widx] ^ r_mask) >> bidx);
                REGISTER word_t b = (word_t)(r_mask >> bidx);
                REGISTER word_t c = (word_t)((a >> shift) << shift);
                REGISTER word_t d = (word_t)((b >> shift) << shift);
                a ^= c;
                b ^= d;
                return (a ^ b);
        }
        else{
                return 0;
        }
}


#endif /* __LOGICAL_H__ */
