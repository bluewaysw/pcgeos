/* crypto/x509/x509_ext.c */
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
#include "stack.h"
#include "cryptlib.h"
#include "asn1.h"
#include "objects.h"
#include "evp.h"
#include "x509.h"

int X509_CRL_get_ext_count(x)
X509_CRL *x;
	{
	return(X509v3_get_ext_count(x->crl->extensions));
	}

int X509_CRL_get_ext_by_NID(x,nid,lastpos)
X509_CRL *x;
int nid;
int lastpos;
	{
	return(X509v3_get_ext_by_NID(x->crl->extensions,nid,lastpos));
	}

int X509_CRL_get_ext_by_OBJ(x,obj,lastpos)
X509_CRL *x;
ASN1_OBJECT *obj;
int lastpos;
	{
	return(X509v3_get_ext_by_OBJ(x->crl->extensions,obj,lastpos));
	}

int X509_CRL_get_ext_by_critical(x,crit,lastpos)
X509_CRL *x;
int crit;
int lastpos;
	{
	return(X509v3_get_ext_by_critical(x->crl->extensions,crit,lastpos));
	}

X509_EXTENSION *X509_CRL_get_ext(x,loc)
X509_CRL *x;
int loc;
	{
	return(X509v3_get_ext(x->crl->extensions,loc));
	}

X509_EXTENSION *X509_CRL_delete_ext(x,loc)
X509_CRL *x;
int loc;
	{
	return(X509v3_delete_ext(x->crl->extensions,loc));
	}

int X509_CRL_add_ext(x,ex,loc)
X509_CRL *x;
X509_EXTENSION *ex;
int loc;
	{
	return(X509v3_add_ext(&(x->crl->extensions),ex,loc) != NULL);
	}

int X509_get_ext_count(x)
X509 *x;
	{
	return(X509v3_get_ext_count(x->cert_info->extensions));
	}

int X509_get_ext_by_NID(x,nid,lastpos)
X509 *x;
int nid;
int lastpos;
	{
	return(X509v3_get_ext_by_NID(x->cert_info->extensions,nid,lastpos));
	}

int X509_get_ext_by_OBJ(x,obj,lastpos)
X509 *x;
ASN1_OBJECT *obj;
int lastpos;
	{
	return(X509v3_get_ext_by_OBJ(x->cert_info->extensions,obj,lastpos));
	}

int X509_get_ext_by_critical(x,crit,lastpos)
X509 *x;
int crit;
int lastpos;
	{
	return(X509v3_get_ext_by_critical(x->cert_info->extensions,crit,lastpos));
	}

X509_EXTENSION *X509_get_ext(x,loc)
X509 *x;
int loc;
	{
	return(X509v3_get_ext(x->cert_info->extensions,loc));
	}

X509_EXTENSION *X509_delete_ext(x,loc)
X509 *x;
int loc;
	{
	return(X509v3_delete_ext(x->cert_info->extensions,loc));
	}

int X509_add_ext(x,ex,loc)
X509 *x;
X509_EXTENSION *ex;
int loc;
	{
	return(X509v3_add_ext(&(x->cert_info->extensions),ex,loc) != NULL);
	}

int X509_REVOKED_get_ext_count(x)
X509_REVOKED *x;
	{
	return(X509v3_get_ext_count(x->extensions));
	}

int X509_REVOKED_get_ext_by_NID(x,nid,lastpos)
X509_REVOKED *x;
int nid;
int lastpos;
	{
	return(X509v3_get_ext_by_NID(x->extensions,nid,lastpos));
	}

int X509_REVOKED_get_ext_by_OBJ(x,obj,lastpos)
X509_REVOKED *x;
ASN1_OBJECT *obj;
int lastpos;
	{
	return(X509v3_get_ext_by_OBJ(x->extensions,obj,lastpos));
	}

int X509_REVOKED_get_ext_by_critical(x,crit,lastpos)
X509_REVOKED *x;
int crit;
int lastpos;
	{
	return(X509v3_get_ext_by_critical(x->extensions,crit,lastpos));
	}

X509_EXTENSION *X509_REVOKED_get_ext(x,loc)
X509_REVOKED *x;
int loc;
	{
	return(X509v3_get_ext(x->extensions,loc));
	}

X509_EXTENSION *X509_REVOKED_delete_ext(x,loc)
X509_REVOKED *x;
int loc;
	{
	return(X509v3_delete_ext(x->extensions,loc));
	}

int X509_REVOKED_add_ext(x,ex,loc)
X509_REVOKED *x;
X509_EXTENSION *ex;
int loc;
	{
	return(X509v3_add_ext(&(x->extensions),ex,loc) != NULL);
	}

#endif
