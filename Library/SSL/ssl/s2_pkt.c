/* ssl/s2_pkt.c */
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
#include <errno.h>
#define USE_SOCKETS
#include "ssl_locl.h"

/* SSLerr(SSL_F_GET_SERVER_HELLO,SSL_R_PEER_ERROR_NO_CIPHER);
 * SSLerr(SSL_F_GET_SERVER_HELLO,SSL_R_PEER_ERROR_NO_CERTIFICATE);
 * SSLerr(SSL_F_GET_SERVER_HELLO,SSL_R_PEER_ERROR_CERTIFICATE);
 * SSLerr(SSL_F_GET_SERVER_HELLO,SSL_R_PEER_ERROR_UNSUPPORTED_CERTIFICATE_TYPE);
 * SSLerr(SSL_F_GET_SERVER_HELLO,SSL_R_UNKNOWN_REMOTE_ERROR_TYPE);
 */

#ifndef NOPROTO
static int read_n(SSL *s,unsigned int n,unsigned int max,unsigned int extend);
static int do_ssl_write(SSL *s, char *buf, unsigned int len);
static int write_pending(SSL *s, char *buf, unsigned int len);
static int ssl_mt_error(int n);
#else
static int read_n();
static int do_ssl_write();
static int write_pending();
static int ssl_mt_error();
#endif

#ifndef COMPILE_OPTION_HOST_SERVICE_ONLY

#ifndef GEOS_CLIENT

int ssl2_peek(s,buf,len)
SSL *s;
char *buf;
int len;
	{
	int ret;

	ret=ssl2_read(s,buf,len);
	if (ret > 0)
	        {
		s->s2->ract_data_length+=ret;
#ifdef GEOS_MEM
#error This does not work
#else
		s->s2->ract_data-=ret;
#endif
		}
	return(ret);
	}

#endif /* GEOS_CLIENT */

/* SSL_read -
 * This routine will return 0 to len bytes, decrypted etc if required.
 */
