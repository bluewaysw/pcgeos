COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Ruler Library
FILE:		rulerView.asm

AUTHOR:		Jon Witort

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	10 OCT 91	Initial version.

DESCRIPTION:
	This file contains the method handlers for RulerViewClass,
	a subclass off of GenView that ensures that the scale factor
	never changes.

	$Id: rulerView.asm,v 1.1 97/04/07 10:43:19 newdeal Exp $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RulerBasicCode	segment	resource



COMMENT @----------------------------------------------------------------------

METHOD:		RulerViewSpecBuild -- 
		MSG_SPEC_BUILD for RulerViewClass

DESCRIPTION:	Builds the ruler.  We need to a hint in here.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_BUILD

RETURN:		
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	11/ 4/92         	Initial Version

------------------------------------------------------------------------------@

RulerViewSpecBuild	method dynamic	RulerViewClass, MSG_SPEC_BUILD

	test	ds:[di].RVI_attrs, mask RVA_NO_SCROLLBAR
	jnz	done		
	;
	; Add the appropriate leave-room hint, as this seems possible through
	; default hints in a .uih file.
	;
	push	ax
	mov	ax, HINT_VIEW_LEAVE_ROOM_FOR_HORIZ_SCROLLER
	test	ds:[di].RVI_attrs, mask RVA_HORIZONTAL
	jz	10$			;vertical, we'll preserve LR bounds
	mov	ax, HINT_VIEW_LEAVE_ROOM_FOR_VERT_SCROLLER
10$:
	call	ObjVarAddData
	pop	ax
done:
	mov	di, offset RulerViewClass
	call	ObjCallSuperNoLock
	ret
RulerViewSpecBuild	endm


COMMENT @----------------------------------------------------------------------

METHOD:		RulerViewSetDocBounds -- 
		MSG_GEN_VIEW_SET_DOC_BOUNDS for RulerViewClass

DESCRIPTION:	Sets the document bounds for the ruler view.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VIEW_SET_DOC_BOUNDS
		ss:bp	- RectDWord

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	5/18/92		Initial Version

------------------------------------------------------------------------------@

RulerViewSetDocBounds	method dynamic	RulerViewClass, \
				MSG_GEN_VIEW_SET_DOC_BOUNDS

	; we only want to set doc bounds vertically for vertical rulers,
	; horizontally for horizontal ones.  Meaning, we'll stuff the current
	; left and right bounds back into the message params for vertical
	; rulers, and the opposite for horizontal.

	push	bp
	clr	bx
	test	ds:[di].RVI_attrs, mask RVA_HORIZONTAL
	jz	common			;vertical, we'll preserve LR bounds
	mov	bx, offset RD_top - offset RD_left	;otherwise TB bounds
common:
	add	di, bx
	add	bp, bx
	
	mov	cx, ds:[di].GVI_docBounds.RD_left.low
	mov	ss:[bp].RD_left.low, cx
	mov	cx, ds:[di].GVI_docBounds.RD_left.high
	mov	ss:[bp].RD_left.high, cx
	mov	cx, ds:[di].GVI_docBounds.RD_right.low
	mov	ss:[bp].RD_right.low, cx
	mov	cx, ds:[di].GVI_docBounds.RD_right.high
	mov	ss:[bp].RD_right.high, cx
	pop	bp

	mov	di, offset RulerViewClass
	call	ObjCallSuperNoLock
	ret
RulerViewSetDocBounds	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	RulerViewScaleLow -- MSG_GEN_VIEW_SCALE_LOW
							for RulerViewClass

DESCRIPTION:	Set the scale factor for the view

PASS:
	*ds:si - instance data
	es - segment of RulerViewClass

	ax - The message

	bp - ScaleViewParams

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/26/92		Initial version

------------------------------------------------------------------------------@
RulerViewScaleLow	method dynamic	RulerViewClass,	MSG_GEN_VIEW_SCALE_LOW

	; we only want to scale in one direction

	mov	bx, offset SVP_scaleFactor.PF_y		;assume horizontal
	test	ds:[di].RVI_attrs, mask RVA_HORIZONTAL
	jnz	common
	mov	bx, offset SVP_scaleFactor.PF_x
common:
	push	bp
	add	bp, bx
	movdw	ss:[bp], 0x10000
	pop	bp

	mov	di, offset RulerViewClass
	GOTO	ObjCallSuperNoLock

RulerViewScaleLow	endm

RulerBasicCode	ends
