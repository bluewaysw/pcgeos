COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Document
FILE:		documentErrorCheck.asm

AUTHOR:		Steve Scholl

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	Steve Scholl    2/8/92        Initial revision.

DESCRIPTION:

	$Id: documentErrorCheck.asm,v 1.1 97/04/04 15:51:55 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;	THIS FILE SHOULD ONLY BE INCLUDED WHEN MAKING THE ERROR CHECKING VERSION

DocumentCode	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	ECCheckDocument

DESCRIPTION:	Check a DrawDocument object for validity

CALLED BY:	INTERNAL

PASS:
	*ds:si - DrawDocument

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	12/90		Initial version

------------------------------------------------------------------------------@


ECCheckDocument	proc	far	uses ax,bx, di, es
	class	DrawDocumentClass
	.enter
	pushf
	call	ECCheckLMemObject
	GetResourceHandleNS DrawDocumentClass, bx
	call	MemDerefES
	mov	di, offset DrawDocumentClass
	call	ObjIsObjectInClass
	ERROR_NC DRAW_NOT_A_DRAW_DOCUMENT
	popf
	.leave
	ret

ECCheckDocument	endp

DocumentCode ends
