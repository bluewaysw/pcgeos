COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Clavin
MODULE:		Utils
FILE:		utilsC.asm

AUTHOR:		Chung Liu, Nov 23, 1994

ROUTINES:
	Name			Description
	----			-----------
	MAILBOXLOADTRANSPORTDRIVER
	MAILBOXLOADDATADRIVER
	MAILBOXLOADDATADRIVERWITHERROR
	MAILBOXFREEDRIVER
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	11/23/94   	Initial revision


DESCRIPTION:
	C interface
		

	$Id: utilsC.asm,v 1.1 97/04/05 01:19:35 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	SetGeosConvention

C_Mailbox	segment resource

COMMENT @----------------------------------------------------------------------

C FUNCTION:	MailboxLoadTransportDriver

C DECLARATION:	GeodeHandle (MailboxTransport transport, GeodeLoadError *error)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CHL	11/94		Initial version

------------------------------------------------------------------------------@
MAILBOXLOADTRANSPORTDRIVER	proc	far		transport:dword,
							loadErr:fptr
	.enter
	movdw	cxdx, transport
	call	MailboxLoadTransportDriver
	jc	error
	mov	ax, bx			;return GeodeHandle
exit:
	.leave
	ret
error:
	les	bx, loadErr
	mov	es:[bx], ax		;return GeodeLoadError
	clr	ax			;signal error
	jmp	exit
MAILBOXLOADTRANSPORTDRIVER	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	MailboxLoadDataDriver

C DECLARATION:	GeodeHandle (MailboxStorage storage, GeodeLoadError *error)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CHL	11/94		Initial version

------------------------------------------------------------------------------@
MAILBOXLOADDATADRIVER	proc	far		storage:dword,
						loadErr:fptr
	.enter
	movdw	cxdx, storage
	call	MailboxLoadDataDriver
	jc	error
	mov	ax, bx			;return GeodeHandle
exit:
	.leave
	ret
error:
	les	bx, loadErr
	mov	es:[bx], ax		;return GeodeLoadError
	clr	ax			;signal error
	jmp	exit
MAILBOXLOADDATADRIVER	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	MailboxLoadDataDriverWithError

C DECLARATION:	GeodeHandle (MailboxStorage storage, GeodeLoadError *error)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CHL	11/94		Initial version

------------------------------------------------------------------------------@
MAILBOXLOADDATADRIVERWITHERROR	proc	far	storage:dword,
						loadErr:fptr
	.enter
	movdw	cxdx, storage
	call	MailboxLoadDataDriverWithError
	jc	error
	mov	ax, bx			;return GeodeHandle
exit:
	.leave
	ret
error:
	les	bx, loadErr
	mov	es:[bx], ax		;return GeodeLoadError
	clr	ax			;signal error
	jmp	exit
MAILBOXLOADDATADRIVERWITHERROR	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	MailboxFreeDriver

C DECLARATION:	void (GeodeHandle driverHandle)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CHL	11/94		Initial version

------------------------------------------------------------------------------@
MAILBOXFREEDRIVER	proc	far	driverHandle:hptr
	.enter
	mov	bx, driverHandle
	call	MailboxFreeDriver
	.leave
	ret
MAILBOXFREEDRIVER	endp

C_Mailbox	ends
	
	SetDefaultConvention
