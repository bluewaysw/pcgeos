/***********************************************************************
 *
 *	Copyright (c) Global PC 1998 -- All Rights Reserved
 *
 *			GLOBAL PC CONFIDENTIAL
 *
 * PROJECT:	  Socket
 * MODULE:	  PPP Driver
 * FILE:	  md4.h
 *
 * AUTHOR:  	  Brian Chin: October 6, 1998
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	10/6/98	  brianc    Initial version
 *
 * DESCRIPTION:
 *	Header file for MD4 Encryption.
 *
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

#ifndef _MD4_H_
#define _MD4_H_

/*
 * need 32 bit values
 */
typedef unsigned long INT32;

/*
 * MDstruct is the data structure for a message digest computation.
 */
typedef struct {
	INT32 buffer[4]; /* Holds 4-word result of MD computation */
	unsigned char count[8]; /* Number of bits processed so far */
	unsigned int done;      /* Nonzero means MD computation finished */
} MD4_CTX;

/* MD4Init(MD4_CTX *)
** Initialize the MD4_CTX prepatory to doing a message digest
** computation.
*/
extern void MD4Init(MD4_CTX *MD);

/* MD4Update(MD,X,count)
** Input: X -- a pointer to an array of unsigned characters.
**        count -- the number of bits of X to use (an unsigned int).
** Updates MD using the first "count" bits of X.
** The array pointed to by X is not modified.
** If count is not a multiple of 8, MD4Update uses high bits of
** last byte.
** This is the basic input routine for a user.
** The routine terminates the MD computation when count < 512, so
** every MD computation should end with one call to MD4Update with a
** count less than 512.  Zero is OK for a count.
*/
extern void MD4Update(MD4_CTX *MD, unsigned char *X, unsigned int count);

/* MD4Final(buf, MD)
** Returns message digest from MD and terminates the message
** digest computation.
*/
extern void MD4Final(unsigned char *, MD4_CTX *);

#endif /* _MD4_H_ */
