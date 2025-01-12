/* crypto/rand/md_rand.c */
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
#include <sys/types.h>
#ifdef __GEOS__
#include <timer.h>
#else
#include <time.h>
#endif

#if !defined(USE_MD5_RAND) && !defined(USE_SHA1_RAND) && !defined(USE_MDC2_RAND) && !defined(USE_MD2_RAND)
#ifndef NO_MD5
#define USE_MD5_RAND
#elif !defined(NO_SHA1)
#define USE_SHA1_RAND
#elif !defined(NO_MDC2)
#define USE_MDC2_RAND
#elif !defined(NO_MD2)
#define USE_MD2_RAND
#else
We need a message digest of some type 
#endif
#endif

/* Changed how the state buffer used.  I now attempt to 'wrap' such
 * that I don't run over the same locations the next time  go through
 * the 1023 bytes - many thanks to
 * Robert J. LeBlanc <rjl@renaissoft.com> for his comments
 */

#if defined(USE_MD5_RAND)
#include "md5.h"
#define MD_DIGEST_LENGTH	MD5_DIGEST_LENGTH
#define MD_CTX			MD5_CTX
#define MD_Init(a)		MD5_Init(a)
#define MD_Update(a,b,c)	MD5_Update(a,b,c)
#define	MD_Final(a,b)		MD5_Final(a,b)
#elif defined(USE_SHA1_RAND)
#include "sha.h"
#define MD_DIGEST_LENGTH	SHA_DIGEST_LENGTH
#define MD_CTX			SHA_CTX
#define MD_Init(a)		SHA1_Init(a)
#define MD_Update(a,b,c)	SHA1_Update(a,b,c)
#define	MD_Final(a,b)		SHA1_Final(a,b)
#elif defined(USE_MDC2_RAND)
#include "mdc2.h"
#define MD_DIGEST_LENGTH	MDC2_DIGEST_LENGTH
#define MD_CTX			MDC2_CTX
#define MD_Init(a)		MDC2_Init(a)
#define MD_Update(a,b,c)	MDC2_Update(a,b,c)
#define	MD_Final(a,b)		MDC2_Final(a,b)
#elif defined(USE_MD2_RAND)
#include "md2.h"
#define MD_DIGEST_LENGTH	MD2_DIGEST_LENGTH
#define MD_CTX			MD2_CTX
#define MD_Init(a)		MD2_Init(a)
#define MD_Update(a,b,c)	MD2_Update(a,b,c)
#define	MD_Final(a,b)		MD2_Final(a,b)
#endif

#include "rand.h"

/*#define NORAND	1 */
/*#define PREDICT	1 */

#define STATE_SIZE	1023
#ifdef GEOS_MEM
#define STATE_BLOCK_SIZE STATE_SIZE+MD_DIGEST_LENGTH
static MemHandle stateBlock = 0;
#else
static unsigned char state[STATE_SIZE+MD_DIGEST_LENGTH];
#endif
static int state_num=0,state_index=0;
static unsigned char md[MD_DIGEST_LENGTH];
static int md_count=0;

#ifndef GEOS_CLIENT
char *RAND_version="RAND part of SSLeay 0.9.0b 29-Jun-1998";
#endif

void RAND_cleanup()
	{
#ifdef GEOS_MEM
	char *state;
#endif
	PUSHDS;
#ifdef GEOS_MEM
	if (stateBlock) state = MemLock(stateBlock);
	if (stateBlock && state) {
	memset(state,0,STATE_BLOCK_SIZE);
#else
	memset(state,0,sizeof(state));
#endif
	state_num=0;
	state_index=0;
	memset(md,0,MD_DIGEST_LENGTH);
	md_count=0;
#ifdef GEOS_MEM
	MemUnlock(stateBlock);
	}
#endif
	POPDS;
	}

