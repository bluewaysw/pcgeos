/* ssl/ssl_algs.c */
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
#include "objects.h"
#include "lhash.h"
#include "ssl_locl.h"
#include <hostif.h>

#ifdef COMPILE_OPTION_HOST_SERVICE
extern Boolean hostApiAvailable;
#endif

void _export _pascal SSLeay_add_ssl_algorithms()
	{
#ifdef COMPILE_OPTION_HOST_SERVICE
	if(hostApiAvailable)
		{
		HostIfCall(
			HIF_SSL_SSLEAY_ADD_SSL_ALGO,
			 			(dword) NULL, (dword) NULL, 0);
		return;
		}
#endif

    SSLEnter() ;
#ifndef NO_DES
/*	EVP_add_cipher(EVP_des_cbc());
	EVP_add_cipher(EVP_des_ede3_cbc());*/
#endif
#ifndef NO_IDEA
	EVP_add_cipher(EVP_idea_cbc());
#endif
#ifndef NO_RC4
        EVP_add_cipher(EVP_rc4());
#endif  
#ifndef NO_RC2
        EVP_add_cipher(EVP_rc2_cbc());
#endif  

#ifndef NO_MD2
        EVP_add_digest(EVP_md2());
#endif
#ifndef NO_MD5
	EVP_add_digest(EVP_md5());
	EVP_add_alias(SN_md5,"ssl2-md5");
	EVP_add_alias(SN_md5,"ssl3-md5");
#endif
#ifndef NO_SHA1
	EVP_add_digest(EVP_sha1()); /* RSA with sha1 */
	EVP_add_alias(SN_sha1,"ssl3-sha1");
#endif
#if !defined(NO_SHA1) && !defined(NO_DSA)
/*	EVP_add_digest(EVP_dss1()); *//* DSA with sha1 */
#endif

	/* If you want support for phased out ciphers, add the following */
#if 0
	EVP_add_digest(EVP_sha());
	EVP_add_digest(EVP_dss());
#endif
        SSLLeave() ;
	}

