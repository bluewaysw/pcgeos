COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Clavin
MODULE:		VMStore
FILE:		vmstoreC.asm

AUTHOR:		Chung Liu, Nov 21, 1994

ROUTINES:
	Name			Description
	----			-----------
	MAILBOXGETVMFILE
	MAILBOXOPENVMFILE
	MAILBOXGETVMFILENAME
	MAILBOXDONEWITHVMFILE
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	11/21/94   	Initial revision


DESCRIPTION:
	C interface routines for the VMStore module.
		

	$Id: vmstoreC.asm,v 1.1 97/04/05 01:20:39 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	SetGeosConvention

C_Mailbox	segment resource

COMMENT @----------------------------------------------------------------------

C FUNCTION:	MailboxGetVMFile

C DECLARATION:	VMFileHandle (word expectedNumBlocks, VMStatus *vmStatusp)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CHL	11/94		Initial version

------------------------------------------------------------------------------@
MAILBOXGETVMFILE	proc	far		numBlocks:word,
						vmStatus:fptr
	.enter
	mov	bx, numBlocks
	call	MailboxGetVMFile
	jc	error
	mov	ax, bx			;return VMFileHandle
exit:
	.leave
	ret
error:
	les	bx, vmStatus
	mov	es:[bx], ax		;set VMStatus
	clr	ax			;return 0
	jmp	exit

MAILBOXGETVMFILE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	MailboxOpenVMFile

C DECLARATION:	VMFileHandle (FileLongName name, VMStatus *vmStatusp)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CHL	11/94		Initial version

------------------------------------------------------------------------------@
MAILBOXOPENVMFILE	proc	far		filename:fptr,
						vmStatus:fptr
	.enter
	movdw	cxdx, filename
	call	MailboxOpenVMFile
	mov_tr	cx, ax				; cx <- VMStatus
	mov_tr	ax, bx				; ax <- presumed VMFileHandle
	les	bx, vmStatus
	mov	es:[bx], cx
	jnc	exit
	clr	ax				;return 0 when error
exit:
	.leave
	ret
MAILBOXOPENVMFILE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	MailboxGetVMFileName

C DECLARATION:	void (VMFileHandle file, FileLongName name)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CHL	11/94		Initial version

------------------------------------------------------------------------------@
MAILBOXGETVMFILENAME	proc	far		file:hptr,
						filename:fptr
	.enter
	mov	bx, file
	movdw	cxdx, filename
	call	MailboxGetVMFileName
	.leave
	ret
MAILBOXGETVMFILENAME	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	MailboxDoneWithVMFile

C DECLARATION:	void (VMFileHandle file)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CHL	11/94		Initial version

------------------------------------------------------------------------------@
MAILBOXDONEWITHVMFILE	proc	far		file:hptr
	.enter
	mov	bx, file
	call	MailboxDoneWithVMFile
	.leave
	ret
MAILBOXDONEWITHVMFILE	endp

C_Mailbox	ends

	SetDefaultConvention



















