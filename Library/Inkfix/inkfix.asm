COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	InkFix library
FILE:		inkfix.asm

AUTHOR:		Andrew Wilson, Oct 22, 1993

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/22/93		Initial revision

DESCRIPTION:
	

	$Id: inkfix.asm,v 1.1 97/04/05 01:06:34 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


;------------------------------------------------------------------------------
;			Include files
;------------------------------------------------------------------------------

include geos.def
include heap.def
include geode.def
include resource.def
include library.def
include ec.def
include vm.def
include dbase.def

include object.def
include graphics.def
include thread.def
include gstring.def
include Objects/inputC.def

include Objects/winC.def


UseLib ui.def
UseLib pen.def
DefLib Objects/inkfix.def

COORDINATE_OVERFLOW				enum FatalErrors
; Some internal error in TransformInkBlock

udata	segment
	needPosWorkarounds	BooleanByte
	; If this is non-zero, then we have an older (buggy) version of the
	; ink library, so use the workarounds for the bugs related to having
	; ink objects at non-0,0 offsets

	needEmptyInkChunkWorkarounds	BooleanByte
	; If this is non-zero, there are bugs in the ink library related to
	; having null II_segment fields.
udata	ends

idata	segment
	FixedInkClass
	InkParentClass
idata	ends

Code	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkfixEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine what the protocol # of the pen library is, so we
		know if we need to add our workarounds.

CALLED BY:	GLOBAL
PASS:		di - LibraryCallType
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/22/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MAJOR_PROTOCOL_NUMBER_OF_INK_LIBRARY_WITH_POSITIONING_BUGS	equ	1
MINOR_PROTOCOL_NUMBER_OF_INK_LIBRARY_WITH_POSITIONING_BUGS	equ	1

MAJOR_PROTOCOL_NUMBER_OF_INK_LIBRARY_WITH_EMPTY_INK_CHUNK_BUG	equ	1
MINOR_PROTOCOL_NUMBER_OF_INK_LIBRARY_WITH_EMPTY_INK_CHUNK_BUG	equ	2
InkfixEntry	proc	far
	.enter
	cmp	di, LCT_ATTACH
	jne	exit
	segmov	ds, dgroup, ax

;	Get the protocol number of the pen library, so we can see if we need
;	to add our workarounds or not.

	sub	sp, size ProtocolNumber
	mov	di, sp
	segmov	es, ss
	mov	ax, GGIT_GEODE_PROTOCOL
	mov	bx, handle pen
	call	GeodeGetInfo
	clr	ax			;We assume that the workarounds are
					; *not* necessary.
	cmp	es:[di].PN_major, MAJOR_PROTOCOL_NUMBER_OF_INK_LIBRARY_WITH_POSITIONING_BUGS
	ja	noPosFixes
	cmp	es:[di].PN_minor, MINOR_PROTOCOL_NUMBER_OF_INK_LIBRARY_WITH_POSITIONING_BUGS
	ja	noPosFixes
	mov	al, TRUE
noPosFixes:
	cmp	es:[di].PN_major, MAJOR_PROTOCOL_NUMBER_OF_INK_LIBRARY_WITH_EMPTY_INK_CHUNK_BUG
	ja	noFixes
	cmp	es:[di].PN_minor, MINOR_PROTOCOL_NUMBER_OF_INK_LIBRARY_WITH_EMPTY_INK_CHUNK_BUG
	ja	noFixes
	mov	ah, TRUE	
noFixes:
	add	sp, size ProtocolNumber
	mov	ds:[needPosWorkarounds], al
	mov	ds:[needEmptyInkChunkWorkarounds], ah
	
exit:
	clc
	.leave
	ret
InkfixEntry	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaveBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Saves the VI_bounds data in FII_realBounds

