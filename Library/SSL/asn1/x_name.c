/* crypto/asn1/x_name.c */
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
#include "objects.h"
#include "asn1_mac.h"

/*
 * ASN1err(ASN1_F_D2I_X509_NAME,ASN1_R_LENGTH_MISMATCH);
 * ASN1err(ASN1_F_X509_NAME_NEW,ASN1_R_UNKNOWN_ATTRIBUTE_TYPE);
 * ASN1err(ASN1_F_D2I_X509_NAME_ENTRY,ASN1_R_LENGTH_MISMATCH);
 * ASN1err(ASN1_F_X509_NAME_ENTRY_NEW,ASN1_R_UNKNOWN_ATTRIBUTE_TYPE);
 */

#ifndef NOPROTO
static int i2d_X509_NAME_entries(X509_NAME *a);
#else
static int i2d_X509_NAME_entries();
#endif

int i2d_X509_NAME_ENTRY(a,pp)
X509_NAME_ENTRY *a;
unsigned char **pp;
	{
	M_ASN1_I2D_vars(a);

	M_ASN1_I2D_len(a->object,i2d_ASN1_OBJECT);
	M_ASN1_I2D_len(a->value,i2d_ASN1_PRINTABLE);

	M_ASN1_I2D_seq_total();

	M_ASN1_I2D_put(a->object,i2d_ASN1_OBJECT);
	M_ASN1_I2D_put(a->value,i2d_ASN1_PRINTABLE);

	M_ASN1_I2D_finish();
	}

X509_NAME_ENTRY *d2i_X509_NAME_ENTRY(a,pp,length)
X509_NAME_ENTRY **a;
unsigned char **pp;
long length;
	{
	M_ASN1_D2I_vars(a,X509_NAME_ENTRY *,X509_NAME_ENTRY_new);

	M_ASN1_D2I_Init();
	M_ASN1_D2I_start_sequence();
	M_ASN1_D2I_get(ret->object,d2i_ASN1_OBJECT);
	M_ASN1_D2I_get(ret->value,d2i_ASN1_PRINTABLE);
	ret->set=0;
	M_ASN1_D2I_Finish(a,X509_NAME_ENTRY_free,ASN1_F_D2I_X509_NAME_ENTRY);
	}

int i2d_X509_NAME(a,pp)
X509_NAME *a;
unsigned char **pp;
	{
	int ret;

	if (a == NULL) return(0);
	if (a->modified)
		{
		ret=i2d_X509_NAME_entries(a);
		if (ret < 0) return(ret);
		}

	ret=a->bytes->length;
	if (pp != NULL)
		{
		memcpy(*pp,a->bytes->data,ret);
		*pp+=ret;
		}
	return(ret);
	}

static int i2d_X509_NAME_entries(a)
X509_NAME *a;
	{
	X509_NAME_ENTRY *ne,*fe=NULL;
	STACK *sk;
	BUF_MEM *buf=NULL;
	int set=0,r,ret=0;
	int i;
	unsigned char *p;
	int size=0;

	sk=a->entries;
	for (i=0; i<sk_num(sk); i++)
		{
		ne=(X509_NAME_ENTRY *)sk_value(sk,i);
		if (fe == NULL)
			{
			fe=ne;
			size=0;
			}

		if (ne->set != set)
			{
			ret+=ASN1_object_size(1,size,V_ASN1_SET);
			fe->size=size;
			fe=ne;
			size=0;
			set=ne->set;
			}
		size+=i2d_X509_NAME_ENTRY(ne,NULL);
		}

	ret+=ASN1_object_size(1,size,V_ASN1_SET);
	if (fe != NULL)
		fe->size=size;

	r=ASN1_object_size(1,ret,V_ASN1_SEQUENCE);

	buf=a->bytes;
	if (!BUF_MEM_grow(buf,r)) goto err;
	p=(unsigned char *)buf->data;

	ASN1_put_object(&p,1,ret,V_ASN1_SEQUENCE,V_ASN1_UNIVERSAL);

	set= -1;
	for (i=0; i<sk_num(sk); i++)
		{
		ne=(X509_NAME_ENTRY *)sk_value(sk,i);
		if (set != ne->set)
			{
			set=ne->set;
			ASN1_put_object(&p,1,ne->size,
				V_ASN1_SET,V_ASN1_UNIVERSAL);
			}
		i2d_X509_NAME_ENTRY(ne,&p);
		}
	a->modified=0;
	return(r);
err:
	return(-1);
	}