int ssl2_read(s, buf, len)
SSL *s;
char *buf;
int len;
	{
	int n;
	unsigned char mac[MAX_MAC_SIZE];
	unsigned char *p;
	int i;
	unsigned int mac_size=0;
#ifdef GEOS_MEM
	int ret;
	MemHandle checkSpace;
#endif

#ifdef GEOS_MEM
	if (MemGetInfo(s->s2->rbufH, MGIT_ADDRESS) == 0) {
	    if ((checkSpace = MemAlloc(MemGetInfo(s->s2->rbufH,
						  MGIT_SIZE),
				       HF_DYNAMIC,
				       HAF_STANDARD_LOCK)) == NULL) {
		SSLerr(SSL_F_SSL2_READ,ERR_R_MALLOC_FAILURE);
		return(-1);
	    } else {
		MemFree(checkSpace);
	    }
	}
	if ((s->s2->rbuf = MemLock(s->s2->rbufH)) == NULL) {
	    s->s2->rbuf = (void *)-1;
	    SSLerr(SSL_F_SSL2_READ,ERR_R_MALLOC_FAILURE);
	    return(-1);
	} else {
	    (dword)s->packet += (dword)MemDeref(s->s2->rbufH);
	    (dword)s->s2->ract_data += (dword)MemDeref(s->s2->rbufH);
	    (dword)s->s2->mac_data += (dword)MemDeref(s->s2->rbufH);
	    (dword)s->s2->pad_data += (dword)MemDeref(s->s2->rbufH);
	}
#endif

	if (SSL_in_init(s) && !s->in_handshake)
		{
#ifdef __GEOS__
		n=CALLCB1(s->handshake_func,s);
#else
		n=s->handshake_func(s);
#endif
#ifdef GEOS_MEM
		if (n < 0) {
		    ret = n;
		    goto retIt;
		}
#else
		if (n < 0) return(n);
#endif
		if (n == 0)
			{
			SSLerr(SSL_F_SSL2_READ,SSL_R_SSL_HANDSHAKE_FAILURE);
#ifdef GEOS_MEM
			goto retErr;
#else
			return(-1);
#endif
			}
		}

	clear_sys_error();
	s->rwstate=SSL_NOTHING;
	if (len <= 0) return(len);

	if (s->s2->ract_data_length != 0) /* read from buffer */
		{
		if (len > s->s2->ract_data_length)
			n=s->s2->ract_data_length;
		else
			n=len;

		memcpy(buf,s->s2->ract_data,(unsigned int)n);
		s->s2->ract_data_length-=n;
		s->s2->ract_data+=n;
		if (s->s2->ract_data_length == 0)
			s->rstate=SSL_ST_READ_HEADER;
#ifdef GEOS_MEM
		ret = n;
		goto retIt;
#else
		return(n);
#endif
		}

	if (s->rstate == SSL_ST_READ_HEADER)
		{
		if (s->first_packet)
			{
			n=read_n(s,5,SSL2_MAX_RECORD_LENGTH_2_BYTE_HEADER+2,0);
#ifdef GEOS_MEM
			if (n <= 0) {ret = n; goto retIt;}
#else
			if (n <= 0) return(n); /* error or non-blocking */
#endif
			s->first_packet=0;
			p=s->packet;
			if (!((p[0] & 0x80) && (
				(p[2] == SSL2_MT_CLIENT_HELLO) ||
				(p[2] == SSL2_MT_SERVER_HELLO))))
				{
				SSLerr(SSL_F_SSL2_READ,SSL_R_NON_SSLV2_INITIAL_PACKET);
#ifdef GEOS_MEM
				goto retErr;
#else
				return(-1);
#endif
				}
			}
		else
			{
			n=read_n(s,2,SSL2_MAX_RECORD_LENGTH_2_BYTE_HEADER+2,0);
#ifdef GEOS_MEM
			if (n <= 0) {ret = n; goto retIt;}
#else
			if (n <= 0) return(n); /* error or non-blocking */
#endif
			}
		/* part read stuff */

		s->rstate=SSL_ST_READ_BODY;
		p=s->packet;
		/* Do header */
		/*s->s2->padding=0;*/
		s->s2->escape=0;
		s->s2->rlength=(((unsigned int)p[0])<<8)|((unsigned int)p[1]);
		if ((p[0] & TWO_BYTE_BIT))		/* Two byte header? */
			{
			s->s2->three_byte_header=0;
			s->s2->rlength&=TWO_BYTE_MASK;	
			}
		else
			{
			s->s2->three_byte_header=1;
			s->s2->rlength&=THREE_BYTE_MASK;

			/* security >s2->escape */
			s->s2->escape=((p[0] & SEC_ESC_BIT))?1:0;
			}
		}

	if (s->rstate == SSL_ST_READ_BODY)
		{
		n=s->s2->rlength+2+s->s2->three_byte_header;
		if (n > (int)s->packet_length)
			{
			n-=s->packet_length;
			i=read_n(s,(unsigned int)n,(unsigned int)n,1);
#ifdef GEOS_MEM
			if (i <= 0) {ret = i; goto retIt;}
#else
			if (i <= 0) return(i); /* ERROR */
#endif
			}

		p= &(s->packet[2]);
		s->rstate=SSL_ST_READ_HEADER;
		if (s->s2->three_byte_header)
			s->s2->padding= *(p++);
		else	s->s2->padding=0;

		/* Data portion */
		if (s->s2->clear_text)
			{
			s->s2->mac_data=p;
			s->s2->ract_data=p;
			s->s2->pad_data=NULL;
			}
		else
			{
			mac_size=EVP_MD_size(s->read_hash);
			s->s2->mac_data=p;
			s->s2->ract_data= &p[mac_size];
			s->s2->pad_data= &p[mac_size+
				s->s2->rlength-s->s2->padding];
			}

		s->s2->ract_data_length=s->s2->rlength;
		/* added a check for length > max_size in case
		 * encryption was not turned on yet due to an error */
		if ((!s->s2->clear_text) &&
			(s->s2->rlength >= mac_size))
			{
			ssl2_enc(s,0);
			s->s2->ract_data_length-=mac_size;
			ssl2_mac(s,mac,0);
			s->s2->ract_data_length-=s->s2->padding;
			if (	(memcmp(mac,s->s2->mac_data,
				(unsigned int)mac_size) != 0) ||
				(s->s2->rlength%EVP_CIPHER_CTX_block_size(s->enc_read_ctx) != 0))
				{
				SSLerr(SSL_F_SSL2_READ,SSL_R_BAD_MAC_DECODE);
#ifdef GEOS_MEM
				goto retErr;
#else
				return(-1);
#endif
				}
			}
		INC32(s->s2->read_sequence); /* expect next number */
		/* s->s2->ract_data is now available for processing */

		/* If a 0 byte packet was sent, return 0, otherwise
		 * we play havoc with people using select with
		 * blocking sockets.  Let them handle a packet at a time,
		 * they should really be using non-blocking sockets. */
#ifdef GEOS_MEM
		if (s->s2->ract_data_length == 0)
			{ret = 0; goto retIt;}
		/* unlock read buffer before recurse */
		if (PtrToSegment(s->packet) != PtrToSegment(MemDeref(s->s2->rbufH))) abort();
		if (PtrToSegment(s->s2->ract_data) != PtrToSegment(MemDeref(s->s2->rbufH))) abort();
		(dword)s->packet -= (dword)MemDeref(s->s2->rbufH);
		(dword)s->s2->ract_data -= (dword)MemDeref(s->s2->rbufH);
		(dword)s->s2->mac_data -= (dword)MemDeref(s->s2->rbufH);
		(dword)s->s2->pad_data -= (dword)MemDeref(s->s2->rbufH);
		s->s2->rbuf = (void *)-1;
		MemUnlock(s->s2->rbufH);
		return(ssl2_read(s,buf,len));
retErr:
		ret = -1;
retIt:
		if (PtrToSegment(s->packet) != PtrToSegment(MemDeref(s->s2->rbufH))) abort();
		if (PtrToSegment(s->s2->ract_data) != PtrToSegment(MemDeref(s->s2->rbufH))) abort();
		(dword)s->packet -= (dword)MemDeref(s->s2->rbufH);
		(dword)s->s2->ract_data -= (dword)MemDeref(s->s2->rbufH);
		s->s2->rbuf = (void *)-1;
		MemUnlock(s->s2->rbufH);
		/* for some reason the compiled ASM code doesn't
		   work if we don't have this 'nop' */
		/*asm{nop};*/
		return (ret);
#else
		if (s->s2->ract_data_length == 0)
			return(0);
		return(ssl2_read(s,buf,len));
#endif
		}
	else
		{
		SSLerr(SSL_F_SSL2_READ,SSL_R_BAD_STATE);
#ifdef GEOS_MEM
			goto retErr;
#else
			return(-1);
#endif
		}
	}

