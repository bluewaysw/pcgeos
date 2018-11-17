COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	Text
MODULE:		UI
FILE:		uiC.asm

AUTHOR:		Andrew Wilson, May 11, 1992

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/11/92		Initial revision

DESCRIPTION:
	Contains C stubs for UI module.	

	$Id: uiC.asm,v 1.1 97/04/07 11:17:14 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 0
	SetGeosConvention
TextC	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TEXTSENDSEARCHNOTIFICATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A CStub for TextSendSearchNotification

CALLED BY:	GLOBAL
C DECLARATION:	extern void _far _pascal
		TextSendSearchNotification (SearchSpellEnableFlags flags);
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	TEXTSENDSEARCHNOTIFICATION:far
TEXTSENDSEARCHNOTIFICATION	proc	far	;flags:byte
	.enter
	C_GetOneWordArg cx,	ax, bx		;CL <- flags
	call	TextSendSearchNotification
	.leave
	ret
TEXTSENDSEARCHNOTIFICATION	endp

TextC	ends
	SetDefaultConvention
endif