CALLED BY:	GLOBAL
PASS:		*ds:si - ink object
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/21/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaveBounds	proc	near	uses	cx, di, si, es
	class	FixedInkClass
	.enter
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	lea	si, ds:[di].VI_bounds	;DS:SI <- source structure
	add	di, offset FII_realBounds
	segmov	es, ds			;ES:DI <- dest structure

	mov	cx, (size Rectangle)/(size word)
	rep	movsw

	.leave
	ret
SaveBounds	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RestoreBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Restores the VI_bounds data from FII_realBounds.

CALLED BY:	GLOBAL
PASS:		*ds:si - ink object
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/21/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RestoreBounds	proc	near	uses	cx, di, si, es
	class	FixedInkClass
	.enter
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	lea	si, ds:[di].FII_realBounds	;DS:SI <- source structure
	add	di, offset VI_bounds
	segmov	es, ds			;ES:DI <- dest structure

	mov	cx, (size Rectangle)/(size word)
	rep	movsw
	.leave
	ret
RestoreBounds	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FixedInkVisDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets up a translation so the ink object can draw ink at a
		non-zero offset. 
		
		We also draw a rectangle around the ink object, to make it
		more visible.

CALLED BY:	GLOBAL
PASS:		cl - DrawFlags
		bp - gstate
RETURN:		nada
DESTROYED:	ax, cx, dx, bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/19/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FixedInkVisDraw	method	FixedInkClass, MSG_VIS_DRAW
	.enter

;	Only do workaround if we are using an older (Zoomer version)
;	pen library

	tst	es:[needPosWorkarounds]
	jnz	doWorkaround
	mov	di, offset FixedInkClass
	GOTO	ObjCallSuperNoLock

doWorkaround:

	mov	di, bp
	call	GrSaveState

;	Apply a translation so the ink draws at the object origin

	push	ax, cx, bp
	call	VisGetBounds
	mov_tr	dx, ax		;DX <- X offset of ink object
				;BX <- Y offset of ink object
	clr	cx		;DX.CX <- X translation to move ink from origin
				; of window to origin of ink object
	clr	ax		;BX.AX <- Y translation 
	call	GrApplyTranslation
	pop	ax, cx, bp

;	The ink object tries to set up a clip rectangle for the coming
;	drawing - change our bounds so they start at 0:0, as the translation
;	above has changed our coordinates to start there...

	call	SaveBoundsAndMoveToOrigin

	push	bp			;Save gstate
	mov	di, offset FixedInkClass	;Call ink object so it draws itself
	call	ObjCallSuperNoLock
	pop	bp

;	Restore our bounds...

	call	RestoreBounds

	mov	di, bp			;DI <- gstate to draw through
	call	GrRestoreState

	.leave
	ret
FixedInkVisDraw	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FixedInkVisInvalidate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If we truly just want to invalidate our bounds, then skip
		our parent.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	ax, cx, dx, bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/ 1/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FixedInkVisInvalidate	method	FixedInkClass, MSG_VIS_INVALIDATE
	.enter


;	Only do workaround if we are using an older (Zoomer version)
;	pen library

	tst	es:[needPosWorkarounds]
	jnz	doWorkaround
	mov	di, offset FixedInkClass
	GOTO	ObjCallSuperNoLock

doWorkaround:

;	Convert a MSG_VIS_INVALIDATE to a MSG_VIS_ADD_RECT_TO_UPDATE_REGION
;	passing the object's bounds, and send it directly to the win group,
;	without giving our meddling InkParent a chance to muck with the
;	bounds.
;
;	This fixes a bug where the wrong region is invalidated when you
;	load the ink data or change the stroke width/color.

	sub	sp, size VisAddRectParams
	mov	bp, sp
	call	VisGetBounds
	mov	ss:[bp].VARP_bounds.R_left, ax
	mov	ss:[bp].VARP_bounds.R_top, bx
	mov	ss:[bp].VARP_bounds.R_right, cx
	mov	ss:[bp].VARP_bounds.R_bottom, dx 
	mov	dx, size VisAddRectParams

	push	si
	mov	bx, segment VisClass
	mov	si, offset VisClass
	mov	ax, MSG_VIS_ADD_RECT_TO_UPDATE_REGION
	mov	di, mask MF_STACK or mask MF_RECORD
	call	ObjMessage
	pop	si

	mov	cx, di			;CX <- classed event
	mov	ax, MSG_VIS_VUP_CALL_WIN_GROUP
	call	ObjCallInstanceNoLock
	add	sp, size VisAddRectParams
	.leave
	ret
