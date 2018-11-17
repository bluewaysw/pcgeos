COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/Spec
FILE:		cspecContent.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	OLBuildContent		Convert a generic trigger to the OL equivalent

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	9/89		Initial version

DESCRIPTION:
	This file contains routines to handle the Open Look implementation
of a content object.

	$Id: cspecContent.asm,v 1.1 97/04/07 10:50:51 newdeal Exp $

------------------------------------------------------------------------------@


Build segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLBuildContent

DESCRIPTION:	Return the specific UI class for a GenContent

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
	Chris	9/89		Initial version

------------------------------------------------------------------------------@

OLBuildContent	proc	far
	class	GenContentClass

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset

				; Segment of our classes
	mov	cx, segment OLContentClass
	mov	dx, offset OLContentClass
	ret

OLBuildContent	endp

Build ends
