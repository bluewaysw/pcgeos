/* ssl/ssl_asn1.c */
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

#ifdef __GEOS__
#include <Ansi/stdio.h>
#else
#include <stdio.h>
#endif
#ifdef __GEOS__
#include <Ansi/stdlib.h>
#else
#include <stdlib.h>
#endif
#include "asn1_mac.h"
#include "objects.h"
#include "ssl_locl.h"

typedef struct ssl_session_asn1_st
	{
	ASN1_INTEGER version;
	ASN1_INTEGER ssl_version;
	ASN1_OCTET_STRING cipher;
	ASN1_OCTET_STRING master_key;
	ASN1_OCTET_STRING session_id;
	ASN1_OCTET_STRING key_arg;
	ASN1_INTEGER time;
	ASN1_INTEGER timeout;
	} SSL_SESSION_ASN1;

/*
 * SSLerr(SSL_F_I2D_SSL_SESSION,SSL_R_CIPHER_CODE_WRONG_LENGTH);
 * SSLerr(SSL_F_D2I_SSL_SESSION,SSL_R_UNSUPPORTED_CIPHER);
 */

 #ifndef COMPILE_OPTION_HOST_SERVICE_ONLY


int i2d_SSL_SESSION(in,pp)
SSL_SESSION *in;
unsigned char **pp;
	{
#define LSIZE2 (sizeof(long)*2)
	int v1=0,v2=0,v3=0;
	unsigned char buf[4],ibuf1[LSIZE2],ibuf2[LSIZE2];
	unsigned char ibuf3[LSIZE2],ibuf4[LSIZE2];
	long l;
	SSL_SESSION_ASN1 a;
	M_ASN1_I2D_vars(in);

	if ((in == NULL) || ((in->cipher == NULL) && (in->cipher_id == 0)))
		return(0);

	/* Note that I cheat in the following 2 assignments.  I know
	 * that if the ASN1_INTERGER passed to ASN1_INTEGER_set
	 * is > sizeof(long)+1, the buffer will not be re-Malloc()ed.
	 * This is a bit evil but makes things simple, no dynamic allocation
	 * to clean up :-) */
	a.version.length=LSIZE2;
	a.version.type=V_ASN1_INTEGER;
	a.version.data=ibuf1;
	ASN1_INTEGER_set(&(a.version),SSL_SESSION_ASN1_VERSION);

	a.ssl_version.length=LSIZE2;
	a.ssl_version.type=V_ASN1_INTEGER;
	a.ssl_version.data=ibuf2;
	ASN1_INTEGER_set(&(a.ssl_version),in->ssl_version);

	a.cipher.type=V_ASN1_OCTET_STRING;
	a.cipher.data=buf;

	if (in->cipher == NULL)
		l=in->cipher_id;
	else
		l=in->cipher->id;
	if (in->ssl_version == SSL2_VERSION)
		{
		a.cipher.length=3;
		buf[0]=((unsigned char)(l>>16L))&0xff;
		buf[1]=((unsigned char)(l>> 8L))&0xff;
		buf[2]=((unsigned char)(l     ))&0xff;
		}
	else
		{
		a.cipher.length=2;
		buf[0]=((unsigned char)(l>>8L))&0xff;
		buf[1]=((unsigned char)(l    ))&0xff;
		}

	a.master_key.length=in->master_key_length;
	a.master_key.type=V_ASN1_OCTET_STRING;
	a.master_key.data=in->master_key;

	a.session_id.length=in->session_id_length;
	a.session_id.type=V_ASN1_OCTET_STRING;
	a.session_id.data=in->session_id;

	a.key_arg.length=in->key_arg_length;
	a.key_arg.type=V_ASN1_OCTET_STRING;
	a.key_arg.data=in->key_arg;

	if (in->time != 0L)
		{
		a.time.length=LSIZE2;
		a.time.type=V_ASN1_INTEGER;
		a.time.data=ibuf3;
		ASN1_INTEGER_set(&(a.time),in->time);
		}

	if (in->timeout != 0L)
		{
		a.timeout.length=LSIZE2;
		a.timeout.type=V_ASN1_INTEGER;
		a.timeout.data=ibuf4;
		ASN1_INTEGER_set(&(a.timeout),in->timeout);
		}

	M_ASN1_I2D_len(&(a.version),		i2d_ASN1_INTEGER);
	M_ASN1_I2D_len(&(a.ssl_version),	i2d_ASN1_INTEGER);
	M_ASN1_I2D_len(&(a.cipher),		i2d_ASN1_OCTET_STRING);
	M_ASN1_I2D_len(&(a.session_id),		i2d_ASN1_OCTET_STRING);
	M_ASN1_I2D_len(&(a.master_key),		i2d_ASN1_OCTET_STRING);
	if (in->key_arg_length > 0)
		M_ASN1_I2D_len_IMP_opt(&(a.key_arg),i2d_ASN1_OCTET_STRING);
	if (in->time != 0L)
		M_ASN1_I2D_len_EXP_opt(&(a.time),i2d_ASN1_INTEGER,1,v1);
	if (in->timeout != 0L)
		M_ASN1_I2D_len_EXP_opt(&(a.timeout),i2d_ASN1_INTEGER,2,v2);
	if (in->peer != NULL)
		M_ASN1_I2D_len_EXP_opt(in->peer,i2d_X509,3,v3);

	M_ASN1_I2D_seq_total();

	M_ASN1_I2D_put(&(a.version),		i2d_ASN1_INTEGER);
	M_ASN1_I2D_put(&(a.ssl_version),	i2d_ASN1_INTEGER);
	M_ASN1_I2D_put(&(a.cipher),		i2d_ASN1_OCTET_STRING);
	M_ASN1_I2D_put(&(a.session_id),		i2d_ASN1_OCTET_STRING);
	M_ASN1_I2D_put(&(a.master_key),		i2d_ASN1_OCTET_STRING);
	if (in->key_arg_length > 0)
		M_ASN1_I2D_put_IMP_opt(&(a.key_arg),i2d_ASN1_OCTET_STRING,0);
	if (in->time != 0L)
		M_ASN1_I2D_put_EXP_opt(&(a.time),i2d_ASN1_INTEGER,1,v1);
	if (in->timeout != 0L)
		M_ASN1_I2D_put_EXP_opt(&(a.timeout),i2d_ASN1_INTEGER,2,v2);
	if (in->peer != NULL)
		M_ASN1_I2D_put_EXP_opt(in->peer,i2d_X509,3,v3);

	M_ASN1_I2D_finish();
	}

