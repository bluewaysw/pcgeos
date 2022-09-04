COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/CSpec
FILE:		cspecUIDocumentControl.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	OLBuildUIDocumentControl Convert a generic document control to the OL
				equivalent

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

DESCRIPTION:
	This file contains routines to handle the Open Look implementation
of a generic document control.

	$Id: cspecUIDocumentControl.asm,v 1.6 93/01/25 22:25:49 tony Exp $

------------------------------------------------------------------------------@

DocInit segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLBuildUIDocumentControl

DESCRIPTION:	Return the specific UI class for a GenDocumentControl

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

OLBuildUIDocumentControl	proc	far

	; Always convert to OLDocumentControlClass

	mov	dx, offset OLDocumentControlClass
	mov	cx, segment OLDocumentControlClass
	ret

OLBuildUIDocumentControl	endp


DocInit ends
