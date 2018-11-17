COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/CSpec
FILE:		cspecDisplay.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	OLBuildDisplay	Convert a generic base group to the OL
				equivalent

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version

DESCRIPTION:
	This file contains routines to handle the Open Look implementation
of a generic base group.

	$Id: cspecDisplay.asm,v 1.1 97/04/07 10:50:36 newdeal Exp $

------------------------------------------------------------------------------@

Build segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLBuildDisplay

DESCRIPTION:	Return the specific UI class for a GenDisplay

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

OLBuildDisplay	proc	far

	; Use the common DoSimpleWinBuild routine that will set up the
	; temporary data chunk that is expected by SPEC_BUILD

	; Pass the query type to send with a GUP_QUERY to find the visual
	; parent for the object

	mov	cx, SQT_VIS_PARENT_FOR_DISPLAY

	; Pass the offset of the class (assumed to be in idata)

	mov	dx, offset OLDisplayWinClass
	GOTO	DoSimpleWinBuild

OLBuildDisplay	endp

Build ends
