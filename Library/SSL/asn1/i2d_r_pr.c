/* crypto/asn1/i2d_r_pr.c */
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
#include "bn.h"
#include "rsa.h"
#include "objects.h"
#include "asn1_mac.h"

/*
 * ASN1err(ASN1_F_D2I_RSAPRIVATEKEY,ASN1_R_LENGTH_MISMATCH);
 * ASN1err(ASN1_F_I2D_RSAPRIVATEKEY,ASN1_R_UNKNOWN_ATTRIBUTE_TYPE);
 */

int i2d_RSAPrivateKey(a,pp)
RSA *a;
unsigned char **pp;
	{
	BIGNUM *num[9];
	unsigned char data[1];
	ASN1_INTEGER bs;
	unsigned int j,i,tot,t,len,max=0;
	unsigned char *p;

	if (a == NULL) return(0);

	num[1]=a->n;
	num[2]=a->e;
	num[3]=a->d;
	num[4]=a->p;
	num[5]=a->q;
	num[6]=a->dmp1;
	num[7]=a->dmq1;
	num[8]=a->iqmp;

	bs.length=1;
	bs.data=data;
	bs.type=V_ASN1_INTEGER;
	data[0]=a->version&0x7f;

	tot=i2d_ASN1_INTEGER(&(bs),NULL);
	for (i=1; i<9; i++)
		{
		j=BN_num_bits(num[i]);
		len=((j == 0)?0:((j/8)+1));
		if (len > max) max=len;
		len=ASN1_object_size(0,len,
			(num[i]->neg)?V_ASN1_NEG_INTEGER:V_ASN1_INTEGER);
		tot+=len;
		}

	t=ASN1_object_size(1,tot,V_ASN1_SEQUENCE);
	if (pp == NULL) return(t);

	p= *pp;
	ASN1_put_object(&p,1,tot,V_ASN1_SEQUENCE,V_ASN1_UNIVERSAL);

	i2d_ASN1_INTEGER(&bs,&p);

	bs.data=(unsigned char *)Malloc(max+4);
	if (bs.data == NULL)
		{
		ASN1err(ASN1_F_I2D_RSAPRIVATEKEY,ERR_R_MALLOC_FAILURE);
		return(-1);
		}

	for (i=1; i<9; i++)
		{
		bs.length=BN_bn2bin(num[i],bs.data);
		i2d_ASN1_INTEGER(&bs,&p);
		}
	Free((char *)bs.data);
	*pp=p;
	return(t);
	}

#endif
