/* crypto/asn1/a_object.c */
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
#include "buffer.h"
#include "asn1.h"
#include "objects.h"

/* ASN1err(ASN1_F_ASN1_OBJECT_NEW,ASN1_R_EXPECTING_AN_OBJECT); 
 * ASN1err(ASN1_F_D2I_ASN1_OBJECT,ASN1_R_BAD_OBJECT_HEADER); 
 * ASN1err(ASN1_F_I2T_ASN1_OBJECT,ASN1_R_BAD_OBJECT_HEADER);
 */

int i2d_ASN1_OBJECT(a, pp)
ASN1_OBJECT *a;
unsigned char **pp;
	{
	unsigned char *p;

	if ((a == NULL) || (a->data == NULL)) return(0);

	if (pp == NULL)
		return(ASN1_object_size(0,a->length,V_ASN1_OBJECT));

	p= *pp;
	ASN1_put_object(&p,0,a->length,V_ASN1_OBJECT,V_ASN1_UNIVERSAL);
	memcpy(p,a->data,a->length);
	p+=a->length;

	*pp=p;
	return(a->length);
	}

int a2d_ASN1_OBJECT(out,olen,buf,num)
unsigned char *out;
int olen;
char *buf;
int num;
	{
	int i,first,len=0,c;
	char tmp[24],*p;
	unsigned long l;

	if (num == 0)
		return(0);
	else if (num == -1)
		num=strlen(buf);

	p=buf;
	c= *(p++);
	num--;
	if ((c >= '0') && (c <= '2'))
		{
		first=(c-'0')*40;
		}
	else
		{
		ASN1err(ASN1_F_A2D_ASN1_OBJECT,ASN1_R_FIRST_NUM_TOO_LARGE);
		goto err;
		}

	if (num <= 0)
		{
		ASN1err(ASN1_F_A2D_ASN1_OBJECT,ASN1_R_MISSING_SECOND_NUMBER);
		goto err;
		}
	c= *(p++);
	num--;
	for (;;)
		{
		if (num <= 0) break;
		if ((c != '.') && (c != ' '))
			{
			ASN1err(ASN1_F_A2D_ASN1_OBJECT,ASN1_R_INVALID_SEPARATOR);
			goto err;
			}
		l=0;
		for (;;)
			{
			if (num <= 0) break;
			num--;
			c= *(p++);
			if ((c == ' ') || (c == '.'))
				break;
			if ((c < '0') || (c > '9'))
				{
				ASN1err(ASN1_F_A2D_ASN1_OBJECT,ASN1_R_INVALID_DIGIT);
				goto err;
				}
			l=l*10L+(long)(c-'0');
			}
		if (len == 0)
			{
			if ((first < 2) && (l >= 40))
				{
				ASN1err(ASN1_F_A2D_ASN1_OBJECT,ASN1_R_SECOND_NUMBER_TOO_LARGE);
				goto err;
				}
			l+=(long)first;
			}
		i=0;
		for (;;)
			{
			tmp[i++]=(unsigned char)l&0x7f;
			l>>=7L;
			if (l == 0L) break;
			}
		if (out != NULL)
			{
			if (len+i > olen)
				{
				ASN1err(ASN1_F_A2D_ASN1_OBJECT,ASN1_R_BUFFER_TOO_SMALL);
				goto err;
				}
			while (--i > 0)
				out[len++]=tmp[i]|0x80;
			out[len++]=tmp[0];
			}
		else
			len+=i;
		}
	return(len);
err:
	return(0);
	}

int i2t_ASN1_OBJECT(buf,buf_len,a)
char *buf;
int buf_len;
ASN1_OBJECT *a;
	{
	int i,idx=0,n=0,len,nid;
	unsigned long l;
	unsigned char *p;
	char *s;
	char tbuf[32];

	if (buf_len <= 0) return(0);

	if ((a == NULL) || (a->data == NULL))
		{
		buf[0]='\0';
		return(0);
		}

	nid=OBJ_obj2nid(a);
	if (nid == NID_undef)
		{
		len=a->length;
		p=a->data;

		idx=0;
		l=0;
		while (idx < a->length)
			{
			l|=(p[idx]&0x7f);
			if (!(p[idx] & 0x80)) break;
			l<<=7L;
			idx++;
			}
		idx++;
		i=(int)(l/40);
		if (i > 2) i=2;
		l-=(long)(i*40);

		sprintf(tbuf,"%d.%ld",i,l);
		i=strlen(tbuf);
		strncpy(buf,tbuf,buf_len);
		buf_len-=i;
		buf+=i;
		n+=i;

		l=0;
		for (; idx<len; idx++)
			{
			l|=p[idx]&0x7f;
			if (!(p[idx] & 0x80))
				{
				sprintf(tbuf,".%ld",l);
				i=strlen(tbuf);
				if (buf_len > 0)
					strncpy(buf,tbuf,buf_len);
				buf_len-=i;
				buf+=i;
				n+=i;
				l=0;
				}
			l<<=7L;
			}
		}
	else
		{
		s=(char *)OBJ_nid2ln(nid);
		if (s == NULL)
			s=(char *)OBJ_nid2sn(nid);
		strncpy(buf,s,buf_len);
		n=strlen(s);
		}
	buf[buf_len-1]='\0';
	return(n);
	}

