/* crypto/bio/bss_sock.c */
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

#if !defined(NO_SOCK) || defined(BIO_FD)

#ifdef __GEOS__
#include <Ansi/stdio.h>
#else
#include <stdio.h>
#endif
#include <errno.h>
#define USE_SOCKETS
#include "cryptlib.h"
#include "bio.h"

#ifndef BIO_FD
#ifndef NOPROTO
static int sock_write(BIO *h,char *buf,int num);
static int sock_read(BIO *h,char *buf,int size);
static int sock_puts(BIO *h,char *str);
static long sock_ctrl(BIO *h,int cmd,long arg1,char *arg2);
static int sock_new(BIO *h);
static int sock_free(BIO *data);
int BIO_sock_should_retry(int s);
#else
static int sock_write();
static int sock_read();
static int sock_puts();
static long sock_ctrl();
static int sock_new();
static int sock_free();
int BIO_sock_should_retry();
#endif

#else

#ifndef NOPROTO
static int fd_write(BIO *h,char *buf,int num);
static int fd_read(BIO *h,char *buf,int size);
static int fd_puts(BIO *h,char *str);
static long fd_ctrl(BIO *h,int cmd,long arg1,char *arg2);
static int fd_new(BIO *h);
static int fd_free(BIO *data);
int BIO_fd_should_retry(int s);
#else
static int fd_write();
static int fd_read();
static int fd_puts();
static long fd_ctrl();
static int fd_new();
static int fd_free();
int BIO_fd_should_retry();
#endif
#endif

#ifndef BIO_FD
static BIO_METHOD methods_sockp=
	{
	BIO_TYPE_SOCKET,
	"socket",
	sock_write,
	sock_read,
	sock_puts,
	NULL, /* sock_gets, */
	sock_ctrl,
	sock_new,
	sock_free,
	};

BIO_METHOD *BIO_s_socket()
	{
#ifdef __GEOS__
	BIO_METHOD *ret;
	PUSHDS;
	ret = &methods_sockp;
	POPDS;
	return(ret);
#else
	return(&methods_sockp);
#endif
	}
#else
static BIO_METHOD methods_fdp=
	{
	BIO_TYPE_FD,"file descriptor",
	fd_write,
	fd_read,
	fd_puts,
	NULL, /* fd_gets, */
	fd_ctrl,
	fd_new,
	fd_free,
	};

BIO_METHOD *BIO_s_fd()
	{
#ifdef __GEOS__
	BIO_METHOD *ret;
	PUSHDS;
	ret = &methods_fdp;
	POPDS;
	return(ret);
#else
	return(&methods_fdp);
#endif
	}
#endif

#ifndef BIO_FD
BIO *BIO_new_socket(fd,close_flag)
#else
BIO *BIO_new_fd(fd,close_flag)
#endif
int fd;
int close_flag;
	{
	BIO *ret;

#ifndef BIO_FD
	ret=BIO_new(BIO_s_socket());
#else
	ret=BIO_new(BIO_s_fd());
#endif
	if (ret == NULL) return(NULL);
	BIO_set_fd(ret,fd,close_flag);
	return(ret);
	}

#ifndef BIO_FD
static int sock_new(bi)
#else
static int fd_new(bi)
#endif
BIO *bi;
	{
	bi->init=0;
	bi->num=0;
	bi->ptr=NULL;
	bi->flags=0;
	return(1);
	}

#ifndef BIO_FD
static int sock_free(a)
#else
static int fd_free(a)
#endif
BIO *a;
	{
	if (a == NULL) return(0);
	if (a->shutdown)
		{
		if (a->init)
			{
#ifndef BIO_FD
#ifdef __GEOS__
/* XXX */
#else
			shutdown(a->num,2);
#endif
# ifdef WINDOWS
			closesocket(a->num);
# elif defined(__GEOS__)
			SocketClose((Socket)a->num);
# else
			close(a->num);
# endif
#else			/* BIO_FD */
			close(a->num);
#endif

			}
		a->init=0;
		a->flags=0;
		}
	return(1);
	}
	
#ifndef BIO_FD
static int sock_read(b,out,outl)
#else
static int fd_read(b,out,outl)
#endif
BIO *b;
char *out;
int outl;
	{
	int ret=0;

	if (out != NULL)
		{
#if defined(WINDOWS) && !defined(BIO_FD)
		clear_socket_error();
		ret=recv(b->num,out,outl,0);
#elif defined(__GEOS__)
		clear_sys_error();
		ret = SocketRecv((Socket)b->num, out, outl,
				 SOCKET_RECV_TIMEOUT, 0, 0);
		if (ThreadGetError() != SE_NORMAL) {
		    ret = -1;  /* indicate error */
		}
#else
		clear_sys_error();
		ret=read(b->num,out,outl);
#endif
		BIO_clear_retry_flags(b);
		if (ret <= 0)
			{
#ifndef BIO_FD
			if (BIO_sock_should_retry(ret))
#else
			if (BIO_fd_should_retry(ret))
#endif
				BIO_set_retry_read(b);
			}
		}
	return(ret);
	}

