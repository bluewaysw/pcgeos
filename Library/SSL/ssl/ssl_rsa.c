/* ssl/ssl_rsa.c */
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

#include "bio.h"
#include "objects.h"
#include "evp.h"
#include "x509.h"
#include "pem.h"
#include "ssl_locl.h"

#ifndef COMPILE_OPTION_HOST_SERVICE_ONLY

#ifndef NOPROTO
static int ssl_set_cert(CERT *c, X509 *x509);
static int ssl_set_pkey(CERT *c, EVP_PKEY *pkey);
#else
static int ssl_set_cert();
static int ssl_set_pkey();
#endif

int SSL_use_certificate(ssl, x)
SSL *ssl;
X509 *x;
	{
	CERT *c;

	if (x == NULL)
		{
		SSLerr(SSL_F_SSL_USE_CERTIFICATE,ERR_R_PASSED_NULL_PARAMETER);
		return(0);
		}
	if ((ssl->cert == NULL) || (ssl->cert == ssl->ctx->default_cert))
		{
		c=ssl_cert_new();
		if (c == NULL)
			{
			SSLerr(SSL_F_SSL_USE_CERTIFICATE,ERR_R_MALLOC_FAILURE);
			return(0);
			}
		if (ssl->cert != NULL) ssl_cert_free(ssl->cert);
		ssl->cert=c;
		}
	c=ssl->cert;

	return(ssl_set_cert(c,x));
	}

#ifndef NO_STDIO
int SSL_use_certificate_file(ssl, file, type)
SSL *ssl;
char *file;
int type;
	{
	int j;
	BIO *in;
	int ret=0;
	X509 *x=NULL;

	in=BIO_new(BIO_s_file_internal());
	if (in == NULL)
		{
		SSLerr(SSL_F_SSL_USE_CERTIFICATE_FILE,ERR_R_BUF_LIB);
		goto end;
		}

	if (BIO_read_filename(in,file) <= 0)
		{
		SSLerr(SSL_F_SSL_USE_CERTIFICATE_FILE,ERR_R_SYS_LIB);
		goto end;
		}
	if (type == SSL_FILETYPE_ASN1)
		{
		j=ERR_R_ASN1_LIB;
		x=d2i_X509_bio(in,NULL);
		}
	else if (type == SSL_FILETYPE_PEM)
		{
		j=ERR_R_PEM_LIB;
		x=PEM_read_bio_X509(in,NULL,ssl->ctx->default_passwd_callback);
		}
	else
		{
		SSLerr(SSL_F_SSL_USE_CERTIFICATE_FILE,SSL_R_BAD_SSL_FILETYPE);
		goto end;
		}

	if (x == NULL)
		{
		SSLerr(SSL_F_SSL_USE_CERTIFICATE_FILE,j);
		goto end;
		}

	ret=SSL_use_certificate(ssl,x);
end:
	if (x != NULL) X509_free(x);
	if (in != NULL) BIO_free(in);
	return(ret);
	}
#endif

int SSL_use_certificate_ASN1(ssl, len, d)
SSL *ssl;
int len;
unsigned char *d;
	{
	X509 *x;
	int ret;

	x=d2i_X509(NULL,&d,(long)len);
	if (x == NULL)
		{
		SSLerr(SSL_F_SSL_USE_CERTIFICATE_ASN1,ERR_R_ASN1_LIB);
		return(0);
		}

	ret=SSL_use_certificate(ssl,x);
	X509_free(x);
	return(ret);
	}

