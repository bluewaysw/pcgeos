/* ssl/t1_enc.c */
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
#include "evp.h"
#include "hmac.h"
#include "ssl_locl.h"

#ifndef COMPILE_OPTION_HOST_SERVICE_ONLY

static void tls1_P_hash(md,sec,sec_len,seed,seed_len,out,olen)
EVP_MD *md;
unsigned char *sec;
int sec_len;
unsigned char *seed;
int seed_len;
unsigned char *out;
int olen;
	{
	int chunk,n;
	unsigned int j;
	HMAC_CTX ctx;
	HMAC_CTX ctx_tmp;
	unsigned char A1[HMAC_MAX_MD_CBLOCK];
	unsigned int A1_len;
	
	chunk=EVP_MD_size(md);

	HMAC_Init(&ctx,sec,sec_len,md);
	HMAC_Update(&ctx,seed,seed_len);
	HMAC_Final(&ctx,A1,&A1_len);

	n=0;
	for (;;)
		{
		HMAC_Init(&ctx,NULL,0,NULL); /* re-init */
		HMAC_Update(&ctx,A1,A1_len);
		memcpy(&ctx_tmp,&ctx,sizeof(ctx)); /* Copy for A2 */ /* not needed for last one */
		HMAC_Update(&ctx,seed,seed_len);

		if (olen > chunk)
			{
			HMAC_Final(&ctx,out,&j);
			out+=j;
			olen-=j;
			HMAC_Final(&ctx_tmp,A1,&A1_len); /* calc the next A1 value */
			}
		else	/* last one */
			{
			HMAC_Final(&ctx,A1,&A1_len);
			memcpy(out,A1,olen);
			break;
			}
		}
	HMAC_cleanup(&ctx);
	HMAC_cleanup(&ctx_tmp);
	memset(A1,0,sizeof(A1));
	}

static void tls1_PRF(md5,sha1,label,label_len,sec,slen,out1,out2,olen)
EVP_MD *md5;
EVP_MD *sha1;
unsigned char *label;
int label_len;
unsigned char *sec;
int slen;
unsigned char *out1;
unsigned char *out2;
int olen;
	{
	int len,i;
	unsigned char *S1,*S2;

	len=slen/2;
	S1=sec;
	S2= &(sec[len]);
	len+=(slen&1); /* add for odd, make longer */

	
	tls1_P_hash(md5 ,S1,len,label,label_len,out1,olen);
	tls1_P_hash(sha1,S2,len,label,label_len,out2,olen);

	for (i=0; i<olen; i++)
		out1[i]^=out2[i];
	}

static void tls1_generate_key_block(s,km,tmp,num)
SSL *s;
unsigned char *km,*tmp;
int num;
	{
	unsigned char *p;
	unsigned char buf[SSL3_RANDOM_SIZE*2+
		TLS_MD_MAX_CONST_SIZE];
	p=buf;

	memcpy(p,TLS_MD_KEY_EXPANSION_CONST,
		TLS_MD_KEY_EXPANSION_CONST_SIZE);
	p+=TLS_MD_KEY_EXPANSION_CONST_SIZE;
	memcpy(p,s->s3->server_random,SSL3_RANDOM_SIZE);
	p+=SSL3_RANDOM_SIZE;
	memcpy(p,s->s3->client_random,SSL3_RANDOM_SIZE);
	p+=SSL3_RANDOM_SIZE;

	tls1_PRF(s->ctx->md5,s->ctx->sha1,buf,(short)(p-buf),
		s->session->master_key,s->session->master_key_length,
		km,tmp,num);
	}

