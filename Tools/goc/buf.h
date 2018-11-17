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
* 	$Id: buf.h,v 4.1 92/04/13 00:16:25 adam Exp $
 *
 ***********************************************************************/
#ifndef _BUF_H
#define _BUF_H

#include    "sprite.h"

typedef struct Buffer *Buffer;
typedef unsigned char B;

Buffer	    	Buf_Init(int initSize);
void	    	Buf_Destroy(Buffer buf, Boolean doFree);
void	    	Buf_AddB(Buffer buf, B b);
void	    	Buf_AddBs(Buffer buf, int numBs, B *bytesPtr);
int	    	Buf_GetB(Buffer buf);
int	    	Buf_GetBs(Buffer buf, int numBs, B *bytesPtr);
void		Buf_UngetB(Buffer buf, B b);
void		Buf_UngetBs(Buffer buf, int numBs, B *bytesPtr);
B	    	*Buf_GetAll(Buffer buf, int *numBsPtr);
void	    	Buf_Discard(Buffer buf, int numBs);
int	    	Buf_Size(Buffer buf);
void	    	Buf_DelBs(Buffer buf, int numBs);

#define BUF_ERROR 256

#endif _BUF_H
