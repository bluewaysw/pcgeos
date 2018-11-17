/***********************************************************************
 *
 *	Copyright (c) GlobalPC 1998.  All rights reserved.
 *	GLOBALPC CONFIDENTIAL
 *
 * PROJECT:	  Mail
 * MODULE:	  MailPOP3
 * FILE:	  buffer.h
 *
 * AUTHOR:  	  : Nov 25, 1998
 *
 * REVISION HISTORY:
 *	Name	        Date		Description
 *	----	        ----		-----------
 *	porteous	11/25/98   	Initial version
 *
 * DESCRIPTION:
 *
 *	
 *
 * 	$Id$
 *
 ***********************************************************************/
#ifndef _BUFFER_H_
#define _BUFFER_H_

/* The transfer size of is smaller than the BUFFER BLOCK size to 
 * allow for the possibility of pushing data back into the buffer.
 */
#define BUFFER_BLOCK_SIZE     8192
#define BUFFER_TRANSFER_SIZE  7168


typedef struct {
    Socket    BB_socket;
    MemHandle BB_blockHandle;
    byte     *BB_data;
    int       BB_startIndex;
    int       BB_endIndex;
} BufferBlock;

extern MailError _pascal 
BufferInit(BufferBlock *block, Socket sock);

extern MailError _pascal 
BufferClose(BufferBlock *block);

extern MailError _pascal
BufferLockBlock (BufferBlock *block);

extern void _pascal
BufferUnlockBlock (BufferBlock *block);

extern MailError _pascal 
BufferGetNextByte(BufferBlock *block, char *c);

MailError _pascal
BufferUndoLastByte (BufferBlock *block);

#endif /* _BUFFER_H_ */