int tls1_change_cipher_state(s,which)
SSL *s;
int which;
	{
	unsigned char *p,*key_block,*mac_secret;
	unsigned char *exp_label,buf[TLS_MD_MAX_CONST_SIZE+
		SSL3_RANDOM_SIZE*2];
	unsigned char tmp1[EVP_MAX_KEY_LENGTH];
	unsigned char tmp2[EVP_MAX_KEY_LENGTH];
	unsigned char iv1[EVP_MAX_IV_LENGTH*2];
	unsigned char iv2[EVP_MAX_IV_LENGTH*2];
	unsigned char *ms,*key,*iv,*er1,*er2;
	int client_write;
	EVP_CIPHER_CTX *dd;
	EVP_CIPHER *c;
	SSL_COMPRESSION *comp;
	EVP_MD *m;
	int exp,n,i,j,k,exp_label_len;

	exp=(s->s3->tmp.new_cipher->algorithms & SSL_EXPORT)?1:0;
	c=s->s3->tmp.new_sym_enc;
	m=s->s3->tmp.new_hash;
	comp=s->s3->tmp.new_compression;
	key_block=s->s3->tmp.key_block;

	if (which & SSL3_CC_READ)
		{
		if ((s->enc_read_ctx == NULL) &&
			((s->enc_read_ctx=(EVP_CIPHER_CTX *)
			Malloc(sizeof(EVP_CIPHER_CTX))) == NULL))
			goto err;
		dd= s->enc_read_ctx;
		s->read_hash=m;
		s->read_compression=comp;
		memset(&(s->s3->read_sequence[0]),0,8);
		mac_secret= &(s->s3->read_mac_secret[0]);
		}
	else
		{
		if ((s->enc_write_ctx == NULL) &&
			((s->enc_write_ctx=(EVP_CIPHER_CTX *)
			Malloc(sizeof(EVP_CIPHER_CTX))) == NULL))
			goto err;
		dd= s->enc_write_ctx;
		s->write_hash=m;
		s->write_compression=comp;
		memset(&(s->s3->write_sequence[0]),0,8);
		mac_secret= &(s->s3->write_mac_secret[0]);
		}

	EVP_CIPHER_CTX_init(dd);

	p=s->s3->tmp.key_block;
	i=EVP_MD_size(m);
	j=(exp)?5:EVP_CIPHER_key_length(c);
	k=EVP_CIPHER_iv_length(c);
	er1= &(s->s3->client_random[0]);
	er2= &(s->s3->server_random[0]);
	if (	(which == SSL3_CHANGE_CIPHER_CLIENT_WRITE) ||
		(which == SSL3_CHANGE_CIPHER_SERVER_READ))
		{
		ms=  &(p[ 0]); n=i+i;
		key= &(p[ n]); n+=j+j;
		iv=  &(p[ n]); n+=k+k;
		exp_label=(unsigned char *)TLS_MD_CLIENT_WRITE_KEY_CONST;
		exp_label_len=TLS_MD_CLIENT_WRITE_KEY_CONST_SIZE;
		client_write=1;
		}
	else
		{
		n=i;
		ms=  &(p[ n]); n+=i+j;
		key= &(p[ n]); n+=j+k;
		iv=  &(p[ n]); n+=k;
		exp_label=(unsigned char *)TLS_MD_SERVER_WRITE_KEY_CONST;
		exp_label_len=TLS_MD_SERVER_WRITE_KEY_CONST_SIZE;
		client_write=0;
		}

	if (n > s->s3->tmp.key_block_length)
		{
		SSLerr(SSL_F_TLS1_CHANGE_CIPHER_STATE,SSL_R_INTERNAL_ERROR);
		goto err2;
		}

	memcpy(mac_secret,ms,i);
#ifdef TLS_DEBUG
printf("which = %04X\nmac key=",which);
{ int z; for (z=0; z<i; z++) printf("%02X%c",ms[z],((z+1)%16)?' ':'\n'); }
#endif
	if (exp)
		{
		/* In here I set both the read and write key/iv to the
		 * same value since only the correct one will be used :-).
		 */
		p=buf;
		memcpy(p,exp_label,exp_label_len);
		p+=exp_label_len;
		memcpy(p,s->s3->client_random,SSL3_RANDOM_SIZE);
		p+=SSL3_RANDOM_SIZE;
		memcpy(p,s->s3->server_random,SSL3_RANDOM_SIZE);
		p+=SSL3_RANDOM_SIZE;
		tls1_PRF(s->ctx->md5,s->ctx->sha1,buf,(short)(p-buf),key,j,
			tmp1,tmp2,EVP_CIPHER_key_length(c));
		key=tmp1;

		if (k > 0)
			{
			p=buf;
			memcpy(p,TLS_MD_IV_BLOCK_CONST,
				TLS_MD_IV_BLOCK_CONST_SIZE);
			p+=TLS_MD_IV_BLOCK_CONST_SIZE;
			memcpy(p,s->s3->client_random,SSL3_RANDOM_SIZE);
			p+=SSL3_RANDOM_SIZE;
			memcpy(p,s->s3->server_random,SSL3_RANDOM_SIZE);
			p+=SSL3_RANDOM_SIZE;
			tls1_PRF(s->ctx->md5,s->ctx->sha1,
				buf,(short)(p-buf),"",0,iv1,iv2,k*2);
			if (client_write)
				iv=iv1;
			else
				iv= &(iv1[k]);
			}
		}

	s->session->key_arg_length=0;

	EVP_CipherInit(dd,c,key,iv,(which & SSL3_CC_WRITE));
#ifdef TLS_DEBUG
printf("which = %04X\nkey=",which);
{ int z; for (z=0; z<EVP_CIPHER_key_length(c); z++) printf("%02X%c",key[z],((z+1)%16)?' ':'\n'); }
printf("\niv=");
{ int z; for (z=0; z<k; z++) printf("%02X%c",iv[z],((z+1)%16)?' ':'\n'); }
printf("\n");
#endif

	memset(tmp1,0,sizeof(tmp1));
	memset(tmp2,0,sizeof(tmp1));
	memset(iv1,0,sizeof(iv1));
	memset(iv2,0,sizeof(iv2));
	return(1);
err:
	SSLerr(SSL_F_TLS1_CHANGE_CIPHER_STATE,ERR_R_MALLOC_FAILURE);
err2:
	return(0);
	}

