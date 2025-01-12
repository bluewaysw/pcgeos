/* crypto/asn1/a_utctm.c */
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
#include "cryptlib.h"
#include "asn1.h"

/* ASN1err(ASN1_F_ASN1_UTCTIME_NEW,ASN1_R_UTCTIME_TOO_LONG);
 * ASN1err(ASN1_F_D2I_ASN1_UTCTIME,ASN1_R_EXPECTING_A_UTCTIME);
 */

int i2d_ASN1_UTCTIME(a,pp)
ASN1_UTCTIME *a;
unsigned char **pp;
	{
	return(i2d_ASN1_bytes((ASN1_STRING *)a,pp,
		V_ASN1_UTCTIME,V_ASN1_UNIVERSAL));
	}


ASN1_UTCTIME *d2i_ASN1_UTCTIME(a, pp, length)
ASN1_UTCTIME **a;
unsigned char **pp;
long length;
	{
	ASN1_UTCTIME *ret=NULL;

	ret=(ASN1_UTCTIME *)d2i_ASN1_bytes((ASN1_STRING **)a,pp,length,
		V_ASN1_UTCTIME,V_ASN1_UNIVERSAL);
	if (ret == NULL)
		{
		ASN1err(ASN1_F_D2I_ASN1_UTCTIME,ASN1_R_ERROR_STACK);
		return(NULL);
		}
	if (!ASN1_UTCTIME_check(ret))
		{
		ASN1err(ASN1_F_D2I_ASN1_UTCTIME,ASN1_R_INVALID_TIME_FORMAT);
		goto err;
		}

	return(ret);
err:
	if ((ret != NULL) && ((a == NULL) || (*a != ret)))
		ASN1_UTCTIME_free(ret);
	return(NULL);
	}

int ASN1_UTCTIME_check(d)
ASN1_UTCTIME *d;
	{
	static int min[8]={ 0, 1, 1, 0, 0, 0, 0, 0};
	static int max[8]={99,12,31,23,59,59,12,59};
	char *a;
	int n,i,l,o;

	PUSHDS;
	if (d->type != V_ASN1_UTCTIME) return(0);
	l=d->length;
	a=(char *)d->data;
	o=0;

	if (l < 11) goto err;
	for (i=0; i<6; i++)
		{
		if ((i == 5) && ((a[o] == 'Z') ||
			(a[o] == '+') || (a[o] == '-')))
			{ i++; break; }
		if ((a[o] < '0') || (a[o] > '9')) goto err;
		n= a[o]-'0';
		if (++o > l) goto err;

		if ((a[o] < '0') || (a[o] > '9')) goto err;
		n=(n*10)+ a[o]-'0';
		if (++o > l) goto err;

		if ((n < min[i]) || (n > max[i])) goto err;
		}
	if (a[o] == 'Z')
		o++;
	else if ((a[o] == '+') || (a[o] == '-'))
		{
		o++;
		if (o+4 > l) goto err;
		for (i=6; i<8; i++)
			{
			if ((a[o] < '0') || (a[o] > '9')) goto err;
			n= a[o]-'0';
			o++;
			if ((a[o] < '0') || (a[o] > '9')) goto err;
			n=(n*10)+ a[o]-'0';
			if ((n < min[i]) || (n > max[i])) goto err;
			o++;
			}
		}
	POPDS;
	return(o == l);
err:
	POPDS;
	return(0);
	}

int ASN1_UTCTIME_set_string(s,str)
ASN1_UTCTIME *s;
char *str;
	{
	ASN1_UTCTIME t;

	t.type=V_ASN1_UTCTIME;
	t.length=strlen(str);
	t.data=(unsigned char *)str;
	if (ASN1_UTCTIME_check(&t))
		{
		if (s != NULL)
			{
			ASN1_STRING_set((ASN1_STRING *)s,
				(unsigned char *)str,t.length);
			}
		return(1);
		}
	else
		return(0);
	}

ASN1_UTCTIME *ASN1_UTCTIME_set(s, t)
ASN1_UTCTIME *s;
#ifdef __GEOS__
TimerDateAndTime t;
#else
time_t t;
#endif
	{
	char *p;
#ifdef __GEOS__
	TimerDateAndTime ts;
#else
	struct tm *ts;
#if defined(THREADS)
	struct tm data;
#endif
#endif

	if (s == NULL)
		s=ASN1_UTCTIME_new();
	if (s == NULL)
		return(NULL);

#ifdef __GEOS__
	TimerGetDateAndTime(&ts);
#else
#if defined(THREADS)
	ts=(struct tm *)gmtime_r(&t,&data);
#else
	ts=(struct tm *)gmtime(&t);
#endif
#endif
	p=(char *)s->data;
	if ((p == NULL) || (s->length < 14))
		{
		p=Malloc(20);
		if (p == NULL) return(NULL);
		if (s->data != NULL)
			Free(s->data);
		s->data=(unsigned char *)p;
		}

#ifdef __GEOS__
	sprintf(p,"%02d%02d%02d%02d%02d%02dZ",ts.TDAT_year%100,
		ts.TDAT_month,ts.TDAT_day,ts.TDAT_hours,ts.TDAT_minutes,ts.TDAT_seconds);
#else
	sprintf(p,"%02d%02d%02d%02d%02d%02dZ",ts->tm_year%100,
		ts->tm_mon+1,ts->tm_mday,ts->tm_hour,ts->tm_min,ts->tm_sec);
#endif
	s->length=strlen(p);
	s->type=V_ASN1_UTCTIME;
	return(s);
	}

#endif
