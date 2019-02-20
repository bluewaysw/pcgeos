/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Swat -- Buf-module definitions
 * FILE:	  buf.h
 *
 * AUTHOR:  	  Adam de Boor: Mar 23, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	3/23/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Declarations for expandable buffers.
 *
 *
* 	$Id: buf.h,v 4.4 97/04/18 14:50:05 dbaumann Exp $
 *
 ***********************************************************************/
#ifndef _BUF_H
#define _BUF_H

#include "sprite.h"

/* XXXdan-q should I leave 
 * typedef struct Buffer *Buffer; 
 * for the _unix case 
 */
typedef void *Buffer;
typedef unsigned char Byte;

Buffer	    	Buf_Init(int initSize);
void	    	Buf_Destroy(Buffer buf, Boolean doFree);
void	    	Buf_AddByte(Buffer buf, Byte b);
void	    	Buf_AddByteMiddle(Buffer buf, Byte b, int start);
void	    	Buf_AddBytes(Buffer buf, int numBytes, Byte *bytesPtr);
void            Buf_AddBytesMiddle (Buffer buf, int numBytes,
				    Byte *bytesPtr, int start);
int	    	Buf_GetByte(Buffer buf);
int	    	Buf_GetBytes(Buffer buf, int numBytes, Byte *bytesPtr);
void		Buf_UngetByte(Buffer buf, Byte b);
void		Buf_UngetBytes(Buffer buf, int numBytes, Byte *bytesPtr);
Byte	    	*Buf_GetAll(Buffer buf, int *numBytesPtr);
void	    	Buf_Discard(Buffer buf, int numBytes);
int	    	Buf_Size(Buffer buf);
void	    	Buf_DelBytes(Buffer buf, int numBytes);
void	    	Buf_DelBytesMiddle(Buffer buf, int numBytes, int start);

#define BUF_ERROR 256

#endif _BUF_H