#ifndef NO_RSA
int SSL_use_RSAPrivateKey(ssl, rsa)
SSL *ssl;
RSA *rsa;
	{
	CERT *c;
	EVP_PKEY *pkey;
	int ret;

	if (rsa == NULL)
		{
		SSLerr(SSL_F_SSL_USE_RSAPRIVATEKEY,ERR_R_PASSED_NULL_PARAMETER);
		return(0);
		}

        if ((ssl->cert == NULL) || (ssl->cert == ssl->ctx->default_cert))
                {
                c=ssl_cert_new();
		if (c == NULL)
			{
			SSLerr(SSL_F_SSL_USE_RSAPRIVATEKEY,ERR_R_MALLOC_FAILURE);
			return(0);
			}
                if (ssl->cert != NULL) ssl_cert_free(ssl->cert);
		ssl->cert=c;
		}
	c=ssl->cert;
	if ((pkey=EVP_PKEY_new()) == NULL)
		{
		SSLerr(SSL_F_SSL_USE_RSAPRIVATEKEY,ERR_R_EVP_LIB);
		return(0);
		}

	CRYPTO_add(&rsa->references,1,CRYPTO_LOCK_RSA);
	EVP_PKEY_assign_RSA(pkey,rsa);

	ret=ssl_set_pkey(c,pkey);
	EVP_PKEY_free(pkey);
	return(ret);
	}
#endif

static int ssl_set_pkey(c,pkey)
CERT *c;
EVP_PKEY *pkey;
	{
	int i,ok=0,bad=0;

	i=ssl_cert_type(NULL,pkey);
	if (i < 0)
		{
		SSLerr(SSL_F_SSL_SET_PKEY,SSL_R_UNKNOWN_CERTIFICATE_TYPE);
		return(0);
		}

	if (c->pkeys[i].x509 != NULL)
		{
#ifndef NO_RSA
		/* Don't check the public/private key, this is mostly
		 * for smart cards. */
		if ((pkey->type == EVP_PKEY_RSA) &&
			(RSA_flags(pkey->pkey.rsa) &
			 RSA_METHOD_FLAG_NO_CHECK))
			 ok=1;
		else
#endif
			if (!X509_check_private_key(c->pkeys[i].x509,pkey))
			{
			if ((i == SSL_PKEY_DH_RSA) || (i == SSL_PKEY_DH_DSA))
				{
				i=(i == SSL_PKEY_DH_RSA)?
					SSL_PKEY_DH_DSA:SSL_PKEY_DH_RSA;

				if (c->pkeys[i].x509 == NULL)
					ok=1;
				else
					{
					if (!X509_check_private_key(
						c->pkeys[i].x509,pkey))
						bad=1;
					else
						ok=1;
					}
				}
			else
				bad=1;
			}
		else
			ok=1;
		}
	else
		ok=1;

	if (bad)
		{
		X509_free(c->pkeys[i].x509);
		c->pkeys[i].x509=NULL;
		return(0);
		}

	if (c->pkeys[i].privatekey != NULL)
		EVP_PKEY_free(c->pkeys[i].privatekey);
	CRYPTO_add(&pkey->references,1,CRYPTO_LOCK_EVP_PKEY);
	c->pkeys[i].privatekey=pkey;
	c->key= &(c->pkeys[i]);

	c->valid=0;
	return(1);
	}

#ifndef NO_RSA
#ifndef NO_STDIO
int SSL_use_RSAPrivateKey_file(ssl, file, type)
SSL *ssl;
char *file;
int type;
	{
	int j,ret=0;
	BIO *in;
	RSA *rsa=NULL;

	in=BIO_new(BIO_s_file_internal());
	if (in == NULL)
		{
		SSLerr(SSL_F_SSL_USE_RSAPRIVATEKEY_FILE,ERR_R_BUF_LIB);
		goto end;
		}

	if (BIO_read_filename(in,file) <= 0)
		{
		SSLerr(SSL_F_SSL_USE_RSAPRIVATEKEY_FILE,ERR_R_SYS_LIB);
		goto end;
		}
	if	(type == SSL_FILETYPE_ASN1)
		{
		j=ERR_R_ASN1_LIB;
		rsa=d2i_RSAPrivateKey_bio(in,NULL);
		}
	else if (type == SSL_FILETYPE_PEM)
		{
		j=ERR_R_PEM_LIB;
		rsa=PEM_read_bio_RSAPrivateKey(in,NULL,
			ssl->ctx->default_passwd_callback);
		}
	else
		{
		SSLerr(SSL_F_SSL_USE_RSAPRIVATEKEY_FILE,SSL_R_BAD_SSL_FILETYPE);
		goto end;
		}
	if (rsa == NULL)
		{
		SSLerr(SSL_F_SSL_USE_RSAPRIVATEKEY_FILE,j);
		goto end;
		}
	ret=SSL_use_RSAPrivateKey(ssl,rsa);
	RSA_free(rsa);
end:
	if (in != NULL) BIO_free(in);
	return(ret);
	}
