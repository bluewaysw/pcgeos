COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/CSpec
FILE:		cspecPane.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	OLBuildPane		Convert a generic pane to the OL equivalent

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version

DESCRIPTION:
	This file contains routines to handle the Open Look implementation
of a generic pane and simple pane.

	$Id: cspecPane.asm,v 1.1 97/04/07 10:50:40 newdeal Exp $

------------------------------------------------------------------------------@


Build segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLBuildPane

DESCRIPTION:	Return for class for the Open Look equivalent of this class.
		If the view object is scrollable, we will convert it into a
		pane; if it isn't, we'll convert it into a simple pane.

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
	Chris	8/89		Created a separate simple pane object.

------------------------------------------------------------------------------@

OLBuildPane	proc	far
	class	GenViewClass

	; Convert views to OLPaneClass
	;
	mov	dx, offset OLPaneClass
	mov	cx, segment OLPaneClass
	ret

OLBuildPane	endp

Build ends