static int read_n(s, n, max, extend)
SSL *s;
unsigned int n;
unsigned int max;
unsigned int extend;
	{
	int i,off,newb;

	/* if there is stuff still in the buffer from a previous read,
	 * and there is more than we want, take some. */
	if (s->s2->rbuf_left >= (int)n)
		{
		if (extend)
			s->packet_length+=n;
		else
			{
			s->packet= &(s->s2->rbuf[s->s2->rbuf_offs]);
			s->packet_length=n;
			}
		s->s2->rbuf_left-=n;
		s->s2->rbuf_offs+=n;
		return(n);
		}

	if (!s->read_ahead) max=n;
	if (max > (unsigned int)(SSL2_MAX_RECORD_LENGTH_2_BYTE_HEADER+2))
		max=SSL2_MAX_RECORD_LENGTH_2_BYTE_HEADER+2;
	

	/* Else we want more than we have.
	 * First, if there is some left or we want to extend */
	off=0;
	if ((s->s2->rbuf_left != 0) || ((s->packet_length != 0) && extend))
		{
		newb=s->s2->rbuf_left;
		if (extend)
			{
			off=s->packet_length;
			if (s->packet != s->s2->rbuf)
				memcpy(s->s2->rbuf,s->packet,
					(unsigned int)newb+off);
			}
		else if (s->s2->rbuf_offs != 0)
			{
			memcpy(s->s2->rbuf,&(s->s2->rbuf[s->s2->rbuf_offs]),
				(unsigned int)newb);
			s->s2->rbuf_offs=0;
			}
		s->s2->rbuf_left=0;
		}
	else
		newb=0;

	/* off is the offset to start writing too.
	 * r->s2->rbuf_offs is the 'unread data', now 0. 
	 * newb is the number of new bytes so far
	 */
	s->packet=s->s2->rbuf;
	while (newb < (int)n)
		{
		clear_sys_error();
		if (s->rbio != NULL)
			{
			s->rwstate=SSL_READING;
#ifdef GEOS_MEM
			/*
			 * ensure read buffer size
			 */
			if ((&(s->s2->rbuf[off+newb]) - MemDeref(s->s2->rbufH) + (max-newb)) > MemGetInfo(s->s2->rbufH, MGIT_SIZE)) {
			    if (PtrToSegment(s->packet) != PtrToSegment(MemDeref(s->s2->rbufH))) abort();
			    if (PtrToSegment(s->s2->ract_data) != PtrToSegment(MemDeref(s->s2->rbufH))) abort();
			    (dword)s->s2->rbuf -= (dword)MemDeref(s->s2->rbufH);
			    (dword)s->packet -= (dword)MemDeref(s->s2->rbufH);
			    (dword)s->s2->ract_data -= (dword)MemDeref(s->s2->rbufH);
			    (dword)s->s2->mac_data -= (dword)MemDeref(s->s2->rbufH);
			    (dword)s->s2->pad_data -= (dword)MemDeref(s->s2->rbufH);
			    /* remains locked */
			    if (MemReAlloc(s->s2->rbufH, (word)((&(s->s2->rbuf[off+newb]) + (max-newb))), HAF_STANDARD) == 0) {
				SSLerr(SSL_F_READ_N,ERR_R_MALLOC_FAILURE);
				return(-1);
			    }
			    (dword)s->s2->rbuf += (dword)MemDeref(s->s2->rbufH);
			    (dword)s->packet += (dword)MemDeref(s->s2->rbufH);
			    (dword)s->s2->ract_data += (dword)MemDeref(s->s2->rbufH);
			    (dword)s->s2->mac_data += (dword)MemDeref(s->s2->rbufH);
			    (dword)s->s2->pad_data += (dword)MemDeref(s->s2->rbufH);
			}
#endif
			i=BIO_read(s->rbio,(char *)&(s->s2->rbuf[off+newb]),
				max-newb);
			}
		else
			{
			SSLerr(SSL_F_READ_N,SSL_R_READ_BIO_NOT_SET);
			i= -1;
			}
#ifdef PKT_DEBUG
		if (s->debug & 0x01) sleep(1);
#endif
		if (i <= 0)
			{
			s->s2->rbuf_left+=newb;
			return(i);
			}
		newb+=i;
		}

	/* record unread data */
	if (newb > (int)n)
		{
		s->s2->rbuf_offs=n+off;
		s->s2->rbuf_left=newb-n;
		}
	else
		{
		s->s2->rbuf_offs=0;
		s->s2->rbuf_left=0;
		}
	if (extend)
		s->packet_length+=n;
	else
		s->packet_length=n;
	s->rwstate=SSL_NOTHING;
	return(n);
	}

