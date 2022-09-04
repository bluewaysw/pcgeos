COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/CSpec
FILE:		cspecDocument.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	OLBuildDocument		Convert a generic document to the OL
				equivalent

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

DESCRIPTION:
	This file contains routines to handle the Open Look implementation
of a generic document.

	$Id: cspecDocument.asm,v 1.5 93/01/25 22:26:06 tony Exp $

------------------------------------------------------------------------------@

DocNewOpen segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLBuildDocument

DESCRIPTION:	Return the specific UI class for a GenDocument

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

OLBuildDocument	proc	far

	; Always convert to OLDocumentClass

	mov	dx, offset OLDocumentClass
	mov	cx, segment OLDocumentClass
	ret

OLBuildDocument	endp


DocNewOpen ends
