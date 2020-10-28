/***********************************************************************
 *
 *	Copyright (c) Global PC 1998 -- All Rights Reserved
 *
 *			GLOBAL PC CONFIDENTIAL
 *
 * PROJECT:	  Socket
 * MODULE:	  PPP Driver
 * FILE:	  md4.c
 *
 * AUTHOR:  	  Brian Chin: October 6, 1998
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	MD4Init
 *	MD4Update
 *	MD4Final
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	10/6/98	  brianc    Initial version
 *
 * DESCRIPTION:
 *	MD4 message-digest algorithm.
 *
 * 	$Id$
 *
 ***********************************************************************/

/* Copyright (C) 1991-2, RSA Data Security, Inc. Created 1991. All
   rights reserved.

   License to copy and use this software is granted provided that it
   is identified as the "RSA Data Security, Inc. MD5 Message-Digest
   Algorithm" in all material mentioning or referencing this software
   or this function.

   License is also granted to make and use derivative works provided
   that such works are identified as "derived from the RSA Data
   Security, Inc. MD5 Message-Digest Algorithm" in all material
   mentioning or referencing the derived work.

   RSA Data Security, Inc. makes no representations concerning either
   the merchantability of this software or the suitability of this
   software for any particular purpose. It is provided "as is"
   without express or implied warranty of any kind.

   These notices must be retained in any copies of any part of this
   documentation and/or software.
 */

#ifdef __HIGHC__
#pragma Comment("@" __FILE__)
#endif

# include <geos.h>
# include <Ansi/string.h>
# include "md4.h"

#ifdef __HIGHC__
# pragma Code("MD4CODE");
#endif
#ifdef __BORLANDC__
#pragma codeseg MD4CODE
#endif
#ifdef __WATCOMC__
#pragma code_seg("MD4CODE")
#endif

/*
 * Compile-time declarations of MD4 "magic constants".
 */
#define I0  0x67452301       /* Initial values for MD buffer */
#define I1  0xefcdab89
#define I2  0x98badcfe
#define I3  0x10325476
#define C2  013240474631     /* round 2 constant = sqrt(2) in octal */
#define C3  015666365641     /* round 3 constant = sqrt(3) in octal */
/* C2 and C3 are from Knuth, The Art of Programming, Volume 2
** (Seminumerical Algorithms), Second Edition (1981), Addison-Wesley.
** Table 2, page 660.
*/

#define fs1  3               /* round 1 shift amounts */
#define fs2  7
#define fs3 11
#define fs4 19
#define gs1  3               /* round 2 shift amounts */
#define gs2  5
#define gs3  9
#define gs4 13
#define hs1  3               /* round 3 shift amounts */
#define hs2  9
#define hs3 11
#define hs4 15

/* Compile-time macro declarations for MD4.
** Note: The "rot" operator uses the variable "tmp".
** It assumes tmp is declared as unsigned int, so that the >>
** operator will shift in zeros rather than extending the sign bit.
*/
#define f(X,Y,Z)             ((X&Y) | ((~X)&Z))
#define g(X,Y,Z)             ((X&Y) | (X&Z) | (Y&Z))
#define h(X,Y,Z)             (X^Y^Z)
#define rot(X,S)             (tmp=X,(tmp<<S) | (tmp>>(32-S)))
#define ff(A,B,C,D,i,s)      A = rot((A + f(B,C,D) + X[i]),s)
#define gg(A,B,C,D,i,s)      A = rot((A + g(B,C,D) + X[i] + C2),s)
#define hh(A,B,C,D,i,s)      A = rot((A + h(B,C,D) + X[i] + C3),s)


/* MD4Init(MDp)
** Initialize message digest buffer MDp.
** This is a user-callable routine.
*/
void
MD4Init(MD4_CTX *MDp)
{
  int i;
  MDp->buffer[0] = I0;
  MDp->buffer[1] = I1;
  MDp->buffer[2] = I2;
  MDp->buffer[3] = I3;
  for (i=0;i<8;i++) MDp->count[i] = 0;
  MDp->done = 0;
}