int ssl2_write(s, buf, len)
SSL *s;
char *buf;
int len;
	{
	unsigned int n,tot;
	int i;

	if (SSL_in_init(s) && !s->in_handshake)
		{
#ifdef __GEOS__
		i=CALLCB1(s->handshake_func,s);
#else
		i=s->handshake_func(s);
#endif
		if (i < 0) return(i);
		if (i == 0)
			{
			SSLerr(SSL_F_SSL2_WRITE,SSL_R_SSL_HANDSHAKE_FAILURE);
			return(-1);
			}
		}

	if (s->error)
		{
		ssl2_write_error(s);
		if (s->error)
			return(-1);
		}

	clear_sys_error();
	s->rwstate=SSL_NOTHING;
	if (len <= 0) return(len);

	tot=s->s2->wnum;
	s->s2->wnum=0;

	n=(len-tot);
	for (;;)
		{
		i=do_ssl_write(s,&(buf[tot]),n);
		if (i <= 0)
			{
			s->s2->wnum=tot;
			return(i);
			}
		if (i == (int)n) return(tot+i);

		n-=i;
		tot+=i;
		}
	}

static int write_pending(s,buf,len)
SSL *s;
char *buf;
unsigned int len;
	{
	int i;

	/* s->s2->wpend_len != 0 MUST be true. */

	/* check that they have given us the same buffer to
	 * write */
	if ((s->s2->wpend_tot > (int)len) || (s->s2->wpend_buf != buf))
		{
		SSLerr(SSL_F_WRITE_PENDING,SSL_R_BAD_WRITE_RETRY);
		return(-1);
		}

	for (;;)
		{
		clear_sys_error();
		if (s->wbio != NULL)
			{
			s->rwstate=SSL_WRITING;
			i=BIO_write(s->wbio,
				(char *)&(s->s2->write_ptr[s->s2->wpend_off]),
				(unsigned int)s->s2->wpend_len);
			}
		else
			{
			SSLerr(SSL_F_WRITE_PENDING,SSL_R_WRITE_BIO_NOT_SET);
			i= -1;
			}
#ifdef PKT_DEBUG
		if (s->debug & 0x01) sleep(1);
#endif
		if (i == s->s2->wpend_len)
			{
			s->s2->wpend_len=0;
			s->rwstate=SSL_NOTHING;
			return(s->s2->wpend_ret);
			}
		else if (i <= 0)
			return(i);
		s->s2->wpend_off+=i;
		s->s2->wpend_len-=i;
		}
	}

