/* crypto/asn1/a_print.c */
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
#include "asn1.h"

/* ASN1err(ASN1_F_D2I_ASN1_PRINT_TYPE,ASN1_R_WRONG_PRINTABLE_TYPE);
 * ASN1err(ASN1_F_D2I_ASN1_PRINT_TYPE,ASN1_R_TAG_VALUE_TOO_HIGH);
 */

int i2d_ASN1_IA5STRING(a,pp)
ASN1_IA5STRING *a;
unsigned char **pp;
	{ return(M_i2d_ASN1_IA5STRING(a,pp)); }

ASN1_IA5STRING *d2i_ASN1_IA5STRING(a,pp,l)
ASN1_IA5STRING **a;
unsigned char **pp;
long l;
	{ return(M_d2i_ASN1_IA5STRING(a,pp,l)); }

ASN1_T61STRING *d2i_ASN1_T61STRING(a,pp,l)
ASN1_T61STRING **a;
unsigned char **pp;
long l;
	{ return(M_d2i_ASN1_T61STRING(a,pp,l)); }

ASN1_PRINTABLESTRING *d2i_ASN1_PRINTABLESTRING(a,pp,l)
ASN1_PRINTABLESTRING **a;
unsigned char **pp;
long l;
	{ return(M_d2i_ASN1_PRINTABLESTRING(a,pp,l)); }

int i2d_ASN1_PRINTABLE(a,pp)
ASN1_STRING *a;
unsigned char **pp;
	{ return(M_i2d_ASN1_PRINTABLE(a,pp)); }

ASN1_STRING *d2i_ASN1_PRINTABLE(a,pp,l)
ASN1_STRING **a;
unsigned char **pp;
long l;
	{ return(M_d2i_ASN1_PRINTABLE(a,pp,l)); }

int ASN1_PRINTABLE_type(s,len)
unsigned char *s;
int len;
	{
	int c;
	int ia5=0;
	int t61=0;

	if (len <= 0) len= -1;
	if (s == NULL) return(V_ASN1_PRINTABLESTRING);

	while ((*s) && (len-- != 0))
		{
		c= *(s++);
		if (!(	((c >= 'a') && (c <= 'z')) ||
			((c >= 'A') && (c <= 'Z')) ||
			(c == ' ') ||
			((c >= '0') && (c <= '9')) ||
			(c == ' ') || (c == '\'') ||
			(c == '(') || (c == ')') ||
			(c == '+') || (c == ',') ||
			(c == '-') || (c == '.') ||
			(c == '/') || (c == ':') ||
			(c == '=') || (c == '?')))
			ia5=1;
		if (c&0x80)
			t61=1;
		}
	if (t61) return(V_ASN1_T61STRING);
	if (ia5) return(V_ASN1_IA5STRING);
	return(V_ASN1_PRINTABLESTRING);
	}

int ASN1_UNIVERSALSTRING_to_string(s)
ASN1_UNIVERSALSTRING *s;
	{
	int i;
	unsigned char *p;

	if (s->type != V_ASN1_UNIVERSALSTRING) return(0);
	if ((s->length%4) != 0) return(0);
	p=s->data;
	for (i=0; i<s->length; i+=4)
		{
		if ((p[0] != '\0') || (p[1] != '\0') || (p[2] != '\0'))
			break;
		else
			p+=4;
		}
	if (i < s->length) return(0);
	p=s->data;
	for (i=3; i<s->length; i+=4)
		{
		*(p++)=s->data[i];
		}
	*(p)='\0';
	s->length/=4;
	s->type=ASN1_PRINTABLE_type(s->data,s->length);
	return(1);
	}

#endif
