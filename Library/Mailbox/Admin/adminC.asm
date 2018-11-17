COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	Clavin
MODULE:		Administartive File Management
FILE:		adminC.asm

AUTHOR:		Skarpi Hedinsson, Mar  8, 1995

ROUTINES:
	Name			Description
	----			-----------
	MAILBOXGETADMINFILE
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	3/ 8/95   	Initial revision


DESCRIPTION:
	C interface routines for admin module.
		

	$Id: adminC.asm,v 1.1 97/04/05 01:20:47 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	SetGeosConvention

C_Mailbox	segment resource

COMMENT @----------------------------------------------------------------------

C FUNCTION:	MailboxGetAdminFile

C DECLARATION:	hptr (void)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	3/95		Initial version

------------------------------------------------------------------------------@
MAILBOXGETADMINFILE	proc	far
		.enter
		call	MailboxGetAdminFile
		mov	ax, bx			;return VMFileHandle
		.leave
		ret
MAILBOXGETADMINFILE	endp

C_Mailbox	ends

	SetDefaultConvention
