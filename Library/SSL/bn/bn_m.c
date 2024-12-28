/* crypto/bn/bn_m.c */
/* Copyright (C) 1995-1998 Eric Young (eay@cryptsoft.com)
 * All rights reserved.
 *
 * This package is an SSL implementation written
 * by Eric Young (eay@cryptsoft.com).
 * The implementation was written so as to conform with Netscapes SSL.
 * 
 * This library is free for commercial and non-commercial use as long as
 * the following conditions are aheared to.  The following conditions
 * apply to all code found in this distribution, be it the RC4, RSA,
 * lhash, DES, etc., code; not just the SSL code.  The SSL documentation
 * included with this distribution is covered by the same copyright terms
 * except that the holder is Tim Hudson (tjh@cryptsoft.com).
 * 
 * Copyright remains Eric Young's, and as such any Copyright notices in
 * the code are not to be removed.
 * If this package is used in a product, Eric Young should be given attribution
 * as the author of the parts of the library used.
 * This can be in the form of a textual message at program startup or
 * in documentation (online or textual) provided with the package.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. All advertising materials mentioning features or use of this software
 *    must display the following acknowledgement:
 *    "This product includes cryptographic software written by
 *     Eric Young (eay@cryptsoft.com)"
 *    The word 'cryptographic' can be left out if the rouines from the library
 *    being used are not cryptographic related :-).
 * 4. If you include any Windows specific code (or a derivative thereof) from 
 *    the apps directory (application code) you must include an acknowledgement:
 *    "This product includes software written by Tim Hudson (tjh@cryptsoft.com)"
 * 
 * THIS SOFTWARE IS PROVIDED BY ERIC YOUNG ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 * 
 * The licence and distribution terms for any publically available version or
 * derivative of this code cannot be changed.  i.e. this code cannot simply be
 * copied and put under another distribution licence
 * [including the GNU Public Licence.]
 */

#ifndef COMPILE_OPTION_HOST_SERVICE_ONLY

#ifdef __GEOS__
#include <Ansi/stdio.h>
#else
#include <stdio.h>
#endif
#include "cryptlib.h"
#include "bn_lcl.h"
#include "stack.h"

int limit=16;

typedef struct bn_pool_st
	{
	int used;
	int tos;
	STACK *sk; 
	} BN_POOL;

BIGNUM *BN_POOL_push(bp)
BN_POOL *bp;
	{
	BIGNUM *ret;

	if (bp->used >= bp->tos)
		{
		ret=BN_new();
		sk_push(bp->sk,(char *)ret);
		bp->tos++;
		bp->used++;
		}
	else
		{
		ret=(BIGNUM *)sk_value(bp->sk,bp->used);
		bp->used++;
		}
	return(ret);
	}

void BN_POOL_pop(bp,num)
BN_POOL *bp;
int num;
	{
	bp->used-=num;
	}

int BN_m(r,a,b)
BIGNUM *r,*a,*b;
	{
	static BN_POOL bp;
	static initBNm=1;
#ifdef __GEOS__
	int ret;
#endif

	PUSHDS;
	if (initBNm)
		{
		bp.used=0;
		bp.tos=0;
		bp.sk=sk_new_null();
		initBNm=0;
		}
#ifdef __GEOS__
	ret = BN_mm(r,a,b,&bp);
	POPDS;
	return(ret);
#else
	return(BN_mm(r,a,b,&bp));
#endif
	}

/* r must be different to a and b */
int BN_mm(m, A, B, bp)
BIGNUM *m,*A,*B;
BN_POOL *bp;
	{
	int i,num;
	int an,bn;
	BIGNUM *a,*b,*c,*d,*ac,*bd;

	an=A->top;
	bn=B->top;
	if ((an <= limit) || (bn <= limit))
		{
		return(BN_mul(m,A,B));
		}

	a=BN_POOL_push(bp);
	b=BN_POOL_push(bp);
	c=BN_POOL_push(bp);
	d=BN_POOL_push(bp);
	ac=BN_POOL_push(bp);
	bd=BN_POOL_push(bp);

	num=(an <= bn)?an:bn;
	num=1<<(BN_num_bits_word(num-1)-1);

	/* Are going to now chop things into 'num' word chunks. */
	num*=BN_BITS2;

	BN_copy(a,A);
	BN_mask_bits(a,num);
	BN_rshift(b,A,num);

	BN_copy(c,B);
	BN_mask_bits(c,num);
	BN_rshift(d,B,num);

	BN_sub(ac ,b,a);
	BN_sub(bd,c,d);
	BN_mm(m,ac,bd,bp);
	BN_mm(ac,a,c,bp);
	BN_mm(bd,b,d,bp);

	BN_add(m,m,ac);
	BN_add(m,m,bd);
	BN_lshift(m,m,num);
	BN_lshift(bd,bd,num*2);

	BN_add(m,m,ac);
	BN_add(m,m,bd);
	BN_POOL_pop(bp,6);
	return(1);
	}

#endif