static int do_ssl_write(s, buf, len)
SSL *s;
char *buf;
unsigned int len;
	{
	unsigned int j,k,olen,p,mac_size,bs;
	register unsigned char *pp;
#ifdef GEOS_MEM
	int ret;
	MemHandle checkSpace;
#endif

#ifdef GEOS_MEM
	if (MemGetInfo(s->s2->wbufH, MGIT_ADDRESS) == 0) {
	    if ((checkSpace = MemAlloc(MemGetInfo(s->s2->wbufH,
						  MGIT_SIZE),
				       HF_DYNAMIC,
				       HAF_STANDARD_LOCK)) == NULL) {
		SSLerr(SSL_F_SSL2_WRITE,ERR_R_MALLOC_FAILURE);
		return(-1);
	    } else {
		MemFree(checkSpace);
	    }
	}
	if ((s->s2->wbuf = MemLock(s->s2->wbufH)) == NULL) {
	    s->s2->wbuf = (void *)-1;
	    SSLerr(SSL_F_SSL2_WRITE,ERR_R_MALLOC_FAILURE);
	    return(-1);
	} else {
	    (dword)s->s2->wact_data += (dword)MemDeref(s->s2->wbufH);
	}
#endif

	olen=len;

	/* first check if there is data from an encryption waiting to
	 * be sent - it must be sent because the other end is waiting.
	 * This will happen with non-blocking IO.  We print it and then
	 * return.
	 */
#ifdef GEOS_MEM
	if (s->s2->wpend_len != 0) {ret = write_pending(s,buf,len); goto retIt;}
#else
	if (s->s2->wpend_len != 0) return(write_pending(s,buf,len));
#endif

	/* set mac_size to mac size */
	if (s->s2->clear_text)
		mac_size=0;
	else
		mac_size=EVP_MD_size(s->write_hash);

	/* lets set the pad p */
	if (s->s2->clear_text)
		{
		if (len > SSL2_MAX_RECORD_LENGTH_2_BYTE_HEADER)
			len=SSL2_MAX_RECORD_LENGTH_2_BYTE_HEADER;
		p=0;
		s->s2->three_byte_header=0;
		/* len=len; */
		}
	else
		{
		bs=EVP_CIPHER_CTX_block_size(s->enc_read_ctx);
		j=len+mac_size;
		if ((j > SSL2_MAX_RECORD_LENGTH_3_BYTE_HEADER) &&
			(!s->s2->escape))
			{
			if (j > SSL2_MAX_RECORD_LENGTH_2_BYTE_HEADER)
				j=SSL2_MAX_RECORD_LENGTH_2_BYTE_HEADER;
			/* set k to the max number of bytes with 2
			 * byte header */
			k=j-(j%bs);
			/* how many data bytes? */
			len=k-mac_size; 
			s->s2->three_byte_header=0;
			p=0;
			}
		else if ((bs <= 1) && (!s->s2->escape))
			{
			/* len=len; */
			s->s2->three_byte_header=0;
			p=0;
			}
		else /* 3 byte header */
			{
			/*len=len; */
			p=(j%bs);
			p=(p == 0)?0:(bs-p);
			if (s->s2->escape)
				s->s2->three_byte_header=1;
			else
				s->s2->three_byte_header=(p == 0)?0:1;
			}
		}
	/* mac_size is the number of MAC bytes
	 * len is the number of data bytes we are going to send
	 * p is the number of padding bytes
	 * if p == 0, it is a 2 byte header */

	s->s2->wlength=len;
	s->s2->padding=p;
	s->s2->mac_data= &(s->s2->wbuf[3]);
	s->s2->wact_data= &(s->s2->wbuf[3+mac_size]);
#ifdef GEOS_MEM
	/*
	 * ensure write buffer size
	 */
	if ((s->s2->wact_data - MemDeref(s->s2->wbufH) + (len+p)) > MemGetInfo(s->s2->wbufH, MGIT_SIZE)) {
	    if (PtrToSegment(s->s2->wbuf) != PtrToSegment(MemDeref(s->s2->wbufH))) abort();
	    if (PtrToSegment(s->s2->wact_data) != PtrToSegment(MemDeref(s->s2->wbufH))) abort();
	    (dword)s->s2->wbuf -= (dword)MemDeref(s->s2->wbufH);
	    (dword)s->s2->wact_data -= (dword)MemDeref(s->s2->wbufH);
	    (dword)s->s2->mac_data -= (dword)MemDeref(s->s2->wbufH);
	    /* remains locked */
	    if (MemReAlloc(s->s2->wbufH, (word)((s->s2->wact_data + (len+p))), HAF_STANDARD) == 0) {
		SSLerr(SSL_F_SSL2_WRITE,ERR_R_MALLOC_FAILURE);
		return(-1);
	    }
	    (dword)s->s2->wbuf += (dword)MemDeref(s->s2->wbufH);
	    (dword)s->s2->wact_data += (dword)MemDeref(s->s2->wbufH);
	    (dword)s->s2->mac_data += (dword)MemDeref(s->s2->wbufH);
	}
#endif
	/* we copy the data into s->s2->wbuf */
	memcpy(s->s2->wact_data,buf,len);
#ifdef PURIFY
	if (p)
		memset(&(s->s2->wact_data[len]),0,p);
#endif

	if (!s->s2->clear_text)
		{
		s->s2->wact_data_length=len+p;
		ssl2_mac(s,s->s2->mac_data,1);
		s->s2->wlength+=p+mac_size;
		ssl2_enc(s,1);
		}

	/* package up the header */
	s->s2->wpend_len=s->s2->wlength;
	if (s->s2->three_byte_header) /* 3 byte header */
		{
		pp=s->s2->mac_data;
		pp-=3;
		pp[0]=(s->s2->wlength>>8)&(THREE_BYTE_MASK>>8);
		if (s->s2->escape) pp[0]|=SEC_ESC_BIT;
		pp[1]=s->s2->wlength&0xff;
		pp[2]=s->s2->padding;
		s->s2->wpend_len+=3;
		}
	else
		{
		pp=s->s2->mac_data;
		pp-=2;
		pp[0]=((s->s2->wlength>>8)&(TWO_BYTE_MASK>>8))|TWO_BYTE_BIT;
		pp[1]=s->s2->wlength&0xff;
		s->s2->wpend_len+=2;
		}
	s->s2->write_ptr=pp;
	
	INC32(s->s2->write_sequence); /* expect next number */

	/* lets try to actually write the data */
	s->s2->wpend_tot=olen;
	s->s2->wpend_buf=(char *)buf;

	s->s2->wpend_ret=len;

	s->s2->wpend_off=0;
#ifdef GEOS_MEM
	ret = write_pending(s,buf,olen);
retIt:
	if (PtrToSegment(s->s2->wact_data) != PtrToSegment(MemDeref(s->s2->wbufH))) abort();
	(dword)s->s2->wact_data -= (dword)MemDeref(s->s2->wbufH);
	s->s2->wbuf = (void *)-1;
	MemUnlock(s->s2->wbufH);
	return(ret);
#else
	return(write_pending(s,buf,olen));
#endif
	}