void RAND_seed(buf,num)
unsigned char *buf;
int num;
	{
	int i,j,k,st_idx,st_num;
	MD_CTX m;
#ifdef GEOS_MEM
	char *state;
#endif

#ifdef NORAND
	return;
#endif

	PUSHDS;
#ifdef GEOS_MEM
	if (!stateBlock) {
	    stateBlock = MemAlloc(STATE_BLOCK_SIZE, HF_DYNAMIC, HAF_STANDARD);
	}
	if (stateBlock) state = MemLock(stateBlock);
	if (stateBlock && state) {
#endif
	CRYPTO_w_lock(CRYPTO_LOCK_RAND);
	st_idx=state_index;
	st_num=state_num;

	state_index=(state_index+num);
	if (state_index >= STATE_SIZE)
		{
		state_index%=STATE_SIZE;
		state_num=STATE_SIZE;
		}
	else if (state_num < STATE_SIZE)	
		{
		if (state_index > state_num)
			state_num=state_index;
		}
	CRYPTO_w_unlock(CRYPTO_LOCK_RAND);

	for (i=0; i<num; i+=MD_DIGEST_LENGTH)
		{
		j=(num-i);
		j=(j > MD_DIGEST_LENGTH)?MD_DIGEST_LENGTH:j;

		MD_Init(&m);
		MD_Update(&m,md,MD_DIGEST_LENGTH);
		k=(st_idx+j)-STATE_SIZE;
		if (k > 0)
			{
			MD_Update(&m,&(state[st_idx]),j-k);
			MD_Update(&m,&(state[0]),k);
			}
		else
			MD_Update(&m,&(state[st_idx]),j);
			
		MD_Update(&m,buf,j);
		MD_Final(md,&m);

		buf+=j;

		for (k=0; k<j; k++)
			{
			state[st_idx++]^=md[k];
			if (st_idx >= STATE_SIZE)
				{
				st_idx=0;
				st_num=STATE_SIZE;
				}
			}
		}
	memset((char *)&m,0,sizeof(m));
#ifdef GEOS_MEM
	MemUnlock(stateBlock);
	}
#endif
	POPDS;
	}

void RAND_bytes(buf,num)
unsigned char *buf;
int num;
	{
	int i,j,k,st_num,st_idx;
	MD_CTX m;
	static int initRAND=1;
	unsigned long l;
#ifdef GEOS_MEM
	char *state;
#endif
#ifndef __GEOS__
#ifdef DEVRANDOM
	FILE *fh;
#endif
#endif

	PUSHDS;
#ifdef PREDICT
	{
	static unsigned char val=0;

	for (i=0; i<num; i++)
		buf[i]=val++;
	return;
	}
#endif
#ifdef GEOS_MEM
	if (stateBlock) state = MemLock(stateBlock);
	if (stateBlock && state) {
#endif

	CRYPTO_w_lock(CRYPTO_LOCK_RAND);

	if (initRAND)
		{
		initRAND=0;
		CRYPTO_w_unlock(CRYPTO_LOCK_RAND);
		/* put in some default random data, we need more than
		 * just this */
		RAND_seed((unsigned char *)&m,sizeof(m));
#ifdef __GEOS__
		l=(unsigned long)TimerGetCount();
#else
#ifndef MSDOS
		l=getpid();
		RAND_seed((unsigned char *)&l,sizeof(l));
		l=getuid();
		RAND_seed((unsigned char *)&l,sizeof(l));
#endif
		l=time(NULL);
#endif
		RAND_seed((unsigned char *)&l,sizeof(l));

#ifndef __GEOS__
/* #ifdef DEVRANDOM */
		/* 
		 * Use a random entropy pool device.
		 * Linux 1.3.x and FreeBSD-Current has 
		 * this. Use /dev/urandom if you can
		 * as /dev/random will block if it runs out
		 * of random entries.
		 */
		if ((fh = fopen(DEVRANDOM, "r")) != NULL)
			{
			unsigned char tmpbuf[32];

			fread((unsigned char *)tmpbuf,1,32,fh);
			/* we don't care how many bytes we read,
			 * we will just copy the 'stack' if there is
			 * nothing else :-) */
			fclose(fh);
			RAND_seed(tmpbuf,32);
			memset(tmpbuf,0,32);
			}
/* #endif */
#endif
#ifdef PURIFY
		memset(state,0,STATE_SIZE);
		memset(md,0,MD_DIGEST_LENGTH);
#endif
		CRYPTO_w_lock(CRYPTO_LOCK_RAND);
		}

	st_idx=state_index;
	st_num=state_num;
	state_index+=num;
	if (state_index > state_num)
		state_index=(state_index%state_num);

	CRYPTO_w_unlock(CRYPTO_LOCK_RAND);

	while (num > 0)
		{
		j=(num >= MD_DIGEST_LENGTH/2)?MD_DIGEST_LENGTH/2:num;
		num-=j;
		MD_Init(&m);
		MD_Update(&m,&(md[MD_DIGEST_LENGTH/2]),MD_DIGEST_LENGTH/2);
#ifndef PURIFY
		MD_Update(&m,buf,j); /* purify complains */
#endif
		k=(st_idx+j)-st_num;
		if (k > 0)
			{
			MD_Update(&m,&(state[st_idx]),j-k);
			MD_Update(&m,&(state[0]),k);
			}
		else
			MD_Update(&m,&(state[st_idx]),j);
		MD_Final(md,&m);

		for (i=0; i<j; i++)
			{
			if (st_idx >= st_num)
				st_idx=0;
			state[st_idx++]^=md[i];
			*(buf++)=md[i+MD_DIGEST_LENGTH/2];
			}
		}

	MD_Init(&m);
	MD_Update(&m,(unsigned char *)&md_count,sizeof(md_count)); md_count++;
	MD_Update(&m,md,MD_DIGEST_LENGTH);
	MD_Final(md,&m);
	memset(&m,0,sizeof(m));
#ifdef GEOS_MEM
	MemUnlock(stateBlock);
	}
#endif
	POPDS;
	}