int tls1_setup_key_block(s)
SSL *s;
	{
	unsigned char *p1,*p2;
	EVP_CIPHER *c;
	EVP_MD *hash;
	int num,exp;

	if (s->s3->tmp.key_block_length != 0)
		return(1);

	if (!ssl_cipher_get_evp(s->session->cipher,&c,&hash))
		{
		SSLerr(SSL_F_TLS1_SETUP_KEY_BLOCK,SSL_R_CIPHER_OR_HASH_UNAVAILABLE);
		return(0);
		}

	s->s3->tmp.new_sym_enc=c;
	s->s3->tmp.new_hash=hash;

	exp=(s->session->cipher->algorithms & SSL_EXPORT)?1:0;

	num=EVP_CIPHER_key_length(c)+EVP_MD_size(hash)+EVP_CIPHER_iv_length(c);
	num*=2;

	ssl3_cleanup_key_block(s);

	if ((p1=(unsigned char *)Malloc(num)) == NULL)
		goto err;
	if ((p2=(unsigned char *)Malloc(num)) == NULL)
		goto err;

	s->s3->tmp.key_block_length=num;
	s->s3->tmp.key_block=p1;


#ifdef TLS_DEBUG
printf("client random\n");
{ int z; for (z=0; z<SSL3_RANDOM_SIZE; z++) printf("%02X%c",s->s3->client_random[z],((z+1)%16)?' ':'\n'); }
printf("server random\n");
{ int z; for (z=0; z<SSL3_RANDOM_SIZE; z++) printf("%02X%c",s->s3->server_random[z],((z+1)%16)?' ':'\n'); }
printf("pre-master\n");
{ int z; for (z=0; z<s->session->master_key_length; z++) printf("%02X%c",s->session->master_key[z],((z+1)%16)?' ':'\n'); }
#endif
	tls1_generate_key_block(s,p1,p2,num);
	memset(p2,0,num);
	Free(p2);
#ifdef TLS_DEBUG
printf("\nkey block\n");
{ int z; for (z=0; z<num; z++) printf("%02X%c",p1[z],((z+1)%16)?' ':'\n'); }
#endif

	return(1);
err:
	SSLerr(SSL_F_TLS1_SETUP_KEY_BLOCK,ERR_R_MALLOC_FAILURE);
	return(0);
	}