X509_NAME *d2i_X509_NAME(a,pp,length)
X509_NAME **a;
unsigned char **pp;
long length;
	{
	int set=0,i;
	int idx=0;
	unsigned char *orig;
	M_ASN1_D2I_vars(a,X509_NAME *,X509_NAME_new);

	orig= *pp;
	if (sk_num(ret->entries) > 0)
		{
		while (sk_num(ret->entries) > 0)
			X509_NAME_ENTRY_free((X509_NAME_ENTRY *)
				sk_pop(ret->entries));
		}

	M_ASN1_D2I_Init();
	M_ASN1_D2I_start_sequence();
	for (;;)
		{
		if (M_ASN1_D2I_end_sequence()) break;
		M_ASN1_D2I_get_set(ret->entries,d2i_X509_NAME_ENTRY);
		for (; idx < sk_num(ret->entries); idx++)
			{
			((X509_NAME_ENTRY *)sk_value(ret->entries,idx))->set=
				set;
			}
		set++;
		}

	i=(int)(c.p-orig);
	if (!BUF_MEM_grow(ret->bytes,i)) goto err;
	memcpy(ret->bytes->data,orig,i);
	ret->bytes->length=i;
	ret->modified=0;

	M_ASN1_D2I_Finish(a,X509_NAME_free,ASN1_F_D2I_X509_NAME);
	}

X509_NAME *X509_NAME_new()
	{
	X509_NAME *ret=NULL;

	M_ASN1_New_Malloc(ret,X509_NAME);
	if ((ret->entries=sk_new(NULL)) == NULL) goto err2;
	M_ASN1_New(ret->bytes,BUF_MEM_new);
	ret->modified=1;
	return(ret);
	M_ASN1_New_Error(ASN1_F_X509_NAME_NEW);
	}

X509_NAME_ENTRY *X509_NAME_ENTRY_new()
	{
	X509_NAME_ENTRY *ret=NULL;

	M_ASN1_New_Malloc(ret,X509_NAME_ENTRY);
/*	M_ASN1_New(ret->object,ASN1_OBJECT_new);*/
	ret->object=NULL;
	ret->set=0;
	M_ASN1_New(ret->value,ASN1_STRING_new);
	return(ret);
	M_ASN1_New_Error(ASN1_F_X509_NAME_ENTRY_NEW);
	}

void X509_NAME_free(a)
X509_NAME *a;
	{
	BUF_MEM_free(a->bytes);
	sk_pop_free(a->entries,X509_NAME_ENTRY_free);
	Free((char *)a);
	}

void X509_NAME_ENTRY_free(a)
X509_NAME_ENTRY *a;
	{
	if (a == NULL) return;
	ASN1_OBJECT_free(a->object);
	ASN1_BIT_STRING_free(a->value);
	Free((char *)a);
	}

#ifndef GEOS_CLIENT

int X509_NAME_set(xn,name)
X509_NAME **xn;
X509_NAME *name;
	{
	X509_NAME *in;

	if (*xn == NULL) return(0);

	if (*xn != name)
		{
		in=X509_NAME_dup(name);
		if (in != NULL)
			{
			X509_NAME_free(*xn);
			*xn=in;
			}
		}
	return(*xn != NULL);
	}
	
#endif /* GEOS_CLIENT */

#endif