FixedInkVisInvalidate	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaveBoundsAndMoveToOrigin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Saves the current bounds of the ink object, and moves it to
		the origin.

CALLED BY:	GLOBAL
PASS:		*ds:si - ink object
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/21/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaveBoundsAndMoveToOrigin	proc	near	uses	ax, di
	class	FixedInkClass
	.enter

	call	SaveBounds

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	clr	ax
	xchg	ax, ds:[di].VI_bounds.R_left
	sub	ds:[di].VI_bounds.R_right, ax
	
	clr	ax
	xchg	ax, ds:[di].VI_bounds.R_top
	sub	ds:[di].VI_bounds.R_bottom, ax
	.leave
	ret
SaveBoundsAndMoveToOrigin	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkInk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This method handler modifies the ink points so they look as
		if they came in to an object at 0:0.

CALLED BY:	GLOBAL
PASS:		cx, dx, bp - MSG_META_NOTIFY_WITH_DATA_BLOCK args
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/20/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FixedInkInk	method	dynamic FixedInkClass, MSG_META_NOTIFY_WITH_DATA_BLOCK

;	Only do the workarounds if we are using an older version of the pen
;	library

	tst	es:[needPosWorkarounds]
	jz	callSuper
	cmp	dx, GWNT_INK
	jne	callSuper
	cmp	cx, MANUFACTURER_ID_GEOWORKS
	je	doInk
callSuper:
	mov	di, offset FixedInkClass
	GOTO	ObjCallSuperNoLock


doInk:
	push	ax, cx, dx, bp, es
	mov	bx, bp
	call	MemLock
	mov	es, ax

;	Transform the points in the ink block to be in our document coordinates

	call	TransformInkBlock

	call	MemUnlock
	pop	ax, cx, dx, bp, es

;	Move the ink object to 0,0, call the superclass, and restore the old
;	bounds.

	call	SaveBoundsAndMoveToOrigin
	mov	di, offset FixedInkClass
	call	ObjCallSuperNoLock
	call	RestoreBounds
	ret
FixedInkInk	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransformInkBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine transforms the passed ink block to be as if 
		it were entered over an ink object at the origin of the 
		window.

CALLED BY:	GLOBAL
PASS:		es - locked ink block
		ds:di,*ds:si - Ink object
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
 
PSEUDO CODE/STRATEGY:
	for each point in the block
		Convert the point to document coordinates
		Move the point as if it were entered relative to the 
			ink object instead of the origin of the window
		Translate the point back to screen coordinates

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/20/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TransformInkBlock	proc	near	uses	bx, si, di
	class	FixedInkClass
	.enter
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	bp, ds:[di].VI_bounds.R_left	;BP,DX <- bounds of object
	mov	dx, ds:[di].VI_bounds.R_top

;	Get window this object lies in

	call	VisQueryWindow

;	Transform the bounds (in case we have to invalidate them after an
;	 erase)

	mov	ax, es:[IH_bounds].R_left
	mov	bx, es:[IH_bounds].R_top
	call	WinUntransform		;
	sub	ax, bp			;Translate them to new coord system
	sub	bx, dx			;
	call	WinTransform
	mov	es:[IH_bounds].R_left, ax
	mov	es:[IH_bounds].R_top, bx
	
	mov	ax, es:[IH_bounds].R_right
	mov	bx, es:[IH_bounds].R_bottom
	call	WinUntransform
	sub	ax, bp			;Translate them to new coord system,
	sub	bx, dx			; and back to screen coords
	call	WinTransform		;
	mov	es:[IH_bounds].R_right, ax
	mov	es:[IH_bounds].R_bottom, bx

	mov	cx, es:[IH_count]
	mov	si, offset IH_data

