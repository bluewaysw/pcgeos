/**********************************************************************
 *
 *	Copyright (c) Designs in Light 2002 -- All Rights Reserved
 *
 * PROJECT:        Mail	
 * MODULE:	   BBXMail
 * FILE:	   buffer.h
 * 
 * DESCRIPTION:
 * 
 * Create a buffer between the code that needs to parse the message and 
 * the socket in order to improve performance.
 * 	
 ****************************************************************************/

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