#endif

int SSL_use_RSAPrivateKey_ASN1(ssl,d,len)
SSL *ssl;
unsigned char *d;
long len;
	{
	int ret;
	unsigned char *p;
	RSA *rsa;

	p=d;
	if ((rsa=d2i_RSAPrivateKey(NULL,&p,(long)len)) == NULL)
		{
		SSLerr(SSL_F_SSL_USE_RSAPRIVATEKEY_ASN1,ERR_R_ASN1_LIB);
		return(0);
		}

	ret=SSL_use_RSAPrivateKey(ssl,rsa);
	RSA_free(rsa);
	return(ret);
	}
#endif /* !NO_RSA */

int SSL_use_PrivateKey(ssl, pkey)
SSL *ssl;
EVP_PKEY *pkey;
	{
	CERT *c;
	int ret;

	if (pkey == NULL)
		{
		SSLerr(SSL_F_SSL_USE_PRIVATEKEY,ERR_R_PASSED_NULL_PARAMETER);
		return(0);
		}

        if ((ssl->cert == NULL) || (ssl->cert == ssl->ctx->default_cert))
                {
                c=ssl_cert_new();
		if (c == NULL)
			{
			SSLerr(SSL_F_SSL_USE_PRIVATEKEY,ERR_R_MALLOC_FAILURE);
			return(0);
			}
                if (ssl->cert != NULL) ssl_cert_free(ssl->cert);
		ssl->cert=c;
		}
	c=ssl->cert;

	ret=ssl_set_pkey(c,pkey);
	return(ret);
	}

#ifndef NO_STDIO
int SSL_use_PrivateKey_file(ssl, file, type)
SSL *ssl;
char *file;
int type;
	{
	int j,ret=0;
	BIO *in;
	EVP_PKEY *pkey=NULL;

	in=BIO_new(BIO_s_file_internal());
	if (in == NULL)
		{
		SSLerr(SSL_F_SSL_USE_PRIVATEKEY_FILE,ERR_R_BUF_LIB);
		goto end;
		}

	if (BIO_read_filename(in,file) <= 0)
		{
		SSLerr(SSL_F_SSL_USE_PRIVATEKEY_FILE,ERR_R_SYS_LIB);
		goto end;
		}
	if (type == SSL_FILETYPE_PEM)
		{
		j=ERR_R_PEM_LIB;
		pkey=PEM_read_bio_PrivateKey(in,NULL,
			ssl->ctx->default_passwd_callback);
		}
	else
		{
		SSLerr(SSL_F_SSL_USE_PRIVATEKEY_FILE,SSL_R_BAD_SSL_FILETYPE);
		goto end;
		}
	if (pkey == NULL)
		{
		SSLerr(SSL_F_SSL_USE_PRIVATEKEY_FILE,j);
		goto end;
		}
	ret=SSL_use_PrivateKey(ssl,pkey);
	EVP_PKEY_free(pkey);
end:
	if (in != NULL) BIO_free(in);
	return(ret);
	}
#endif

