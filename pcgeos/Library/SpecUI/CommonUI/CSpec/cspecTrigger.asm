COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/CSpec (common code for several specific ui's)
FILE:		cspecTrigger.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	OLBuildTrigger		Convert a generic trigger to the OL equivalent
   GLB	OLBuildDataTrigger	Convert a generic data trigger to OL equivalent

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version
	Eric	7/89		Motif extensions, more documentation

DESCRIPTION:
	This file contains routines to handle the Open Look implementation
of a generic trigger.

	$Id: cspecTrigger.asm,v 1.1 97/04/07 10:51:15 newdeal Exp $

------------------------------------------------------------------------------@


Build segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLBuildTrigger

DESCRIPTION:	Return the specific UI class for a GenTrigger

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
	A GenTrigger always starts life as an OLButtonClass, but in Motif,
	OLButtonInitialize will check if the button is inside a menu,
	and will set the specific state bits accordingly, so the button
	will be drawn correctly.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version

------------------------------------------------------------------------------@


OLBuildTrigger	proc	far


	;Always convert to OLButtonClass

	mov	dx, offset OLButtonClass
	mov	cx, segment OLButtonClass
	ret

OLBuildTrigger	endp

Build ends
