COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Clavin
MODULE:		Outbox
FILE:		outboxC.asm

AUTHOR:		Chung Liu, Nov 22, 1994

ROUTINES:
	Name			Description
	----			-----------
	MAILBOXSETCANCELACTION
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	11/22/94   	Initial revision


DESCRIPTION:
	C Interface
		

	$Id: outboxC.asm,v 1.1 97/04/05 01:21:22 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	SetGeosConvention

C_Mailbox	segment resource

COMMENT @----------------------------------------------------------------------

C FUNCTION:	MailboxSetCancelAction

C DECLARATION:	void (optr destination, Message messageToSend)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CHL	11/94		Initial version

------------------------------------------------------------------------------@
MAILBOXSETCANCELACTION		proc	far		destination:optr,
							messageToSend:word
	uses	si
	.enter
	movdw	bxsi, destination
	mov	ax, messageToSend
	call	MailboxSetCancelAction
	.leave
	ret
MAILBOXSETCANCELACTION		endp

C_Mailbox	ends

	SetDefaultConvention
