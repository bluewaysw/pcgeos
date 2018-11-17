COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Clavin
MODULE:		Media
FILE:		mediaC.asm

AUTHOR:		Chung Liu, Nov 22, 1994

ROUTINES:
	Name			Description
	----			-----------
	MAILBOXCHECKMEDIUMAVAILABLE
	MAILBOXCHECKMEDIUMCONNECTED
	MAILBOXGETFIRSTMEDIUMUNIT

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	11/22/94   	Initial revision


DESCRIPTION:
	C Interface
		

	$Id: mediaC.asm,v 1.1 97/04/05 01:20:33 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	SetGeosConvention

C_Mailbox	segment resource

COMMENT @----------------------------------------------------------------------

C FUNCTION:	MailboxCheckMediumAvailable

C DECLARATION:	Boolean (MediumType mediumType, word unitNum, 
  				MediumUnitType unitType)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CHL	11/94		Initial version

------------------------------------------------------------------------------@
MAILBOXCHECKMEDIUMAVAILABLE	proc	far		mediumType:dword,
							unitNum:word,
							unitType:word
	.enter
	movdw	cxdx, mediumType
	mov	bx, unitNum
	mov	ax, unitType
	call	MailboxCheckMediumAvailable
	mov	ax, 0
	jnc	exit				;carry clear if medium absent
	dec	ax
exit:
	.leave
	ret
MAILBOXCHECKMEDIUMAVAILABLE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	MailboxCheckMediumConnected

C DECLARATION:	Boolean (MediumType mediumType, word unitNum, 
  				MediumUnitType unitType)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CHL	11/94		Initial version

------------------------------------------------------------------------------@
MAILBOXCHECKMEDIUMCONNECTED	proc	far		mediumType:dword,
							unitNum:word,
							unitType:word
	.enter
	movdw	cxdx, mediumType
	mov	bx, unitNum
	mov	ax, unitType
	call	MailboxCheckMediumConnected
	mov	ax, 0
	jnc	exit
	dec	ax
exit:
	.leave
	ret
MAILBOXCHECKMEDIUMCONNECTED	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	MailboxGetFirstMediumUnit

C DECLARATION:	word (MediumType mediumType, MediumUnitType *unitType)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CHL	11/94		Initial version

------------------------------------------------------------------------------@
MAILBOXGETFIRSTMEDIUMUNIT	proc	far		mediumType:dword,
							unitType:fptr
	.enter
	movdw	cxdx, mediumType
	call	MailboxGetFirstMediumUnit
	les	bp, unitType		; (can destroy bp b/c no local vars)
	mov	es:[bp], ax
	mov_tr	ax, bx
	.leave
	ret
MAILBOXGETFIRSTMEDIUMUNIT	endp

C_Mailbox	ends

	SetDefaultConvention