int ssl2_part_read(s,f,i)
SSL *s;
unsigned long f;
int i;
	{
	unsigned char *p;
	int j;

	/* check for error */
	if ((s->init_num == 0) && (i >= 3))
		{
		p=(unsigned char *)s->init_buf->data;
		if (p[0] == SSL2_MT_ERROR)
			{
			j=(p[1]<<8)|p[2];
			SSLerr((int)f,ssl_mt_error(j));
			}
		}

	if (i < 0)
		{
		/* ssl2_return_error(s); */
		/* for non-blocking io,
		 * this is not fatal */
		return(i);
		}
	else
		{
		s->init_num+=i;
		return(0);
		}
	}

int ssl2_do_write(s)
SSL *s;
	{
	int ret;

	ret=ssl2_write(s,(char *)&(s->init_buf->data[s->init_off]),
		s->init_num);
	if (ret == s->init_num)
		return(1);
	if (ret < 0)
		return(-1);
	s->init_off+=ret;
	s->init_num-=ret;
	return(0);
	}

static int ssl_mt_error(n)
int n;
	{
	int ret;

	switch (n)
		{
	case SSL2_PE_NO_CIPHER:
		ret=SSL_R_PEER_ERROR_NO_CIPHER;
		break;
	case SSL2_PE_NO_CERTIFICATE:
		ret=SSL_R_PEER_ERROR_NO_CERTIFICATE;
		break;
	case SSL2_PE_BAD_CERTIFICATE:
		ret=SSL_R_PEER_ERROR_CERTIFICATE;
		break;
	case SSL2_PE_UNSUPPORTED_CERTIFICATE_TYPE:
		ret=SSL_R_PEER_ERROR_UNSUPPORTED_CERTIFICATE_TYPE;
		break;
	default:
		ret=SSL_R_UNKNOWN_REMOTE_ERROR_TYPE;
		break;
		}
	return(ret);
	}

#endif