#ifdef WINDOWS
#include <windows.h>
#include <rand.h>

/*****************************************************************************
 * Initialisation function for the SSL random generator.  Takes the contents
 * of the screen as random seed.
 *
 * Created 960901 by Gertjan van Oosten, gertjan@West.NL, West Consulting B.V.
 *
 * Code adapted from
 * <URL:http://www.microsoft.com/kb/developr/win_dk/q97193.htm>;
 * the original copyright message is:
 *
//   (C) Copyright Microsoft Corp. 1993.  All rights reserved.
//
//   You have a royalty-free right to use, modify, reproduce and
//   distribute the Sample Files (and/or any modified version) in
//   any way you find useful, provided that you agree that
//   Microsoft has no warranty obligations or liability for any
//   Sample Application Files which are modified.
 */
/*
 * I have modified the loading of bytes via RAND_seed() mechanism since
 * the origional would have been very very CPU intensive since RAND_seed()
 * does an MD5 per 16 bytes of input.  The cost to digest 16 bytes is the same
 * as that to digest 56 bytes.  So under the old system, a screen of
 * 1024*768*256 would have been CPU cost of approximatly 49,000 56 byte MD5
 * digests or digesting 2.7 mbytes.  What I have put in place would
 * be 48 16k MD5 digests, or efectivly 48*16+48 MD5 bytes or 816 kbytes
 * or about 3.5 times as much.
 * - eric 
 */
void RAND_screen(void)
{
  HDC		hScrDC;		/* screen DC */
  HDC		hMemDC;		/* memory DC */
  HBITMAP	hBitmap;	/* handle for our bitmap */
  HBITMAP	hOldBitmap;	/* handle for previous bitmap */
  BITMAP	bm;		/* bitmap properties */
  unsigned int	size;		/* size of bitmap */
  char		*bmbits;	/* contents of bitmap */
  int		w;		/* screen width */
  int		h;		/* screen height */
  int		y;		/* y-coordinate of screen lines to grab */
  int		n = 16;		/* number of screen lines to grab at a time */

  /* Create a screen DC and a memory DC compatible to screen DC */
  hScrDC = CreateDC("DISPLAY", NULL, NULL, NULL);
  hMemDC = CreateCompatibleDC(hScrDC);

  /* Get screen resolution */
  w = GetDeviceCaps(hScrDC, HORZRES);
  h = GetDeviceCaps(hScrDC, VERTRES);

  /* Create a bitmap compatible with the screen DC */
  hBitmap = CreateCompatibleBitmap(hScrDC, w, n);

  /* Select new bitmap into memory DC */
  hOldBitmap = SelectObject(hMemDC, hBitmap);

  /* Get bitmap properties */
  GetObject(hBitmap, sizeof(BITMAP), (LPSTR)&bm);
  size = (unsigned int)bm.bmWidthBytes * bm.bmHeight * bm.bmPlanes;

  bmbits = Malloc(size);
  if (bmbits) {
    /* Now go through the whole screen, repeatedly grabbing n lines */
    for (y = 0; y < h-n; y += n)
    	{
	unsigned char md[MD_DIGEST_LENGTH];

	/* Bitblt screen DC to memory DC */
	BitBlt(hMemDC, 0, 0, w, n, hScrDC, 0, y, SRCCOPY);

	/* Copy bitmap bits from memory DC to bmbits */
	GetBitmapBits(hBitmap, size, bmbits);

	/* Get the MD5 of the bitmap */
	MD5(bmbits,size,md);

	/* Seed the random generator with the MD5 digest */
	RAND_seed(md, MD_DIGEST_LENGTH);
	}

    Free(bmbits);
  }

  /* Select old bitmap back into memory DC */
  hBitmap = SelectObject(hMemDC, hOldBitmap);

  /* Clean up */
  DeleteObject(hBitmap);
  DeleteDC(hMemDC);
  DeleteDC(hScrDC);
}
#endif

#endif