/* crypto/x509/x509_vfy.c */
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
#ifdef __GEOS__
#include <timedate.h>
#else
#include <time.h>
#endif
#include <errno.h>
#include <sys/types.h>
#include <sys/stat.h>

#include "crypto.h"
#include "cryptlib.h"
#include "lhash.h"
#include "buffer.h"
#include "evp.h"
#include "asn1.h"
#include "x509.h"
#include "objects.h"
#include "pem.h"

#ifndef NOPROTO
static int null_callback(int ok,X509_STORE_CTX *e);
static int internal_verify(X509_STORE_CTX *ctx);
#else
static int null_callback();
static int internal_verify();
#endif

#ifndef GEOS_CLIENT
char *X509_version="X509 part of SSLeay 0.9.0b 29-Jun-1998";
#endif
static STACK *x509_store_ctx_method=NULL;
static int x509_store_ctx_num=0;
#if 0
static int x509_store_num=1;
static STACK *x509_store_method=NULL;
#endif

static int null_callback(ok,e)
int ok;
X509_STORE_CTX *e;
	{
	return(ok);
	}

#if 0
static int x509_subject_cmp(a,b)
X509 **a,**b;
	{
	return(X509_subject_name_cmp(*a,*b));
	}
#endif

int X509_verify_cert(ctx)
X509_STORE_CTX *ctx;
	{
	X509 *x,*xtmp,*chain_ss=NULL;
	X509_NAME *xn;
	X509_OBJECT obj;
	int depth,i,ok=0;
	int num;
	int (*cb)();
	STACK *sktmp=NULL;

	if (ctx->cert == NULL)
		{
		X509err(X509_F_X509_VERIFY_CERT,X509_R_NO_CERT_SET_FOR_US_TO_VERIFY);
		return(-1);
		}

	cb=ctx->ctx->verify_cb;
	if (cb == NULL) cb=null_callback;

	/* first we make sure the chain we are going to build is
	 * present and that the first entry is in place */
	if (ctx->chain == NULL)
		{
		if (	((ctx->chain=sk_new_null()) == NULL) ||
			(!sk_push(ctx->chain,(char *)ctx->cert)))
			{
			X509err(X509_F_X509_VERIFY_CERT,ERR_R_MALLOC_FAILURE);
			goto end;
			}
		CRYPTO_add(&ctx->cert->references,1,CRYPTO_LOCK_X509);
		ctx->last_untrusted=1;
		}

	/* We use a temporary so we can chop and hack at it */
	if ((ctx->untrusted != NULL) && (sktmp=sk_dup(ctx->untrusted)) == NULL)
		{
		X509err(X509_F_X509_VERIFY_CERT,ERR_R_MALLOC_FAILURE);
		goto end;
		}

	num=sk_num(ctx->chain);
	x=(X509 *)sk_value(ctx->chain,num-1);
	depth=ctx->depth;


	for (;;)
		{
		/* If we have enough, we break */
		if (depth <= num) break;

		/* If we are self signed, we break */
		xn=X509_get_issuer_name(x);
		if (X509_NAME_cmp(X509_get_subject_name(x),xn) == 0)
			break;

		/* If we were passed a cert chain, use it first */
		if (ctx->untrusted != NULL)
			{
			xtmp=X509_find_by_subject(sktmp,xn);
			if (xtmp != NULL)
				{
				if (!sk_push(ctx->chain,(char *)xtmp))
					{
					X509err(X509_F_X509_VERIFY_CERT,ERR_R_MALLOC_FAILURE);
					goto end;
					}
				CRYPTO_add(&xtmp->references,1,CRYPTO_LOCK_X509);
				sk_delete_ptr(sktmp,(char *)xtmp);
				ctx->last_untrusted++;
				x=xtmp;
				num++;
				/* reparse the full chain for
				 * the next one */
				continue;
				}
			}
		break;
		}

	/* at this point, chain should contain a list of untrusted
	 * certificates.  We now need to add at least one trusted one,
	 * if possible, otherwise we complain. */

	i=sk_num(ctx->chain);
	x=(X509 *)sk_value(ctx->chain,i-1);
	if (X509_NAME_cmp(X509_get_subject_name(x),X509_get_issuer_name(x))
		== 0)
		{
		/* we have a self signed certificate */
		if (sk_num(ctx->chain) == 1)
			{
			ctx->error=X509_V_ERR_DEPTH_ZERO_SELF_SIGNED_CERT;
			ctx->current_cert=x;
			ctx->error_depth=i-1;
#ifdef __GEOS__
			ok=CALLCB2(cb,0,ctx);
#else
			ok=cb(0,ctx);
#endif
			if (!ok) goto end;
			}
		else
			{
			/* worry more about this one elsewhere */
			chain_ss=(X509 *)sk_pop(ctx->chain);
			ctx->last_untrusted--;
			num--;
			x=(X509 *)sk_value(ctx->chain,num-1);
			}
		}

	/* We now lookup certs from the certificate store */
	for (;;)
		{
		/* If we have enough, we break */
		if (depth <= num) break;

		/* If we are self signed, we break */
		xn=X509_get_issuer_name(x);
		if (X509_NAME_cmp(X509_get_subject_name(x),xn) == 0)
			break;

		ok=X509_STORE_get_by_subject(ctx,X509_LU_X509,xn,&obj);
		if (ok != X509_LU_X509)
			{
			if (ok == X509_LU_RETRY)
				{
				X509_OBJECT_free_contents(&obj);
				X509err(X509_F_X509_VERIFY_CERT,X509_R_SHOULD_RETRY);
				return(ok);
				}
			else if (ok != X509_LU_FAIL)
				{
				X509_OBJECT_free_contents(&obj);
				/* not good :-(, break anyway */
				return(ok);
				}
			break;
			}
		x=obj.data.x509;
		if (!sk_push(ctx->chain,(char *)obj.data.x509))
			{
			X509_OBJECT_free_contents(&obj);
			X509err(X509_F_X509_VERIFY_CERT,ERR_R_MALLOC_FAILURE);
			return(0);
			}
		num++;
		}

	/* we now have our chain, lets check it... */
	xn=X509_get_issuer_name(x);
	if (X509_NAME_cmp(X509_get_subject_name(x),xn) != 0)
		{
		if ((chain_ss == NULL) || (X509_NAME_cmp(X509_get_subject_name(chain_ss),xn) != 0))
			{
			if (ctx->last_untrusted >= num)
				ctx->error=X509_V_ERR_UNABLE_TO_GET_ISSUER_CERT_LOCALLY;
			else
				ctx->error=X509_V_ERR_UNABLE_TO_GET_ISSUER_CERT;
			ctx->current_cert=x;
			}
		else
			{

			sk_push(ctx->chain,(char *)chain_ss);
			num++;
			ctx->last_untrusted=num;
			ctx->current_cert=chain_ss;
			ctx->error=X509_V_ERR_SELF_SIGNED_CERT_IN_CHAIN;
			chain_ss=NULL;
			}

		ctx->error_depth=num-1;
#ifdef __GEOS__
		ok=CALLCB2(cb,0,ctx);
#else
		ok=cb(0,ctx);
#endif
		if (!ok) goto end;
		}

	/* We may as well copy down any DSA parameters that are required */
	X509_get_pubkey_parameters(NULL,ctx->chain);

	/* At this point, we have a chain and just need to verify it */
	if (ctx->ctx->verify != NULL)
		ok=ctx->ctx->verify(ctx);
	else
		ok=internal_verify(ctx);
end:
	if (sktmp != NULL) sk_free(sktmp);
	if (chain_ss != NULL) X509_free(chain_ss);
	return(ok);
	}