#ifndef BIO_FD
static int sock_write(b,in,inl)
#else
static int fd_write(b,in,inl)
#endif
BIO *b;
char *in;
int inl;
	{
	int ret;
	
#if defined(WINDOWS) && !defined(BIO_FD)
	clear_socket_error();
	ret=send(b->num,in,inl,0);
#elif defined(__GEOS__)
	clear_sys_error();
	ret = SocketSend((Socket)b->num, in, inl, 0, 0);
	if (ret == SE_NORMAL) {
	    ret = inl;  /* if no error, return bytes sent */
	} else {
	    ret = -1;  /* else, error */
	}
#else
	clear_sys_error();
	ret=write(b->num,in,inl);
#endif
	BIO_clear_retry_flags(b);
	if (ret <= 0)
		{
#ifndef BIO_FD
		if (BIO_sock_should_retry(ret))
#else
		if (BIO_fd_should_retry(ret))
#endif
			BIO_set_retry_write(b);
		}
	return(ret);
	}

#ifndef BIO_FD
static long sock_ctrl(b,cmd,num,ptr)
#else
static long fd_ctrl(b,cmd,num,ptr)
#endif
BIO *b;
int cmd;
long num;
char *ptr;
	{
	long ret=1;
	int *ip;

	switch (cmd)
		{
	case BIO_CTRL_RESET:
#ifdef BIO_FD
		ret=(long)lseek(b->num,0,0);
#else
		ret=0;
#endif
		break;
	case BIO_CTRL_INFO:
		ret=0;
		break;
	case BIO_C_SET_FD:
#ifndef BIO_FD
		sock_free(b);
#else
		fd_free(b);
#endif
		b->num= *((int *)ptr);
		b->shutdown=(int)num;
		b->init=1;
		break;
	case BIO_C_GET_FD:
		if (b->init)
			{
			ip=(int *)ptr;
			if (ip != NULL) *ip=b->num;
			ret=b->num;
			}
		else
			ret= -1;
		break;
	case BIO_CTRL_GET_CLOSE:
		ret=b->shutdown;
		break;
	case BIO_CTRL_SET_CLOSE:
		b->shutdown=(int)num;
		break;
	case BIO_CTRL_PENDING:
	case BIO_CTRL_WPENDING:
		ret=0;
		break;
	case BIO_CTRL_DUP:
	case BIO_CTRL_FLUSH:
		ret=1;
		break;
		break;
	default:
		ret=0;
		break;
		}
	return(ret);
	}

#ifdef undef
static int sock_gets(bp,buf,size)
BIO *bp;
char *buf;
int size;
	{
	return(-1);
	}
#endif

#ifndef BIO_FD
static int sock_puts(bp,str)
#else
static int fd_puts(bp,str)
#endif
BIO *bp;
char *str;
	{
	int n,ret;

	n=strlen(str);
#ifndef BIO_FD
	ret=sock_write(bp,str,n);
#else
	ret=fd_write(bp,str,n);
#endif
	return(ret);
	}

#ifndef BIO_FD
int BIO_sock_should_retry(i)
#else
int BIO_fd_should_retry(i)
#endif
int i;
	{
	int err;

	if ((i == 0) || (i == -1))
		{
#if !defined(BIO_FD) && defined(WINDOWS)
		err=get_last_socket_error();
#else
		err=get_last_sys_error();
#endif

#if defined(WINDOWS) /* more microsoft stupidity */
		if ((i == -1) && (err == 0))
			return(1);
#endif

#ifndef BIO_FD
		return(BIO_sock_non_fatal_error(err));
#else
		return(BIO_fd_non_fatal_error(err));
#endif
		}
	return(0);
	}

#ifndef BIO_FD
int BIO_sock_non_fatal_error(err)
#else
int BIO_fd_non_fatal_error(err)
#endif
int err;
	{
	switch (err)
		{
#if !defined(BIO_FD) && defined(WINDOWS)
# if defined(WSAEWOULDBLOCK)
	case WSAEWOULDBLOCK:
# endif

# if defined(WSAENOTCONN)
	case WSAENOTCONN:
# endif
#endif

#ifdef EWOULDBLOCK
# ifdef WSAEWOULDBLOCK
#  if WSAEWOULDBLOCK != EWOULDBLOCK
	case EWOULDBLOCK:
#  endif
# else
	case EWOULDBLOCK:
# endif
#endif

#if defined(ENOTCONN)
	case ENOTCONN:
#endif

#ifdef EINTR
	case EINTR:
#endif

#ifdef EAGAIN
#if EWOULDBLOCK != EAGAIN
	case EAGAIN:
# endif
#endif

#ifdef EPROTO
	case EPROTO:
#endif

#ifdef EINPROGRESS
	case EINPROGRESS:
#endif

#ifdef EALREADY
	case EALREADY:
#endif
		return(1);
		break;
	default:
		break;
		}
	return(0);
	}
#endif

#endif
