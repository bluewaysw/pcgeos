COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/CSpec
FILE:		specScreen.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	OLBuildScreen		Convert a generic screen to the OL
				equivalent

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version

DESCRIPTION:
	This file contains routines to handle the Open Look implementation
of a screen.

	$Id: cspecScreen.asm,v 2.4 94/06/08 20:56:35 clee Exp $

------------------------------------------------------------------------------@

Build segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLBuildScreen

DESCRIPTION:	Return the specific UI class for a GenScreen

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

OLBuildScreen	proc	far

	; Always convert to OLScreenClass

	mov	dx, offset OLScreenClass
	mov	cx, segment OLScreenClass
	ret

OLBuildScreen	endp

Build ends