static int internal_verify(ctx)
X509_STORE_CTX *ctx;
	{
	int i,ok=0,n;
	X509 *xs,*xi;
	EVP_PKEY *pkey=NULL;
	int (*cb)();

	cb=ctx->ctx->verify_cb;
	if (cb == NULL) cb=null_callback;

	n=sk_num(ctx->chain);
	ctx->error_depth=n-1;
	n--;
	xi=(X509 *)sk_value(ctx->chain,n);
	if (X509_NAME_cmp(X509_get_subject_name(xi),
		X509_get_issuer_name(xi)) == 0)
		xs=xi;
	else
		{
		if (n <= 0)
			{
			ctx->error=X509_V_ERR_UNABLE_TO_VERIFY_LEAF_SIGNATURE;
			ctx->current_cert=xi;
#ifdef __GEOS__
			ok=CALLCB2(cb,0,ctx);
#else
			ok=cb(0,ctx);
#endif
			goto end;
			}
		else
			{
			n--;
			ctx->error_depth=n;
			xs=(X509 *)sk_value(ctx->chain,n);
			}
		}

/*	ctx->error=0;  not needed */
	while (n >= 0)
		{
		ctx->error_depth=n;
		if (!xs->valid)
			{
			if ((pkey=X509_get_pubkey(xi)) == NULL)
				{
				ctx->error=X509_V_ERR_UNABLE_TO_DECODE_ISSUER_PUBLIC_KEY;
				ctx->current_cert=xi;
#ifdef __GEOS__
				ok=CALLCB2(cb,0,ctx);
#else
				ok=(*cb)(0,ctx);
#endif
				if (!ok) goto end;
				}
			if (X509_verify(xs,pkey) <= 0)
				{
				ctx->error=X509_V_ERR_CERT_SIGNATURE_FAILURE;
				ctx->current_cert=xs;
#ifdef __GEOS__
				ok=CALLCB2(cb,0,ctx);
#else
				ok=(*cb)(0,ctx);
#endif
				if (!ok) goto end;
				}
			pkey=NULL;

			i=X509_cmp_current_time(X509_get_notBefore(xs));
			if (i == 0)
				{
				ctx->error=X509_V_ERR_ERROR_IN_CERT_NOT_BEFORE_FIELD;
				ctx->current_cert=xs;
#ifdef __GEOS__
				ok=CALLCB2(cb,0,ctx);
#else
				ok=(*cb)(0,ctx);
#endif
				if (!ok) goto end;
				}
			if (i > 0)
				{
				ctx->error=X509_V_ERR_CERT_NOT_YET_VALID;
				ctx->current_cert=xs;
#ifdef __GEOS__
				ok=CALLCB2(cb,0,ctx);
#else
				ok=(*cb)(0,ctx);
#endif
				if (!ok) goto end;
				}
			xs->valid=1;
			}

		i=X509_cmp_current_time(X509_get_notAfter(xs));
		if (i == 0)
			{
			ctx->error=X509_V_ERR_ERROR_IN_CERT_NOT_AFTER_FIELD;
			ctx->current_cert=xs;
#ifdef __GEOS__
			ok=CALLCB2(*cb,0,ctx);
#else
			ok=(*cb)(0,ctx);
#endif
			if (!ok) goto end;
			}

		if (i < 0)
			{
			ctx->error=X509_V_ERR_CERT_HAS_EXPIRED;
			ctx->current_cert=xs;
#ifdef __GEOS__
			ok=CALLCB2(cb,0,ctx);
#else
			ok=(*cb)(0,ctx);
#endif
			if (!ok) goto end;
			}

		/* CRL CHECK */

		/* The last error (if any) is still in the error value */
		ctx->current_cert=xs;
#ifdef __GEOS__
		ok=CALLCB2(cb,1,ctx);
#else
		ok=(*cb)(1,ctx);
#endif
		if (!ok) goto end;

		n--;
		if (n >= 0)
			{
			xi=xs;
			xs=(X509 *)sk_value(ctx->chain,n);
			}
		}
	ok=1;
end:
	return(ok);
	}

