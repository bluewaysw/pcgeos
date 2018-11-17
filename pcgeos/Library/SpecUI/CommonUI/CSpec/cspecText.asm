COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/CSpec
FILE:		cspecText.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	OLBuildText		Convert a text display to the OL equivalent

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/89		Initial version

DESCRIPTION:

	$Id: cspecText.asm,v 1.1 97/04/07 10:50:42 newdeal Exp $

------------------------------------------------------------------------------@


Build segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLBuildText

DESCRIPTION:	Return the specific UI class for a GenTextDisplay

CALLED BY:	GLOBAL

PASS:
	*ds:si - instance data
	ax - MSG_META_RESOLVE_VARIANT_SUPERCLASS
	cx, dx, bp - ?

RETURN:
	cx:dx - class (cx = 0 for no conversion)

DESTROYED:
	ax, bx, si, di, bp, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version

------------------------------------------------------------------------------@

OLBuildText	proc	far

	; Always convert to OLTextClass

	mov	dx, offset OLTextClass
	mov	cx, segment OLTextClass
	ret

OLBuildText	endp

Build ends
