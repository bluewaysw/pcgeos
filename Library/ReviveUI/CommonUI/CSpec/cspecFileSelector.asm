COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/CSpec
FILE:		cspecFileSelector.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	OLBuildFileSelector	Convert a generic document control to the OL
				equivalent

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

DESCRIPTION:
	This file contains routines to handle the Open Look implementation
of a generic document control.

	$Id: cspecFileSelector.asm,v 1.6 92/07/29 22:23:50 joon Exp $

------------------------------------------------------------------------------@

Build segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLBuildFileSelector

DESCRIPTION:	Return the specific UI class for a GenFileSelector

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

OLBuildFileSelector	proc	far

	; Always convert to OLFileSelectorClass

	mov	dx, offset OLFileSelectorClass
	mov	cx, segment OLFileSelectorClass
	ret

OLBuildFileSelector	endp


Build ends