int i2a_ASN1_OBJECT(bp,a)
BIO *bp;
ASN1_OBJECT *a;
	{
	char buf[80];
	int i;

	if ((a == NULL) || (a->data == NULL))
		return(BIO_write(bp,"NULL",4));
	i=i2t_ASN1_OBJECT(buf,80,a);
	if (i > 80) i=80;
	BIO_write(bp,buf,i);
	return(i);
	}

ASN1_OBJECT *d2i_ASN1_OBJECT(a, pp, length)
ASN1_OBJECT **a;
unsigned char **pp;
long length; 
	{
	ASN1_OBJECT *ret=NULL;
	unsigned char *p;
	long len;
	int tag,xclass;
	int inf,i;

	/* only the ASN1_OBJECTs from the 'table' will have values
	 * for ->sn or ->ln */
	if ((a == NULL) || ((*a) == NULL) ||
		!((*a)->flags & ASN1_OBJECT_FLAG_DYNAMIC))
		{
		if ((ret=ASN1_OBJECT_new()) == NULL) return(NULL);
		}
	else	ret=(*a);

	p= *pp;

	inf=ASN1_get_object(&p,&len,&tag,&xclass,length);
	if (inf & 0x80)
		{
		i=ASN1_R_BAD_OBJECT_HEADER;
		goto err;
		}

	if (tag != V_ASN1_OBJECT)
		{
		i=ASN1_R_EXPECTING_AN_OBJECT;
		goto err;
		}
	if ((ret->data == NULL) || (ret->length < len))
		{
		if (ret->data != NULL) Free((char *)ret->data);
		ret->data=(unsigned char *)Malloc((int)len);
		ret->flags|=ASN1_OBJECT_FLAG_DYNAMIC_DATA;
		if (ret->data == NULL)
			{ i=ERR_R_MALLOC_FAILURE; goto err; }
		}
	memcpy(ret->data,p,(int)len);
	ret->length=(int)len;
	ret->sn=NULL;
	ret->ln=NULL;
	/* ret->flags=ASN1_OBJECT_FLAG_DYNAMIC; we know it is dynamic */
	p+=len;

	if (a != NULL) (*a)=ret;
	*pp=p;
	return(ret);
err:
	ASN1err(ASN1_F_D2I_ASN1_OBJECT,i);
	if ((ret != NULL) && ((a == NULL) || (*a != ret)))
		ASN1_OBJECT_free(ret);
	return(NULL);
	}

ASN1_OBJECT *ASN1_OBJECT_new()
	{
	ASN1_OBJECT *ret;

	ret=(ASN1_OBJECT *)Malloc(sizeof(ASN1_OBJECT));
	if (ret == NULL)
		{
		ASN1err(ASN1_F_ASN1_OBJECT_NEW,ERR_R_MALLOC_FAILURE);
		return(NULL);
		}
	ret->length=0;
	ret->data=NULL;
	ret->nid=0;
	ret->sn=NULL;
	ret->ln=NULL;
	ret->flags=ASN1_OBJECT_FLAG_DYNAMIC;
	return(ret);
	}

void ASN1_OBJECT_free(a)
ASN1_OBJECT *a;
	{
	if (a == NULL) return;
	if (a->flags & ASN1_OBJECT_FLAG_DYNAMIC_STRINGS)
		{
		if (a->sn != NULL) Free(a->sn);
		if (a->ln != NULL) Free(a->ln);
		a->sn=a->ln=NULL;
		}
	if (a->flags & ASN1_OBJECT_FLAG_DYNAMIC_DATA)
		{
		if (a->data != NULL) Free(a->data);
		a->data=NULL;
		a->length=0;
		}
	if (a->flags & ASN1_OBJECT_FLAG_DYNAMIC)
		Free((char *)a);
	}

ASN1_OBJECT *ASN1_OBJECT_create(nid,data,len,sn,ln)
int nid;
unsigned char *data;
int len;
char *sn,*ln;
	{
	ASN1_OBJECT o;

	o.sn=sn;
	o.ln=ln;
	o.data=data;
	o.nid=nid;
	o.length=len;
	o.flags=ASN1_OBJECT_FLAG_DYNAMIC|
		ASN1_OBJECT_FLAG_DYNAMIC_STRINGS|ASN1_OBJECT_FLAG_DYNAMIC_DATA;
	return(OBJ_dup(&o));
	}

#endif
