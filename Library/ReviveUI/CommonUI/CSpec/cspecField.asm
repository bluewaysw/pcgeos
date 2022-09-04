COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/CSpec
FILE:		cspecField.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	OLBuildField		Convert a generic field group to the OL
				equivalent

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version

DESCRIPTION:
	This file contains routines to handle the Open Look implementation
of a field window

	$Id: cspecField.asm,v 2.4 94/06/08 20:41:45 clee Exp $

------------------------------------------------------------------------------@

Build segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLBuildField

DESCRIPTION:	Return the specific UI class for a GenField

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

OLBuildField	proc	far

	; Always convert to OLFieldClass

	mov	dx, offset OLFieldClass
	mov	cx, segment OLFieldClass
	ret

OLBuildField	endp

Build ends