int X509_cmp_current_time(ctm)
ASN1_UTCTIME *ctm;
	{
	char *str;
	ASN1_UTCTIME atm;
#ifdef __GEOS__
	long offset;
#else
	time_t offset;
#endif
	char buff1[24],buff2[24],*p;
	int i,j;

	p=buff1;
	i=ctm->length;
	str=(char *)ctm->data;
	if ((i < 11) || (i > 17)) return(0);
	memcpy(p,str,10);
	p+=10;
	str+=10;

	if ((*str == 'Z') || (*str == '-') || (*str == '+'))
		{ *(p++)='0'; *(p++)='0'; }
	else	{ *(p++)= *(str++); *(p++)= *(str++); }
	*(p++)='Z';
	*(p++)='\0';

	if (*str == 'Z')
		offset=0;
	else
		{
		if ((*str != '+') && (str[5] != '-'))
			return(0);
		offset=((str[1]-'0')*10+(str[2]-'0'))*60;
		offset+=(str[3]-'0')*10+(str[4]-'0');
		if (*str == '-')
			offset=-offset;
		}
	atm.type=V_ASN1_UTCTIME;
	atm.length=sizeof(buff2);
	atm.data=(unsigned char *)buff2;

	X509_gmtime_adj(&atm,-offset);

	i=(buff1[0]-'0')*10+(buff1[1]-'0');
	if (i < 70) i+=100;
	j=(buff2[0]-'0')*10+(buff2[1]-'0');
	if (j < 70) j+=100;

	if (i < j) return (-1);
	if (i > j) return (1);
	i=strcmp(buff1,buff2);
	if (i == 0) /* wait a second then return younger :-) */
		return(-1);
	else
		return(i);
	}