/* MDblock(MDp,X)
** Update message digest buffer MDp->buffer using 16-word data block X.
** Assumes all 16 words of X are full of data.
** Does not update MDp->count.
** This routine is not user-callable.
*/
void
MDblock(MD4_CTX *MDp, unsigned char *Xb)
{
  INT32 tmp, A, B, C, D;
  INT32 X[16];
  int i;

  for (i = 0; i < 16; ++i) {
    X[i] = ((INT32)(Xb[0])) +
	(((INT32)(Xb[1])) << 8) +
	(((INT32)(Xb[2])) << 16) +
	(((INT32)(Xb[3])) << 24);
    Xb += 4;
  }

  A = MDp->buffer[0];
  B = MDp->buffer[1];
  C = MDp->buffer[2];
  D = MDp->buffer[3];
  /* Update the message digest buffer */
  ff(A , B , C , D ,  0 , fs1); /* Round 1 */
  ff(D , A , B , C ,  1 , fs2);
  ff(C , D , A , B ,  2 , fs3);
  ff(B , C , D , A ,  3 , fs4);
  ff(A , B , C , D ,  4 , fs1);
  ff(D , A , B , C ,  5 , fs2);
  ff(C , D , A , B ,  6 , fs3);
  ff(B , C , D , A ,  7 , fs4);
  ff(A , B , C , D ,  8 , fs1);
  ff(D , A , B , C ,  9 , fs2);
  ff(C , D , A , B , 10 , fs3);
  ff(B , C , D , A , 11 , fs4);
  ff(A , B , C , D , 12 , fs1);
  ff(D , A , B , C , 13 , fs2);
  ff(C , D , A , B , 14 , fs3);
  ff(B , C , D , A , 15 , fs4);
  gg(A , B , C , D ,  0 , gs1); /* Round 2 */
  gg(D , A , B , C ,  4 , gs2);
  gg(C , D , A , B ,  8 , gs3);
  gg(B , C , D , A , 12 , gs4);
  gg(A , B , C , D ,  1 , gs1);
  gg(D , A , B , C ,  5 , gs2);
  gg(C , D , A , B ,  9 , gs3);
  gg(B , C , D , A , 13 , gs4);
  gg(A , B , C , D ,  2 , gs1);
  gg(D , A , B , C ,  6 , gs2);
  gg(C , D , A , B , 10 , gs3);
  gg(B , C , D , A , 14 , gs4);
  gg(A , B , C , D ,  3 , gs1);
  gg(D , A , B , C ,  7 , gs2);
  gg(C , D , A , B , 11 , gs3);
  gg(B , C , D , A , 15 , gs4);
  hh(A , B , C , D ,  0 , hs1); /* Round 3 */
  hh(D , A , B , C ,  8 , hs2);
  hh(C , D , A , B ,  4 , hs3);
  hh(B , C , D , A , 12 , hs4);
  hh(A , B , C , D ,  2 , hs1);
  hh(D , A , B , C , 10 , hs2);
  hh(C , D , A , B ,  6 , hs3);
  hh(B , C , D , A , 14 , hs4);
  hh(A , B , C , D ,  1 , hs1);
  hh(D , A , B , C ,  9 , hs2);
  hh(C , D , A , B ,  5 , hs3);
  hh(B , C , D , A , 13 , hs4);
  hh(A , B , C , D ,  3 , hs1);
  hh(D , A , B , C , 11 , hs2);
  hh(C , D , A , B ,  7 , hs3);
  hh(B , C , D , A , 15 , hs4);
  MDp->buffer[0] += A;
  MDp->buffer[1] += B;
  MDp->buffer[2] += C;
  MDp->buffer[3] += D;
}

/* MD4Update(MDp,X,count)
** Input: X -- a pointer to an array of unsigned characters.
**        count -- the number of bits of X to use.
**          (if not a multiple of 8, uses high bits of last byte.)
** Update MDp using the number of bits of X given by count.
** This is the basic input routine for an MD4 user.
** The routine completes the MD computation when count < 512, so
** every MD computation should end with one call to MD4Update with a
** count less than 512.  A call with count 0 will be ignored if the
** MD has already been terminated (done != 0), so an extra call with
** count 0 can be given as a "courtesy close" to force termination
** if desired.
*/
void
MD4Update(MD4_CTX *MDp, unsigned char *X, unsigned int count)
{
  unsigned int i, tmp, bit, byte, mask;
  unsigned char XX[64];
  unsigned char *p;

  /* return with no error if this is a courtesy close with count
  ** zero and MDp->done is true.
  */
  if (count == 0 && MDp->done) return;
  /* check to see if MD is already done and report error */
  if (MDp->done) return;

  /* Add count to MDp->count */
  tmp = count;
  p = MDp->count;
  while (tmp)
  { tmp += *p;
  *p++ = tmp;
  tmp = tmp >> 8;
  }

  /* Process data */
  if (count == 512)
  { /* Full block of data to handle */
    MDblock(MDp,X);
  }
  else if (count > 512) /* Check for count too large */
  {
    return;
  }
  else /* partial block -- must be last block so finish up */
  {
    /* Find out how many bytes and residual bits there are */
    byte = count >> 3;
    bit =  count & 7;
    /* Copy X into XX since we need to modify it */
    for (i=0;i<=byte;i++)   XX[i] = X[i];
    for (i=byte+1;i<64;i++) XX[i] = 0;
    /* Add padding '1' bit and low-order zeros in last byte */
    mask = 1 << (7 - bit);
    XX[byte] = (XX[byte] | mask) & ~( mask - 1);
    /* If room for bit count, finish up with this block */
    if (byte <= 55)
    {
      for (i=0;i<8;i++) XX[56+i] = MDp->count[i];
      MDblock(MDp,XX);
    }
    else /* need to do two blocks to finish up */
    {
      MDblock(MDp,XX);
      for (i=0;i<56;i++) XX[i] = 0;
      for (i=0;i<8;i++)  XX[56+i] = MDp->count[i];
      MDblock(MDp,XX);
    }
    /* Set flag saying we're done with MD computation */
    MDp->done = 1;
  }
}

/*
** Finish up MD4 computation and return message digest.
*/
void
MD4Final(unsigned char *buf, MD4_CTX *MD)
{
  int i, j;
  INT32 w;

  MD4Update(MD, NULL, 0);
  for (i = 0; i < 4; ++i) {
    w = MD->buffer[i];
    for (j = 0; j < 4; ++j) {
      *buf++ = w;
      w >>= 8;
    }
  }
}
