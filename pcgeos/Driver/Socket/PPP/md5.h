/***********************************************************************
 *
 *	Copyright (c) Geoworks 1995 -- All Rights Reserved
 *
 *			GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  Socket
 * MODULE:	  PPP Driver
 * FILE:	  md5.h
 *
 * AUTHOR:  	  Jennifer Wu: May 12, 1995
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	5/12/95	  jwu	    Initial version
 *
 * DESCRIPTION:
 *	Header file for MD5 Encryption.
 *
 *
 * 	$Id: md5.h,v 1.1 95/07/11 15:32:40 jwu Exp $
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

#ifndef _MD5_H_
#define _MD5_H_

/* 
 *	    MD5 context. 
 */
typedef struct {
  unsigned long state[4];                           /* state (ABCD) */
  unsigned long count[2];        /* number of bits, modulo 2^64 (lsb first) */
  unsigned char buffer[64];                         /* input buffer */
} MD5_CTX;

extern void MD5Init ();
extern void MD5Update ();
extern void MD5Final ();

#endif /* _MD5_H_ */