ASN1_UTCTIME *X509_gmtime_adj(s, adj)
ASN1_UTCTIME *s;
long adj;
	{
#ifdef __GEOS__
	TimerDateAndTime t;
#else
	time_t t;
#endif

#ifdef __GEOS__
	TimerGetDateAndTime(&t);
	t.TDAT_seconds += adj%60;
	t.TDAT_minutes += (adj/60)%60;
	t.TDAT_hours += adj/(60*60);
#else
	time(&t);
	t+=adj;
#endif
	return(ASN1_UTCTIME_set(s,t));
	}

int X509_get_pubkey_parameters(pkey,chain)
EVP_PKEY *pkey;
STACK *chain;
	{
	EVP_PKEY *ktmp=NULL,*ktmp2;
	int i,j;

	if ((pkey != NULL) && !EVP_PKEY_missing_parameters(pkey)) return(1);

	for (i=0; i<sk_num(chain); i++)
		{
		ktmp=X509_get_pubkey((X509 *)sk_value(chain,i));
		if (ktmp == NULL)
			{
			X509err(X509_F_X509_GET_PUBKEY_PARAMETERS,X509_R_UNABLE_TO_GET_CERTS_PUBLIC_KEY);
			return(0);
			}
		if (!EVP_PKEY_missing_parameters(ktmp))
			break;
		else
			{
			ktmp=NULL;
			}
		}
	if (ktmp == NULL)
		{
		X509err(X509_F_X509_GET_PUBKEY_PARAMETERS,X509_R_UNABLE_TO_FIND_PARAMETERS_IN_CHAIN);
		return(0);
		}

	/* first, populate the other certs */
	for (j=i-1; j >= 0; j--)
		{
		ktmp2=X509_get_pubkey((X509 *)sk_value(chain,j));
		EVP_PKEY_copy_parameters(ktmp2,ktmp);
		}
	
	if (pkey != NULL)
		EVP_PKEY_copy_parameters(pkey,ktmp);
	return(1);
	}

EVP_PKEY *X509_get_pubkey(x)
X509 *x;
	{
	if ((x == NULL) || (x->cert_info == NULL))
		return(NULL);
	return(X509_PUBKEY_get(x->cert_info->key));
	}

int X509_check_private_key(x,k)
X509 *x;
EVP_PKEY *k;
	{
	EVP_PKEY *xk=NULL;
	int ok=0;

	xk=X509_get_pubkey(x);
	if (xk->type != k->type) goto err;
	switch (k->type)
		{
#ifndef NO_RSA
	case EVP_PKEY_RSA:
		if (BN_cmp(xk->pkey.rsa->n,k->pkey.rsa->n) != 0) goto err;
		if (BN_cmp(xk->pkey.rsa->e,k->pkey.rsa->e) != 0) goto err;
		break;
#endif
#ifndef NO_DSA
	case EVP_PKEY_DSA:
		if (BN_cmp(xk->pkey.dsa->pub_key,k->pkey.dsa->pub_key) != 0)
			goto err;
		break;
#endif
#ifndef NO_DH
	case EVP_PKEY_DH:
		/* No idea */
		goto err;
#endif
	default:
		goto err;
		}

	ok=1;
err:
	return(ok);
	}

