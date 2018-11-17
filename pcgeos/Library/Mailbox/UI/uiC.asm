COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Clavin
MODULE:		UI
FILE:		uiC.asm

AUTHOR:		Chung Liu, Nov 23, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	11/23/94   	Initial revision


DESCRIPTION:
	C Interface
		

	$Id: uiC.asm,v 1.1 97/04/05 01:19:04 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	SetGeosConvention

C_Mailbox	segment resource

COMMENT @----------------------------------------------------------------------

C FUNCTION:	MailboxConvertToMailboxTransferItem

C DECLARATION:	void (VMFileHandle clipboardFile, VMBlockHandle clipboardBlock,
			VMFileHandle vmFile, word userID, 
			MemHandle nameLMemBlock, ChunkHandle nameChunk,
			VMBlockHandle *transferItemBlock);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CHL	11/94		Initial version

------------------------------------------------------------------------------@
MAILBOXCONVERTTOMAILBOXTRANSFERITEM	proc	far	clipbrdFile:hptr,
							clipbrdBlk:word,
							vmFile:hptr,
							userID:word,
							nameBlk:hptr,
							nameChunk:lptr,
							transferBlock:fptr
	uses	ds, si
	.enter
	mov	si, nameChunk
	tst	si
	jz 	dontSetDS
	mov	bx, nameBlk
	call	MemLock
	mov	ds, ax

dontSetDS:
	mov	bx, clipbrdFile
	mov	cx, clipbrdBlk
	mov	dx, vmFile
	mov	ax, userID
	call	MailboxConvertToMailboxTransferItem

	lds	si, transferBlock
	mov	ds:[si], ax

	tst	nameChunk
	jz	exit
	mov	bx, nameBlk
	call	MemUnlock
exit:
	.leave
	ret
MAILBOXCONVERTTOMAILBOXTRANSFERITEM	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	MailboxConvertToClipboardTransferItem

C DECLARATION:	void (VMFileHandle mailboxFile, VMBlockHandle mailboxBlock,
			VMFileHandle vmFile, word userID, 
			transferBlock *VMBlockHandle)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CHL	11/94		Initial version

------------------------------------------------------------------------------@
MAILBOXCONVERTTOCLIPBOARDTRANSFERITEM	proc	far	mboxFile:hptr,
							mboxBlk:word,
							vmFile:hptr,
							userID:word,
							transferBlock:fptr
	uses	ds, si
	.enter
	mov	bx, mboxFile
	mov	cx, mboxBlk
	mov	dx, vmFile
	mov	ax, userID
	call	MailboxConvertToClipboardTransferItem
	lds	si, transferBlock
	mov	ds:[si], ax
	.leave
	ret
MAILBOXCONVERTTOCLIPBOARDTRANSFERITEM	endp

C_Mailbox	ends

	SetDefaultConvention


