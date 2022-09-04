COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/CSpec
FILE:		cspecGlyphDisplay.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	OLBuildGlyphDisplay	Convert a generic Glyph to the OL equivalent

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/89		Initial version

DESCRIPTION:
	This file contains routines to handle the Open Look implementation
of a generic glyph display

	$Id: cspecGlyphDisplay.asm,v 2.4 92/07/29 22:21:11 joon Exp $

------------------------------------------------------------------------------@


Build	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLBuildGlyphDisplay

DESCRIPTION:	Return the specific UI class for a GenGlyph

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
	Doug	5/89		Initial version

------------------------------------------------------------------------------@

OLBuildGlyphDisplay	proc	far

	; Always convert to OLGlyphDisplayClass

	mov	dx, offset OLGlyphDisplayClass
	mov	cx, segment OLGlyphDisplayClass
	ret

OLBuildGlyphDisplay	endp

Build	ends