int X509_STORE_add_cert(ctx,x)
X509_STORE *ctx;
X509 *x;
	{
	X509_OBJECT *obj,*r;
	int ret=1;

	if (x == NULL) return(0);
	obj=(X509_OBJECT *)Malloc(sizeof(X509_OBJECT));
	if (obj == NULL)
		{
		X509err(X509_F_X509_STORE_ADD_CERT,ERR_R_MALLOC_FAILURE);
		return(0);
		}
	obj->type=X509_LU_X509;
	obj->data.x509=x;

	CRYPTO_w_lock(CRYPTO_LOCK_X509_STORE);

	X509_OBJECT_up_ref_count(obj);

	r=(X509_OBJECT *)lh_insert(ctx->certs,(char *)obj);
	if (r != NULL)
		{ /* oops, put it back */
		lh_delete(ctx->certs,(char *)obj);
		X509_OBJECT_free_contents(obj);
		Free(obj);
		lh_insert(ctx->certs,(char *)r);
		X509err(X509_F_X509_STORE_ADD_CERT,X509_R_CERT_ALREADY_IN_HASH_TABLE);
		ret=0;
		}

	CRYPTO_w_unlock(CRYPTO_LOCK_X509_STORE);

	return(ret);	
	}

int X509_STORE_add_crl(ctx,x)
X509_STORE *ctx;
X509_CRL *x;
	{
	X509_OBJECT *obj,*r;
	int ret=1;

	if (x == NULL) return(0);
	obj=(X509_OBJECT *)Malloc(sizeof(X509_OBJECT));
	if (obj == NULL)
		{
		X509err(X509_F_X509_STORE_ADD_CRL,ERR_R_MALLOC_FAILURE);
		return(0);
		}
	obj->type=X509_LU_CRL;
	obj->data.crl=x;

	CRYPTO_w_lock(CRYPTO_LOCK_X509_STORE);

	X509_OBJECT_up_ref_count(obj);

	r=(X509_OBJECT *)lh_insert(ctx->certs,(char *)obj);
	if (r != NULL)
		{ /* oops, put it back */
		lh_delete(ctx->certs,(char *)obj);
		X509_OBJECT_free_contents(obj);
		Free(obj);
		lh_insert(ctx->certs,(char *)r);
		X509err(X509_F_X509_STORE_ADD_CRL,X509_R_CERT_ALREADY_IN_HASH_TABLE);
		ret=0;
		}

	CRYPTO_w_unlock(CRYPTO_LOCK_X509_STORE);

	return(ret);	
	}

#ifdef __GEOS__
int X509_STORE_CTX_get_ex_new_index(long argl,char *argp,int (*new_func)(),int (*dup_func)(),void (*free_func)())
#else
int X509_STORE_CTX_get_ex_new_index(argl,argp,new_func,dup_func,free_func)
long argl;
char *argp;
int (*new_func)();
int (*dup_func)();
void (*free_func)();
#endif
        {
        x509_store_ctx_num++;
        return(CRYPTO_get_ex_new_index(x509_store_ctx_num-1,
		&x509_store_ctx_method,
                argl,argp,new_func,dup_func,free_func));
        }

int X509_STORE_CTX_set_ex_data(ctx,idx,data)
X509_STORE_CTX *ctx;
int idx;
char *data;
	{
	return(CRYPTO_set_ex_data(&ctx->ex_data,idx,data));
	}

char *X509_STORE_CTX_get_ex_data(ctx,idx)
X509_STORE_CTX *ctx;
int idx;
	{
	return(CRYPTO_get_ex_data(&ctx->ex_data,idx));
	}

int X509_STORE_CTX_get_error(ctx)
X509_STORE_CTX *ctx;
	{
	return(ctx->error);
	}

void X509_STORE_CTX_set_error(ctx,err)
X509_STORE_CTX *ctx;
int err;
	{
	ctx->error=err;
	}

int X509_STORE_CTX_get_error_depth(ctx)
X509_STORE_CTX *ctx;
	{
	return(ctx->error_depth);
	}

X509 *X509_STORE_CTX_get_current_cert(ctx)
X509_STORE_CTX *ctx;
	{
	return(ctx->current_cert);
	}

STACK *X509_STORE_CTX_get_chain(ctx)
X509_STORE_CTX *ctx;
	{
	return(ctx->chain);
	}

void X509_STORE_CTX_set_cert(ctx,x)
X509_STORE_CTX *ctx;
X509 *x;
	{
	ctx->cert=x;
	}

void X509_STORE_CTX_set_chain(ctx,sk)
X509_STORE_CTX *ctx;
STACK *sk;
	{
	ctx->untrusted=sk;
	}

#endif
