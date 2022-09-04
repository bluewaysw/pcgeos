COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/CSpec
FILE:		cspecApplication.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	OLBuildApplication	Convert a generic application into the OL
				equivalent

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version

DESCRIPTION:
	This file contains routines to handle the Open Look implementation
of a generic application.

	$Id: cspecApplication.asm,v 2.4 94/06/08 20:32:51 clee Exp $

------------------------------------------------------------------------------@

Build segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLBuildApplication

DESCRIPTION:	Return the specific UI class for a GenApplication

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

OLBuildApplication	proc	far

	; Always convert to OLApplicationClass

	mov	dx, offset OLApplicationClass
	mov	cx, segment OLApplicationClass
	ret

OLBuildApplication	endp

Build ends
