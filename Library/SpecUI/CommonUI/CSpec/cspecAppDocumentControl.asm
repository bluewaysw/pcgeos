COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/CSpec
FILE:		cspecAppDocumentControl.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	OLBuildAppDocumentControl Convert a generic document control to the OL
				equivalent

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

DESCRIPTION:
	This file contains routines to handle the Open Look implementation
of a generic document control.

	$Id: cspecAppDocumentControl.asm,v 1.1 97/04/07 10:50:58 newdeal Exp $

------------------------------------------------------------------------------@

DocInit segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLBuildAppDocumentControl

DESCRIPTION:	Return the specific UI class for a GenDocumentGroup

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

OLBuildAppDocumentControl	proc	far

	; Always convert to OLDocumentGroupClass

	mov	dx, offset OLDocumentGroupClass
	mov	cx, segment OLDocumentGroupClass
	ret

OLBuildAppDocumentControl	endp


DocInit ends
