COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		helpC.asm

AUTHOR:		Gene Anderson, Mar  2, 1993

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	3/ 2/93		Initial revision


DESCRIPTION:
	C routines for help

	$Id: helpC.asm,v 1.1 97/04/07 11:47:25 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HelpControlCode	segment	resource

if FULL_EXECUTE_IN_PLACE
HelpControlCode  ends
UserCStubXIP    segment resource
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HELPSENDHELPNOTIFICATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate a help notification

C FUNCTION:	HelpSendHelpNotification()
C DECLARATION	extern void
			_far _pascal HelpSendHelpNotification(word HelpType,
					const char *contextname,
					const char *filename);
		Note:The fptrs *can* be pointing to the movable XIP 
			code resource.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/ 2/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HELPSENDHELPNOTIFICATION proc far helpType:HelpType,
				contextname:fptr.char,
				filename:fptr.char
	uses	ds, si, es, di
	.enter

	mov	al, {byte}ss:helpType
	lds	si, ss:contextname
	les	di, ss:filename
NOFXIP<	call	HelpSendHelpNotification				>
FXIP<	call	HelpSendHelpNotificationXIP				>

	.leave
	ret
HELPSENDHELPNOTIFICATION endp

if FULL_EXECUTE_IN_PLACE
UserCStubXIP    ends
HelpControlCode  segment resource
endif

HelpControlCode	ends
