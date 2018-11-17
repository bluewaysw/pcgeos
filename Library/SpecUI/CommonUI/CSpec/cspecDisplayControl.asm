COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/Spec
FILE:		specDisplayControl.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	OLBuildDisplayControl	Convert a generic display control to the OL
				equivalent

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/89		Initial version

DESCRIPTION:
	This file contains routines to handle the Open Look implementation
of a generic display control.

	$Id: cspecDisplayControl.asm,v 1.1 97/04/07 10:48:42 newdeal Exp $

------------------------------------------------------------------------------@

Build segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLBuildDisplayControl

DESCRIPTION:	Return the specific UI class for a GenDisplayGroup

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

OLBuildDisplayControl	proc	far

	; Always convert to OLDisplayGroupClass

	mov	dx, offset OLDisplayGroupClass
	mov	cx, segment OLDisplayGroupClass
	ret

OLBuildDisplayControl	endp


Build ends