int SSL_use_PrivateKey_ASN1(type,ssl,d,len)
int type;
SSL *ssl;
unsigned char *d;
long len;
	{
	int ret;
	unsigned char *p;
	EVP_PKEY *pkey;

	p=d;
	if ((pkey=d2i_PrivateKey(type,NULL,&p,(long)len)) == NULL)
		{
		SSLerr(SSL_F_SSL_USE_PRIVATEKEY_ASN1,ERR_R_ASN1_LIB);
		return(0);
		}

	ret=SSL_use_PrivateKey(ssl,pkey);
	EVP_PKEY_free(pkey);
	return(ret);
	}

int SSL_CTX_use_certificate(ctx, x)
SSL_CTX *ctx;
X509 *x;
	{
	CERT *c;

	if (x == NULL)
		{
		SSLerr(SSL_F_SSL_CTX_USE_CERTIFICATE,ERR_R_PASSED_NULL_PARAMETER);
		return(0);
		}

	if (ctx->default_cert == NULL)
		{
		c=ssl_cert_new();
		if (c == NULL)
			{
			SSLerr(SSL_F_SSL_CTX_USE_CERTIFICATE,ERR_R_MALLOC_FAILURE);
			return(0);
			}
		ctx->default_cert=c;
		}
	c=ctx->default_cert;

	return(ssl_set_cert(c,x));
	}

static int ssl_set_cert(c,x)
CERT *c;
X509 *x;
	{
	EVP_PKEY *pkey;
	int i,ok=0,bad=0;

	pkey=X509_get_pubkey(x);
	if (pkey == NULL)
		{
		SSLerr(SSL_F_SSL_SET_CERT,SSL_R_X509_LIB);
		return(0);
		}

	i=ssl_cert_type(x,pkey);
	if (i < 0)
		{
		SSLerr(SSL_F_SSL_SET_CERT,SSL_R_UNKNOWN_CERTIFICATE_TYPE);
		return(0);
		}

	if (c->pkeys[i].privatekey != NULL)
		{
		if (!X509_check_private_key(x,c->pkeys[i].privatekey))
			{
			if ((i == SSL_PKEY_DH_RSA) || (i == SSL_PKEY_DH_DSA))
				{
				i=(i == SSL_PKEY_DH_RSA)?
					SSL_PKEY_DH_DSA:SSL_PKEY_DH_RSA;

				if (c->pkeys[i].privatekey == NULL)
					ok=1;
				else
					{
					if (!X509_check_private_key(x,
						c->pkeys[i].privatekey))
						bad=1;
					else
						ok=1;
					}
				}
			else
				bad=1;
			}
		else
			ok=1;
		}
	else
		ok=1;

	if (bad)
		{
		EVP_PKEY_free(c->pkeys[i].privatekey);
		c->pkeys[i].privatekey=NULL;
		}

	if (c->pkeys[i].x509 != NULL)
		X509_free(c->pkeys[i].x509);
	CRYPTO_add(&x->references,1,CRYPTO_LOCK_X509);
	c->pkeys[i].x509=x;
	c->key= &(c->pkeys[i]);

	c->valid=0;
	return(1);
	}

#ifndef NO_STDIO
int SSL_CTX_use_certificate_file(ctx, file, type)
SSL_CTX *ctx;
char *file;
int type;
	{
	int j;
	BIO *in;
	int ret=0;
	X509 *x=NULL;

	in=BIO_new(BIO_s_file_internal());
	if (in == NULL)
		{
		SSLerr(SSL_F_SSL_CTX_USE_CERTIFICATE_FILE,ERR_R_BUF_LIB);
		goto end;
		}

	if (BIO_read_filename(in,file) <= 0)
		{
		SSLerr(SSL_F_SSL_CTX_USE_CERTIFICATE_FILE,ERR_R_SYS_LIB);
		goto end;
		}
	if (type == SSL_FILETYPE_ASN1)
		{
		j=ERR_R_ASN1_LIB;
		x=d2i_X509_bio(in,NULL);
		}
	else if (type == SSL_FILETYPE_PEM)
		{
		j=ERR_R_PEM_LIB;
		x=PEM_read_bio_X509(in,NULL,ctx->default_passwd_callback);
		}
	else
		{
		SSLerr(SSL_F_SSL_CTX_USE_CERTIFICATE_FILE,SSL_R_BAD_SSL_FILETYPE);
		goto end;
		}

	if (x == NULL)
		{
		SSLerr(SSL_F_SSL_CTX_USE_CERTIFICATE_FILE,j);
		goto end;
		}

	ret=SSL_CTX_use_certificate(ctx,x);
end:
	if (x != NULL) X509_free(x);
	if (in != NULL) BIO_free(in);
	return(ret);
	}