loopTop:
;
;	Sit in a loop and transform the ink points to the coordinate system
; 	of an ink object that is at 0,0...
;
;	DI <- window our object lives in
;	CX <- # points left to transform
;	ES:SI <- ptr to point to transform
;	BP - left vis bound of object
;	DX - right vis bound of object

	mov	ax, es:[si].P_x
	mov	bx, es:[si].P_y

;	AX <-   ink  X coordinate:
;		High bit - set if this is the end of an ink stroke
;		low 15 bits - signed x coordinate
;
;	Convert the 15-bit signed X coordinate value to an 8-bit signed value
;	so it can be transformed to window coords

	shl	ax			;High Bit -> carry
	pushf	
	sar	ax			;Sign extend the 15-bit value in AX

	call	WinUntransform		;Transform the coordinate to our window
	sub	ax, bp			; coords, and then into our personal
	sub	bx, dx			; object vis coords
	call	WinTransform

;	Transform the X coordinate into a 15-bit signed value, and set the high
;	bit to be 1 if it was the end of the line segment

EC <	test	ah, 0xc0						>
EC <	ERROR_PO COORDINATE_OVERFLOW					>
	andnf	ax, 0x7fff		;Clear the high bit (it is a seven-bit
					; signed number)
	popf				;Restore the "end of stroke" flag
	jnc	10$			;
	ornf	ax, 0x8000		;
10$:
	mov	es:[si].P_x, ax
	mov	es:[si].P_y, bx
	add	si, size Point
	loop	loopTop
	.leave
	ret
TransformInkBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkMouseEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The goal here is to fool the ink object into thinking it is
		at 0,0 so map every mouse event to the correct coords.

CALLED BY:	GLOBAL
PASS:		*ds:si - object
		cx - X pos of mouse
		dx - Y pos of mouse
		bp - flags
RETURN:		whatever from object
DESTROYED:	whatever from object method handler
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/20/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkMouseEvent	method	FixedInkClass,	MSG_META_MOUSE_PTR, 
					MSG_META_START_SELECT,
					MSG_META_END_SELECT
	.enter

;	Only do workaround if we are using an older (Zoomer version)
;	pen library

	tst	es:[needPosWorkarounds]
	jnz	doWorkaround
	mov	di, offset FixedInkClass
	GOTO	ObjCallSuperNoLock

doWorkaround:

;	Save the bounds of the object before we munge them

	call	SaveBounds

;	Map the bounds of the object and the start select to a new coordinate
;	system, where the object itself is at 0,0

	clr	bx
	xchg	bx, ds:[di].VI_bounds.R_left
	sub	ds:[di].VI_bounds.R_right, bx
	sub	cx, bx
	
	clr	bx
	xchg	bx, ds:[di].VI_bounds.R_top
	sub	ds:[di].VI_bounds.R_bottom, bx
	sub	dx, bx

	mov	di, offset FixedInkClass
	call	ObjCallSuperNoLock

;	Restore the bounds of the object to their pre-munged values

	call	RestoreBounds
	.leave
	ret
InkMouseEvent	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FixedInkGetRealBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the "real" bounds of the ink object, in the same way
		that MSG_VIS_GET_BOUNDS does.

CALLED BY:	GLOBAL
PASS:		ax - left
		bp - top
		cx - right
		dx - bottom
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/21/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FixedInkGetRealBounds	method FixedInkClass, MSG_FIXED_INK_GET_REAL_BOUNDS
	.enter
	mov	ax, ds:[di].FII_realBounds.R_left	;add in real bounds
	mov	bp, ds:[di].FII_realBounds.R_top
	mov	cx, ds:[di].FII_realBounds.R_right
	mov	dx, ds:[di].FII_realBounds.R_bottom
	.leave
	ret
