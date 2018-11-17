COMMENT @---------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All rights reserved

PROJECT:	
MODULE:	
FILE:		amateurProcess.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------

DESCRIPTION:
		Routines for the AmateurProcess class

	$Id: amateurProcess.asm,v 1.1 97/04/04 15:11:58 newdeal Exp $
-----------------------------------------------------------------------------@
AmateurCode	segment resource

COMMENT @---------------------------------------------------------------------
		AmateurOpenApplication
------------------------------------------------------------------------------

SYNOPSIS:	initialize content data when attached

CALLED BY:	
PASS:		
RETURN:		
-----------------------------------------------------------------------------@
AmateurOpenApplication	method	AmateurProcessClass,
				MSG_GEN_PROCESS_OPEN_APPLICATION

	.enter
	mov	di, offset AmateurProcessClass
	call	ObjCallSuperNoLock

		
	mov	ax, MSG_CONTENT_INITIALIZE
	mov	bx, handle GameObjects
	mov	di, mask MF_CALL
	mov	si, offset ContentObject
	call	ObjMessage

	call	AmateurInitSound
		
	.leave
	ret
AmateurOpenApplication	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AmateurCloseApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= AmateurProcessClass object
		ds:di	= AmateurProcessClass instance data
		es	= Segment of AmateurProcessClass.

RETURN:		cx - clear (no state saving)

DESTROYED:	ax,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/10/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AmateurCloseApplication	method	dynamic	AmateurProcessClass, 
					MSG_GEN_PROCESS_CLOSE_APPLICATION

	mov	di, offset AmateurProcessClass
	call	ObjCallSuperNoLock

	call	AmateurExitSound		

	clr	cx
	ret
AmateurCloseApplication	endm


AmateurCode	ends