#endif

int SSL_CTX_use_certificate_ASN1(ctx, len, d)
SSL_CTX *ctx;
int len;
unsigned char *d;
	{
	X509 *x;
	int ret;

	x=d2i_X509(NULL,&d,(long)len);
	if (x == NULL)
		{
		SSLerr(SSL_F_SSL_CTX_USE_CERTIFICATE_ASN1,ERR_R_ASN1_LIB);
		return(0);
		}

	ret=SSL_CTX_use_certificate(ctx,x);
	X509_free(x);
	return(ret);
	}

#ifndef NO_RSA
int SSL_CTX_use_RSAPrivateKey(ctx, rsa)
SSL_CTX *ctx;
RSA *rsa;
	{
	int ret;
	CERT *c;
	EVP_PKEY *pkey;

	if (rsa == NULL)
		{
		SSLerr(SSL_F_SSL_CTX_USE_RSAPRIVATEKEY,ERR_R_PASSED_NULL_PARAMETER);
		return(0);
		}
	if (ctx->default_cert == NULL)
		{
		c=ssl_cert_new();
		if (c == NULL)
			{
			SSLerr(SSL_F_SSL_CTX_USE_RSAPRIVATEKEY,ERR_R_MALLOC_FAILURE);
			return(0);
			}
		ctx->default_cert=c;
		}
	c=ctx->default_cert;

	if ((pkey=EVP_PKEY_new()) == NULL)
		{
		SSLerr(SSL_F_SSL_CTX_USE_RSAPRIVATEKEY,ERR_R_EVP_LIB);
		return(0);
		}

	CRYPTO_add(&rsa->references,1,CRYPTO_LOCK_RSA);
	EVP_PKEY_assign_RSA(pkey,rsa);

	ret=ssl_set_pkey(c,pkey);
	EVP_PKEY_free(pkey);
	return(ret);
	}

#ifndef NO_STDIO
int SSL_CTX_use_RSAPrivateKey_file(ctx, file, type)
SSL_CTX *ctx;
char *file;
int type;
	{
	int j,ret=0;
	BIO *in;
	RSA *rsa=NULL;

	in=BIO_new(BIO_s_file_internal());
	if (in == NULL)
		{
		SSLerr(SSL_F_SSL_CTX_USE_RSAPRIVATEKEY_FILE,ERR_R_BUF_LIB);
		goto end;
		}

	if (BIO_read_filename(in,file) <= 0)
		{
		SSLerr(SSL_F_SSL_CTX_USE_RSAPRIVATEKEY_FILE,ERR_R_SYS_LIB);
		goto end;
		}
	if	(type == SSL_FILETYPE_ASN1)
		{
		j=ERR_R_ASN1_LIB;
		rsa=d2i_RSAPrivateKey_bio(in,NULL);
		}
	else if (type == SSL_FILETYPE_PEM)
		{
		j=ERR_R_PEM_LIB;
		rsa=PEM_read_bio_RSAPrivateKey(in,NULL,
			ctx->default_passwd_callback);
		}
	else
		{
		SSLerr(SSL_F_SSL_CTX_USE_RSAPRIVATEKEY_FILE,SSL_R_BAD_SSL_FILETYPE);
		goto end;
		}
	if (rsa == NULL)
		{
		SSLerr(SSL_F_SSL_CTX_USE_RSAPRIVATEKEY_FILE,j);
		goto end;
		}
	ret=SSL_CTX_use_RSAPrivateKey(ctx,rsa);
	RSA_free(rsa);
end:
	if (in != NULL) BIO_free(in);
	return(ret);
	}
