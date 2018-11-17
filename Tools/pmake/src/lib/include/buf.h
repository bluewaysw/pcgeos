/*-
 * buf.h --
 *	Header for users of the buf library.
 *
 * Copyright (c) 1987 by the Regents of the University of California
 *
 * Permission to use, copy, modify, and distribute this
 * software and its documentation for any purpose and without
 * fee is hereby granted, provided that the above copyright
 * notice appear in all copies.  The University of California
 * makes no representations about the suitability of this
 * software for any purpose.  It is provided "as is" without
 * express or implied warranty.
 *
 *	"$Id: buf.h,v 1.1 92/07/27 12:23:40 jimmy Exp $ SPRITE (Berkeley)"
 */

#ifndef _BUF_H
#define _BUF_H

#include    "sprite.h"

typedef void	 *Buffer;
typedef unsigned char Byte;

   /* Initialize a buffer */
Buffer Buf_Init(int size);

  /* Destroy a buffer */   
void  Buf_Destroy(Buffer buf, Boolean freeData);

   /* Add a single byte to a buffer */
void Buf_AddByte(Buffer buf, Byte byte);

  /* Add a range of bytes to a buffer */
void Buf_AddBytes(Buffer buf, int numBytes, Byte *bytesPtr);

    /* Get a byte from a buffer */
int  Buf_GetByte(Buffer buf);

   /* Get multiple bytes */
int  Buf_GetBytes(Buffer buf, int numBytes, Byte *bytesPtr);

  /* Push a byte back into the buffer */
void  Buf_UngetByte(Buffer buf, Byte byte);
  
/* Push many bytes back into the buf */
void  Buf_UngetBytes(Buffer buf, int numBytes, Byte *bytesPtr); 

    /* Get them all */
Byte  *Buf_GetAll(Buffer buf, int *numBytesPtr);

     /* Throw away some of the bytes */
void  Buf_Discard(Buffer buf, int numBytes);

    /* See how many are there */
int   Buf_Size(Buffer buf);	

#define BUF_ERROR 256

#endif _BUF_H