SSL_SESSION *d2i_SSL_SESSION(a,pp,length)
SSL_SESSION **a;
unsigned char **pp;
long length;
	{
	int version,ssl_version=0,i;
	long id;
	ASN1_INTEGER ai,*aip;
	ASN1_OCTET_STRING os,*osp;
	M_ASN1_D2I_vars(a,SSL_SESSION *,SSL_SESSION_new);

	aip= &ai;
	osp= &os;

	M_ASN1_D2I_Init();
	M_ASN1_D2I_start_sequence();

	ai.data=NULL; ai.length=0;
	M_ASN1_D2I_get(aip,d2i_ASN1_INTEGER);
	version=(int)ASN1_INTEGER_get(aip);
	if (ai.data != NULL) { Free(ai.data); ai.data=NULL; ai.length=0; }

	/* we don't care about the version right now :-) */
	M_ASN1_D2I_get(aip,d2i_ASN1_INTEGER);
	ssl_version=(int)ASN1_INTEGER_get(aip);
	ret->ssl_version=ssl_version;
	if (ai.data != NULL) { Free(ai.data); ai.data=NULL; ai.length=0; }

	os.data=NULL; os.length=0;
	M_ASN1_D2I_get(osp,d2i_ASN1_OCTET_STRING);
	if (ssl_version == SSL2_VERSION)
		{
		if (os.length != 3)
			{
			c.error=SSL_R_CIPHER_CODE_WRONG_LENGTH;
			goto err;
			}
		id=0x02000000L|
			((unsigned long)os.data[0]<<16L)|
			((unsigned long)os.data[1]<< 8L)|
			 (unsigned long)os.data[2];
		}
	else if ((ssl_version>>8) == 3)
		{
		if (os.length != 2)
			{
			c.error=SSL_R_CIPHER_CODE_WRONG_LENGTH;
			goto err;
			}
		id=0x03000000L|
			((unsigned long)os.data[0]<<8L)|
			 (unsigned long)os.data[1];
		}
	else
		{
		SSLerr(SSL_F_D2I_SSL_SESSION,SSL_R_UNKNOWN_SSL_VERSION);
		return(NULL);
		}
	
	ret->cipher=NULL;
	ret->cipher_id=id;

	M_ASN1_D2I_get(osp,d2i_ASN1_OCTET_STRING);
	if ((ssl_version>>8) == SSL3_VERSION)
		i=SSL3_MAX_SSL_SESSION_ID_LENGTH;
	else /* if (ssl_version == SSL2_VERSION) */
		i=SSL2_MAX_SSL_SESSION_ID_LENGTH;

	if (os.length > i)
		os.length=i;

	ret->session_id_length=os.length;
	memcpy(ret->session_id,os.data,os.length);

	M_ASN1_D2I_get(osp,d2i_ASN1_OCTET_STRING);
	if (ret->master_key_length > SSL_MAX_MASTER_KEY_LENGTH)
		ret->master_key_length=SSL_MAX_MASTER_KEY_LENGTH;
	else
		ret->master_key_length=os.length;
	memcpy(ret->master_key,os.data,ret->master_key_length);

	os.length=0;
	M_ASN1_D2I_get_IMP_opt(osp,d2i_ASN1_OCTET_STRING,0,V_ASN1_OCTET_STRING);
	if (os.length > SSL_MAX_KEY_ARG_LENGTH)
		ret->key_arg_length=SSL_MAX_KEY_ARG_LENGTH;
	else
		ret->key_arg_length=os.length;
	memcpy(ret->key_arg,os.data,ret->key_arg_length);
	if (os.data != NULL) Free(os.data);

	ai.length=0;
	M_ASN1_D2I_get_EXP_opt(aip,d2i_ASN1_INTEGER,1);
	if (ai.data != NULL)
		{
		ret->time=ASN1_INTEGER_get(aip);
		Free(ai.data); ai.data=NULL; ai.length=0;
		}
	else
#ifdef __GEOS__
		ret->time=TimerGetCount();
#else
		ret->time=time(NULL);
#endif

	ai.length=0;
	M_ASN1_D2I_get_EXP_opt(aip,d2i_ASN1_INTEGER,2);
	if (ai.data != NULL)
		{
		ret->timeout=ASN1_INTEGER_get(aip);
		Free(ai.data); ai.data=NULL; ai.length=0;
		}
	else
		ret->timeout=3;

	if (ret->peer != NULL)
		{
		X509_free(ret->peer);
		ret->peer=NULL;
		}
	M_ASN1_D2I_get_EXP_opt(ret->peer,d2i_X509,3);

	M_ASN1_D2I_Finish(a,SSL_SESSION_free,SSL_F_D2I_SSL_SESSION);
	}

#endif