int tls1_enc(s,send)
SSL *s;
int send;
	{
	SSL3_RECORD *rec;
	EVP_CIPHER_CTX *ds;
	unsigned long l;
	int bs,i,ii,j,k,n=0;
	EVP_CIPHER *enc;
	SSL_COMPRESSION *comp;

	if (send)
		{
		if (s->write_hash != NULL)
			n=EVP_MD_size(s->write_hash);
		ds=s->enc_write_ctx;
		rec= &(s->s3->wrec);
		if (s->enc_write_ctx == NULL)
			{ enc=NULL; comp=NULL; }
		else
			{
			enc=EVP_CIPHER_CTX_cipher(s->enc_write_ctx);
			comp=s->write_compression;
			}
		}
	else
		{
		if (s->read_hash != NULL)
			n=EVP_MD_size(s->read_hash);
		ds=s->enc_read_ctx;
		rec= &(s->s3->rrec);
		if (s->enc_read_ctx == NULL)
			{ enc=NULL; comp=NULL; }
		else
			{
			enc=EVP_CIPHER_CTX_cipher(s->enc_read_ctx);
			comp=s->read_compression;
			}
		}

	if ((s->session == NULL) || (ds == NULL) ||
		((enc == NULL) && (comp == NULL)))
		{
		memcpy(rec->data,rec->input,rec->length);
		rec->input=rec->data;
		}
	else
		{
		l=rec->length;
		bs=EVP_CIPHER_block_size(ds->cipher);

		if ((bs != 1) && send)
			{
			i=bs-((int)l%bs);

			/* Add weird padding of upto 256 bytes */

			/* we need to add 'i' padding bytes of value j */
			j=i-1;
			if (s->options & SSL_OP_TLS_BLOCK_PADDING_BUG)
				{
				if (s->s3->flags & TLS1_FLAGS_TLS_PADDING_BUG)
					j++;
				}
			for (k=(int)l; k<(int)(l+i); k++)
				rec->input[k]=j;
			l+=i;
			rec->length+=i;
			}

#ifdef __GEOS__
		EVP_Cipher(ds,rec->data,rec->input,(int)l);
#else
		EVP_Cipher(ds,rec->data,rec->input,l);
#endif

		if ((bs != 1) && !send)
			{
			ii=i=rec->data[l-1];
			i++;
			if (s->options&SSL_OP_TLS_BLOCK_PADDING_BUG)
				{
				/* First packet is even in size, so check */
				if ((memcmp(s->s3->read_sequence,
					"\0\0\0\0\0\0\0\0",8) == 0) && !(ii & 1))
					s->s3->flags|=TLS1_FLAGS_TLS_PADDING_BUG;
				if (s->s3->flags & TLS1_FLAGS_TLS_PADDING_BUG)
					i--;
				}
			if (i > (int)rec->length)
				{
				SSLerr(SSL_F_TLS1_ENC,SSL_R_BLOCK_CIPHER_PAD_IS_WRONG);
				ssl3_send_alert(s,SSL3_AL_FATAL,SSL_AD_DECRYPTION_FAILED);
				return(0);
				}
			for (j=(int)(l-i); j<(int)l; j++)
				{
				if (rec->data[j] != ii)
					{
					SSLerr(SSL_F_TLS1_ENC,SSL_R_DECRYPTION_FAILED);
					ssl3_send_alert(s,SSL3_AL_FATAL,SSL_AD_DECRYPTION_FAILED);
					return(0);
					}
				}
			rec->length-=i;
			}
		}
	return(1);
	}