#endif

int SSL_CTX_use_RSAPrivateKey_ASN1(ctx,d,len)
SSL_CTX *ctx;
unsigned char *d;
long len;
	{
	int ret;
	unsigned char *p;
	RSA *rsa;

	p=d;
	if ((rsa=d2i_RSAPrivateKey(NULL,&p,(long)len)) == NULL)
		{
		SSLerr(SSL_F_SSL_CTX_USE_RSAPRIVATEKEY_ASN1,ERR_R_ASN1_LIB);
		return(0);
		}

	ret=SSL_CTX_use_RSAPrivateKey(ctx,rsa);
	RSA_free(rsa);
	return(ret);
	}
#endif /* !NO_RSA */

int SSL_CTX_use_PrivateKey(ctx, pkey)
SSL_CTX *ctx;
EVP_PKEY *pkey;
	{
	CERT *c;

	if (pkey == NULL)
		{
		SSLerr(SSL_F_SSL_CTX_USE_PRIVATEKEY,ERR_R_PASSED_NULL_PARAMETER);
		return(0);
		}
		
	if (ctx->default_cert == NULL)
		{
		c=ssl_cert_new();
		if (c == NULL)
			{
			SSLerr(SSL_F_SSL_CTX_USE_PRIVATEKEY,ERR_R_MALLOC_FAILURE);
			return(0);
			}
		ctx->default_cert=c;
		}
	c=ctx->default_cert;

	return(ssl_set_pkey(c,pkey));
	}

#ifndef NO_STDIO
int SSL_CTX_use_PrivateKey_file(ctx, file, type)
SSL_CTX *ctx;
char *file;
int type;
	{
	int j,ret=0;
	BIO *in;
	EVP_PKEY *pkey=NULL;

	in=BIO_new(BIO_s_file_internal());
	if (in == NULL)
		{
		SSLerr(SSL_F_SSL_CTX_USE_PRIVATEKEY_FILE,ERR_R_BUF_LIB);
		goto end;
		}

	if (BIO_read_filename(in,file) <= 0)
		{
		SSLerr(SSL_F_SSL_CTX_USE_PRIVATEKEY_FILE,ERR_R_SYS_LIB);
		goto end;
		}
	if (type == SSL_FILETYPE_PEM)
		{
		j=ERR_R_PEM_LIB;
		pkey=PEM_read_bio_PrivateKey(in,NULL,
			ctx->default_passwd_callback);
		}
	else
		{
		SSLerr(SSL_F_SSL_CTX_USE_PRIVATEKEY_FILE,SSL_R_BAD_SSL_FILETYPE);
		goto end;
		}
	if (pkey == NULL)
		{
		SSLerr(SSL_F_SSL_CTX_USE_PRIVATEKEY_FILE,j);
		goto end;
		}
	ret=SSL_CTX_use_PrivateKey(ctx,pkey);
	EVP_PKEY_free(pkey);
end:
	if (in != NULL) BIO_free(in);
	return(ret);
	}
#endif

int SSL_CTX_use_PrivateKey_ASN1(type,ctx,d,len)
int type;
SSL_CTX *ctx;
unsigned char *d;
long len;
	{
	int ret;
	unsigned char *p;
	EVP_PKEY *pkey;

	p=d;
	if ((pkey=d2i_PrivateKey(type,NULL,&p,(long)len)) == NULL)
		{
		SSLerr(SSL_F_SSL_CTX_USE_PRIVATEKEY_ASN1,ERR_R_ASN1_LIB);
		return(0);
		}

	ret=SSL_CTX_use_PrivateKey(ctx,pkey);
	EVP_PKEY_free(pkey);
	return(ret);
	}

#endif