FixedInkGetRealBounds	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FixedInkAddRectToUpdateRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This tweaks the values passed w/MSG_VIS_ADD_RECT_TO_UPDATE_REG
		to take into account the object being at a non-zero offset.

CALLED BY:	GLOBAL
PASS:		*ds:si - FixedInkClass object
		ss:bp - VisAddRectParams
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/21/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FixedInkAddRectToUpdateRegion	method	FixedInkClass, 
					MSG_VIS_ADD_RECT_TO_UPDATE_REGION


;	Just exit if we don't need to do any of the bug workarounds

	tst	es:[needPosWorkarounds]
	jz	40$

	mov	bx, ds:[di].FII_realBounds.R_left
	add	ss:[bp].VARP_bounds.R_left, bx
	add	ss:[bp].VARP_bounds.R_right, bx

;	Change update region to remain within our bounds

	mov	bx, ds:[di].FII_realBounds.R_right
	cmp	ss:[bp].VARP_bounds.R_left, bx
	jle	10$
	mov	ss:[bp].VARP_bounds.R_left, bx
10$:
	cmp	ss:[bp].VARP_bounds.R_right, bx
	jle	20$
	mov	ss:[bp].VARP_bounds.R_right, bx
20$:

	mov	bx, ds:[di].FII_realBounds.R_top
	add	ss:[bp].VARP_bounds.R_top, bx
	add	ss:[bp].VARP_bounds.R_bottom, bx

	mov	bx, ds:[di].FII_realBounds.R_bottom
	cmp	ss:[bp].VARP_bounds.R_top, bx
	jle	30$
	mov	ss:[bp].VARP_bounds.R_top, bx
30$:
	cmp	ss:[bp].VARP_bounds.R_bottom, bx
	jle	40$
	mov	ss:[bp].VARP_bounds.R_bottom, bx
40$:

	mov	di, offset FixedInkClass
	GOTO	ObjCallSuperNoLock
FixedInkAddRectToUpdateRegion	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetChildBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the child of the first vis parent.

CALLED BY:	GLOBAL
PASS:		*ds:si - a vis parent
RETURN:		ax - left edge of child
		cx - right edge
		bx - top edge
		dx - bottom edge of child
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/20/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetChildBounds	proc	near	uses	bp, di, si
	class	VisCompClass		
	.enter
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	movdw	bxsi, ds:[di].VCI_comp
	mov	ax, MSG_FIXED_INK_GET_REAL_BOUNDS
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	mov	bx, bp
	.leave
	ret
GetChildBounds	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkParentVupCreateGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	When we are asked to create a gstate, we apply a translation
		equal to the position of our child

CALLED BY:	GLOBAL
PASS:		*ds:si - object
RETURN:		nada
DESTROYED:	ax, cx, dx, bp 
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/20/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkParentVupCreateGState	method	InkParentClass, MSG_VIS_VUP_CREATE_GSTATE
	.enter

	mov	di, offset InkParentClass
	call	ObjCallSuperNoLock
	jnc	exit			;Exit if no gstate returned
	tst	es:[needPosWorkarounds]	;Just exit if we don't need to do
	jz	done			; any of the workarounds

	mov	di, ds:[si]
	add	di, ds:[di].InkParent_offset
	tst	ds:[di].IPI_doNotTranslateGState
	jnz	done

;	Find the offset of the first (and only) child of this object, and apply
;	a translation so it can pretend as if it is at 0,0

	call	GetChildBounds		;ax - left edge of child
					;bx - top edge

	mov	di, bp			;DI <- gstate we are returning
	mov_tr	dx, ax
	clr	ax			;BX.AX <- Y translation
	clr	cx			;DX.CX <- X translation
	call	GrApplyTranslation

;
;	Clip the gstate to the bounds of the object
;
	call	GetChildBounds
	sub	dx, bx			;Move to origin...
	sub	cx, ax
	clr	ax, bx
	mov	si, PCT_INTERSECTION
	call	GrSetWinClipRect
done:
	stc