int tls1_cert_verify_mac(s,in_ctx,out)
SSL *s;
EVP_MD_CTX *in_ctx;
unsigned char *out;
	{
	unsigned int ret;
	EVP_MD_CTX ctx;

	memcpy(&ctx,in_ctx,sizeof(EVP_MD_CTX));
	EVP_DigestFinal(&ctx,out,&ret);
	return((int)ret);
	}

int tls1_final_finish_mac(s,in1_ctx,in2_ctx,str,slen,out)
SSL *s;
EVP_MD_CTX *in1_ctx,*in2_ctx;
unsigned char *str;
int slen;
unsigned char *out;
	{
	unsigned int i;
	EVP_MD_CTX ctx;
	unsigned char buf[TLS_MD_MAX_CONST_SIZE+MD5_DIGEST_LENGTH+SHA_DIGEST_LENGTH];
	unsigned char *q,buf2[12];

	q=buf;
	memcpy(q,str,slen);
	q+=slen;

	memcpy(&ctx,in1_ctx,sizeof(EVP_MD_CTX));
	EVP_DigestFinal(&ctx,q,&i);
	q+=i;
	memcpy(&ctx,in2_ctx,sizeof(EVP_MD_CTX));
	EVP_DigestFinal(&ctx,q,&i);
	q+=i;

	tls1_PRF(s->ctx->md5,s->ctx->sha1,buf,(short)(q-buf),
		s->session->master_key,s->session->master_key_length,
		out,buf2,12);
	memset(&ctx,0,sizeof(EVP_MD_CTX));

	return((int)12);
	}

int tls1_mac(ssl,md,send)
SSL *ssl;
unsigned char *md;
int send;
	{
	SSL3_RECORD *rec;
	unsigned char *mac_sec,*seq;
	EVP_MD *hash;
	unsigned int md_size;
	int i;
	HMAC_CTX hmac;
	unsigned char buf[5]; 

	if (send)
		{
		rec= &(ssl->s3->wrec);
		mac_sec= &(ssl->s3->write_mac_secret[0]);
		seq= &(ssl->s3->write_sequence[0]);
		hash=ssl->write_hash;
		}
	else
		{
		rec= &(ssl->s3->rrec);
		mac_sec= &(ssl->s3->read_mac_secret[0]);
		seq= &(ssl->s3->read_sequence[0]);
		hash=ssl->read_hash;
		}

	md_size=EVP_MD_size(hash);

	buf[0]=rec->type;
	buf[1]=TLS1_VERSION_MAJOR;
	buf[2]=TLS1_VERSION_MINOR;
	buf[3]=rec->length>>8;
	buf[4]=rec->length&0xff;

	/* I should fix this up TLS TLS TLS TLS TLS XXXXXXXX */
	HMAC_Init(&hmac,mac_sec,EVP_MD_size(hash),hash);
	HMAC_Update(&hmac,seq,8);
	HMAC_Update(&hmac,buf,5);
	HMAC_Update(&hmac,rec->input,rec->length);
	HMAC_Final(&hmac,md,&md_size);

#ifdef TLS_DEBUG
printf("sec=");
{int z; for (z=0; z<md_size; z++) printf("%02X ",mac_sec[z]); printf("\n"); }
printf("seq=");
{int z; for (z=0; z<8; z++) printf("%02X ",seq[z]); printf("\n"); }
printf("buf=");
{int z; for (z=0; z<5; z++) printf("%02X ",buf[z]); printf("\n"); }
printf("rec=");
{int z; for (z=0; z<rec->length; z++) printf("%02X ",buf[z]); printf("\n"); }
#endif

	for (i=7; i>=0; i--)
		if (++seq[i]) break; 

#ifdef TLS_DEBUG
{int z; for (z=0; z<md_size; z++) printf("%02X ",md[z]); printf("\n"); }
#endif
	return(md_size);
	}

