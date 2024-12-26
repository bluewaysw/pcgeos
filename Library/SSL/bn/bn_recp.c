/* crypto/bn/bn_recp.c */
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

int BN_mod_mul_reciprocal(r, x, y, m, i, nb, ctx)
BIGNUM *r;
BIGNUM *x;
BIGNUM *y;
BIGNUM *m;
BIGNUM *i;
int nb;
BN_CTX *ctx;
	{
	int ret=0,j;
	BIGNUM *a,*b,*c,*d;

	a=ctx->bn[ctx->tos++];
	b=ctx->bn[ctx->tos++];
	c=ctx->bn[ctx->tos++];
	d=ctx->bn[ctx->tos++];

	if (x == y)
		{ if (!BN_sqr(a,x,ctx)) goto err; }
	else
		{ if (!BN_mul(a,x,y)) goto err; }
	if (!BN_rshift(d,a,nb)) goto err;
	if (!BN_mul(b,d,i)) goto err;
	if (!BN_rshift(c,b,nb)) goto err;
	if (!BN_mul(b,m,c)) goto err;
	if (!BN_sub(r,a,b)) goto err;
	j=0;
	while (BN_cmp(r,m) >= 0)
		{
		if (j++ > 2)
			{
			BNerr(BN_F_BN_MOD_MUL_RECIPROCAL,BN_R_BAD_RECIPROCAL);
			goto err;
			}
		if (!BN_sub(r,r,m)) goto err;
		}

	ret=1;
err:
	ctx->tos-=4;
	return(ret);
	}

int BN_reciprocal(r, m,ctx)
BIGNUM *r;
BIGNUM *m;
BN_CTX *ctx;
	{
	int nm,ret= -1;
	BIGNUM *t;

	t=ctx->bn[ctx->tos++];

	nm=BN_num_bits(m);
	if (!BN_lshift(t,BN_value_one(),nm*2)) goto err;

	if (!BN_div(r,NULL,t,m,ctx)) goto err;
	ret=nm;
err:
	ctx->tos--;
	return(ret);
	}

#endif