exit:
	.leave
	ret
InkParentVupCreateGState	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkParentQueryIfPressIsInk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The ink object deals correctly with being at an odd offset
		when setting up a gstate for ink, so disable the translation
		stuff for this method handler.

CALLED BY:	GLOBAL
PASS:		*ds:si - object
RETURN:		nada
DESTROYED:	ax, cx, dx, bp 
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/20/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkParentQueryIfPressIsInk	method	InkParentClass, MSG_META_QUERY_IF_PRESS_IS_INK
	.enter
	mov	bl, TRUE
	xchg	ds:[di].IPI_doNotTranslateGState, bl
	mov	di, offset InkParentClass
	call	ObjCallSuperNoLock

	mov	di, ds:[si]
	add	di, ds:[di].InkParent_offset
	mov	ds:[di].IPI_doNotTranslateGState, bl
	.leave
	ret
InkParentQueryIfPressIsInk	endp



;
;	Workarounds for bugs with GetInkInBounds (it uses an invalid value
;	for the size of the ink, which can lead to memory trashing). We
;	basically just don't ever let II_segments be 0.
;



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FixedInk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	When the ink object gets onscreen, we make sure that the
		ink-chunk is non-zero.

CALLED BY:	GLOBAL
PASS:		method-specific stuff
RETURN:		whatever from superclass
DESTROYED:	whatever from superclass
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/ 6/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FixedInkEnsureNonZeroInkChunk	method	FixedInkClass, 
				MSG_VIS_OPEN,
				MSG_INK_LOAD_FROM_DB_ITEM,
				MSG_META_UNDO

	call	EnsureNonZeroInkChunk

	mov	di, offset FixedInkClass
	call	ObjCallSuperNoLock

	call	EnsureNonZeroInkChunk
	ret
FixedInkEnsureNonZeroInkChunk	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnsureNonZeroInkChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ensures that the ink object has an II_segments field

CALLED BY:	GLOBAL
PASS:		*ds:si - Ink class object
		es - dgroup
RETURN:		nada
DESTROYED:	nada (flags preserved)
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/ 6/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnsureNonZeroInkChunk	proc	near	uses	ax, bx, cx, di, si
	class InkClass
	.enter
	pushf

;	needEmptyInkChunkWorkarounds is set to non-zero if the pen library is
;	protocol 1.2 or below - the bug is fixed in later versions.

	tst	es:[needEmptyInkChunkWorkarounds]
	jz	exit
	
	mov	di, ds:[si]
	add	di, ds:[di].Ink_offset
	tst	ds:[di].II_segments
	jnz	exit

;	Allocate an empty chunk array to hold the line segments - the code
;	in the pen library does not correctly handle the case where II_segments
;	is 0.

	push	si
	mov	bx, size Point	;Size of each element
	clr	cx		;No extra space
	clr	si		;Create a new chunk handle
	mov	al, mask OCF_DIRTY
	call	ChunkArrayCreate
	mov	cx, si		;CX <- chunk handle of chunk array for points
	pop	si		;*DS:SI <- Ink object

;	Stuff the chunk handle for the newly created line-segment array back
;	in to the object's instance data.

	mov	di, ds:[si]
	add	di, ds:[di].Ink_offset
	mov	ds:[di].II_segments, cx
	call	ObjMarkDirty	;We changed the instance data, so mark the 
				; object dirty.
exit:
	popf
	.leave
	ret
EnsureNonZeroInkChunk	endp

if 0
;
; It turns out that Vis objects shouldn't release the target when they are
; closed.
;

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FixedInkVisClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Releases the target after closing the object...

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/14/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FixedInkVisClose	method	FixedInkClass, MSG_VIS_CLOSE
	mov	di, offset FixedInkClass
	call	ObjCallSuperNoLock

	mov	ax, MSG_META_RELEASE_TARGET_EXCL
	GOTO	ObjCallSuperNoLock
FixedInkVisClose	endp
endif

Code	ends


