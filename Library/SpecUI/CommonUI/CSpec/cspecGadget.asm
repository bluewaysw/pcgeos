COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/CSpec (common code for several specific ui's)
FILE:		cspecGadget.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	OLBuildGadget		Convert a generic trigger to the OL equivalent

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version
	Eric	7/89		Motif extensions, more documentation

DESCRIPTION:
	This file contains routines to handle the Open Look implementation
of a generic gadget.

	$Id: cspecGadget.asm,v 1.1 97/04/07 10:50:34 newdeal Exp $

------------------------------------------------------------------------------@


Build segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLBuildGadget

DESCRIPTION:	Return the specific UI class for a GenGadget

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


OLBuildGadget	proc	far
	class	GenGadgetClass

	; If the GenGadget is not a composite, we use OLGadgetClass (whose
	; superclass is VisClass)
	; If the GenGadget is a composite, we use OLGadgetCompClass (whose
	; superclass is VisCompClass)

	mov	dx, offset OLGadgetClass	;assume no composite

	mov	di,ds:[si]
	add	di,ds:[di].Gen_offset
	test	ds:[di].GGI_attrs, mask GGA_COMPOSITE
	jz	OLBG_noComp
	mov	dx, offset OLGadgetCompClass	;assume no composite
OLBG_noComp:
	mov	cx, segment CommonUIClassStructures
	ret

OLBuildGadget	endp

Build ends