int tls1_generate_master_secret(s,out,p,len)
SSL *s;
unsigned char *out;
unsigned char *p;
int len;
	{
	unsigned char buf[SSL3_RANDOM_SIZE*2+TLS_MD_MASTER_SECRET_CONST_SIZE];
	unsigned char buff[SSL_MAX_MASTER_KEY_LENGTH];

	/* Setup the stuff to munge */
	memcpy(buf,TLS_MD_MASTER_SECRET_CONST,
		TLS_MD_MASTER_SECRET_CONST_SIZE);
	memcpy(&(buf[TLS_MD_MASTER_SECRET_CONST_SIZE]),
		s->s3->client_random,SSL3_RANDOM_SIZE);
	memcpy(&(buf[SSL3_RANDOM_SIZE+TLS_MD_MASTER_SECRET_CONST_SIZE]),
		s->s3->server_random,SSL3_RANDOM_SIZE);
	tls1_PRF(s->ctx->md5,s->ctx->sha1,
		buf,TLS_MD_MASTER_SECRET_CONST_SIZE+SSL3_RANDOM_SIZE*2,p,len,
		s->session->master_key,buff,SSL3_MASTER_SECRET_SIZE);
	return(SSL3_MASTER_SECRET_SIZE);
	}

int tls1_alert_code(code)
int code;
	{
	switch (code)
		{
	case SSL_AD_CLOSE_NOTIFY:	return(SSL3_AD_CLOSE_NOTIFY);
	case SSL_AD_UNEXPECTED_MESSAGE:	return(SSL3_AD_UNEXPECTED_MESSAGE);
	case SSL_AD_BAD_RECORD_MAC:	return(SSL3_AD_BAD_RECORD_MAC);
	case SSL_AD_DECRYPTION_FAILED:	return(TLS1_AD_DECRYPTION_FAILED);
	case SSL_AD_RECORD_OVERFLOW:	return(TLS1_AD_RECORD_OVERFLOW);
	case SSL_AD_DECOMPRESSION_FAILURE:return(SSL3_AD_DECOMPRESSION_FAILURE);
	case SSL_AD_HANDSHAKE_FAILURE:	return(SSL3_AD_HANDSHAKE_FAILURE);
	case SSL_AD_NO_CERTIFICATE:	return(-1);
	case SSL_AD_BAD_CERTIFICATE:	return(SSL3_AD_BAD_CERTIFICATE);
	case SSL_AD_UNSUPPORTED_CERTIFICATE:return(SSL3_AD_UNSUPPORTED_CERTIFICATE);
	case SSL_AD_CERTIFICATE_REVOKED:return(SSL3_AD_CERTIFICATE_REVOKED);
	case SSL_AD_CERTIFICATE_EXPIRED:return(SSL3_AD_CERTIFICATE_EXPIRED);
	case SSL_AD_CERTIFICATE_UNKNOWN:return(SSL3_AD_CERTIFICATE_UNKNOWN);
	case SSL_AD_ILLEGAL_PARAMETER:	return(SSL3_AD_ILLEGAL_PARAMETER);
	case SSL_AD_UNKNOWN_CA:		return(TLS1_AD_UNKNOWN_CA);
	case SSL_AD_ACCESS_DENIED:	return(TLS1_AD_ACCESS_DENIED);
	case SSL_AD_DECODE_ERROR:	return(TLS1_AD_DECODE_ERROR);
	case SSL_AD_DECRYPT_ERROR:	return(TLS1_AD_DECRYPT_ERROR);
	case SSL_AD_EXPORT_RESTRICION:	return(TLS1_AD_EXPORT_RESTRICION);
	case SSL_AD_PROTOCOL_VERSION:	return(TLS1_AD_PROTOCOL_VERSION);
	case SSL_AD_INSUFFICIENT_SECURITY:return(TLS1_AD_INSUFFICIENT_SECURITY);
	case SSL_AD_INTERNAL_ERROR:	return(TLS1_AD_INTERNAL_ERROR);
	case SSL_AD_USER_CANCLED:	return(TLS1_AD_USER_CANCLED);
	case SSL_AD_NO_RENEGOTIATION:	return(TLS1_AD_NO_RENEGOTIATION);
	default:			return(-1);
		}
	}

#endif
