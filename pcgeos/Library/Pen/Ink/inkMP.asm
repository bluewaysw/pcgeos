COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		InkTest (Sample PC GEOS application)
FILE:		inktest.asm

ROUTINES:


    INT InvertPasteBitmap       Utility routine to invert the bits of the
				paste bitmap

    INT DragPasteSelection

    INT GetPasteSelectionBoundingBox 
				Loads IMPI_pastedBounds with the bounds of
				the pasted selection.

    INT GetPointsArray          Utility routine to access ink's points
				array

    INT EraseBitmap             Utility routine to allocate a gstate and
				draw the paste bitmap into it.

    INT FreeBitmap              Utility routine to free the bitmap

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	tony	7/91		Initial version

DESCRIPTION:
	This file source code for the InkTest application. This code will
	be assembled by ESP, and then linked by the GLUE linker to produce
	a runnable .geo application file.

IMPORTANT NOTE:
	This sample application is primarily intended to demonstrate a
	model for using the ink object.  Basic parts of a PC/GEOS application
	are not documented heavily here.  See the "Hello" sample application
	for more detailed documentation on the standard parts of a PC/GEOS
	application.

RCS STAMP:
	$Id: inkMP.asm,v 1.1 97/04/05 01:27:55 newdeal Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			Include files
;------------------------------------------------------------------------------

include geos.def
include heap.def
include geode.def
include resource.def
include ec.def
include vm.def
include dbase.def
include system.def

include object.def
include graphics.def
include thread.def
include gstring.def
include Objects/inputC.def

include Objects/winC.def

;------------------------------------------------------------------------------
;			Libraries used
;------------------------------------------------------------------------------

UseLib ui.def
UseLib Objects/inkfix.def
DefLib pen.def

;------------------------------------------------------------------------------
;			Class & Method Definitions
;------------------------------------------------------------------------------

PenClassStructures	segment	resource
	InkMPClass
PenClassStructures	ends

;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------

InkMPCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkMPMetaClipboardPaste
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_META_CLIPBOARD_PASTE
PASS:		*ds:si	= InkMPClass object
		ds:di	= InkMPClass instance data
		ds:bx	= InkMPClass object (same as *ds:si)
		es 	= segment of InkMPClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	9/19/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkMPMetaClipboardPaste	method dynamic InkMPClass, 
					MSG_META_CLIPBOARD_PASTE
	uses	ax, cx, dx, bp
	.enter

	;
	;  If we've already got a paste on the table, then hooey it.
	;

;		test	ds:[di].IMPI_flags, mask IMPF_HAS_PASTE_SELECTION
;		LONG jnz	done

	;
	; If user hasn't completed a previous paste, then complete it
	; for h[ie][rm]
	;

		test	ds:[di].IMPI_flags, mask IMPF_HAS_PASTE_SELECTION
		jz	continue

		mov	ax, MSG_INKMP_FINISH_PASTE
		call	ObjCallInstanceNoLock

		mov	di, ds:[si]
		add	di, ds:[di].InkMP_offset
continue:

	;
	; The new data goes at the end of the old data
	;
		mov_tr	ax, si
		mov	si, ds:[di].II_segments
		clr	cx
		tst	si
		jz	noStart
		call	ChunkArrayGetCount
noStart:
		mov	ds:[di].IMPI_pastedStart, cx
		mov_tr	si, ax

	;
	; Set the selection bounds outside of the visual bounds so we
	; don't have to deal with drawing the thing until it's in the
	; right place.
	;

		call	NukeSelection

		mov	ax, ds:[di].VI_bounds.R_right
		sub	ax, ds:[di].VI_bounds.R_left
		inc	ax				; just to be sure
		mov	ds:[di].II_selectBounds.R_left, ax
		mov	ds:[di].II_selectBounds.R_right, ax
	
		mov	ax, ds:[di].VI_bounds.R_bottom
		sub	ax, ds:[di].VI_bounds.R_top
		inc	ax				; just to be sure
		mov	ds:[di].II_selectBounds.R_top, ax
		mov	ds:[di].II_selectBounds.R_bottom, ax
	
	;
	; Get the paste data
	;
		mov	ax, MSG_META_CLIPBOARD_PASTE
		mov	di, offset InkMPClass
		call	ObjCallSuperNoLock

	;
	; Find end of data
	;
		push	si
		mov	di, ds:[si]
		add	di, ds:[di].InkMP_offset
		mov	si, ds:[di].II_segments
	;
	; See if there are any points now.  If not, forget about it
	;
		mov	cx, ds:[di].IMPI_pastedStart
		tst	si
		jz	dontCount
		call	ChunkArrayGetCount
dontCount:
		mov	ds:[di].IMPI_pastedEnd, cx
		pop	si

	;
	; If the start & end are the same (I don't know why they would be,
	; but it happened...), then forget about it.
	;

		cmp	ds:[di].IMPI_pastedStart, cx
		LONG je	done

	;
	; Set flags
	;

		mov	cx, ds:[di].II_tool
		mov	ds:[di].IMPI_oldTool, cx

if 0
		mov	ax, MSG_INK_SET_TOOL
		mov	cx, IT_PENCIL
		call	ObjCallInstanceNoLock
endif
		mov	ax, MSG_INK_SET_TOOL
		mov	cx, IT_SELECTOR
		call	ObjCallInstanceNoLock

	;
	;  Have to do this after the tool change so that that doesn't
	;  kill our paste
	;
	
		mov	di, ds:[si]
		add	di, ds:[di].InkMP_offset
		mov	ds:[di].IMPI_flags, mask IMPF_HAS_PASTE_SELECTION

	;
	;  Move the thing to the middle of the ink object
	;

		call	GetPasteSelectionBoundingBox

		call	GetGState
		tst	di

		call	GrGetWinBounds
		call	GrDestroyState

		push	bx, dx				;save top, bottom

		mov	di, ds:[si]
		add	di, ds:[di].InkMP_offset
		mov	bx, ds:[di].IMPI_pastedBounds.R_left
		sub	bx, ds:[di].IMPI_pastedBounds.R_right

		cmp	cx, ds:[di].VI_bounds.R_right
		jle	haveRight
		mov	cx, ds:[di].VI_bounds.R_right
haveRight:
		cmp	ax, ds:[di].VI_bounds.R_left
		jge	haveLeft
		mov	ax, ds:[di].VI_bounds.R_left
haveLeft:
		add	bx, cx
		sub	bx, ax
		sar	bx
		add	bx, ax

		cmp	bx, ds:[di].VI_bounds.R_right
		jle	checkTooFarLeft

		mov	bx, ds:[di].VI_bounds.R_right
		sub	bx, ds:[di].IMPI_pastedBounds.R_right
		add	bx, ds:[di].IMPI_pastedBounds.R_left

checkTooFarLeft:
		cmp	bx, ds:[di].VI_bounds.R_left
		jge	setX

		mov	bx, ds:[di].VI_bounds.R_left
setX:
		mov	ds:[di].IMPI_lastPos.P_x, bx

		pop	ax, cx

		mov	bx, ds:[di].IMPI_pastedBounds.R_top
		sub	bx, ds:[di].IMPI_pastedBounds.R_bottom

		cmp	cx, ds:[di].VI_bounds.R_bottom
		jle	haveBottom
		mov	cx, ds:[di].VI_bounds.R_bottom
haveBottom:
		cmp	ax, ds:[di].VI_bounds.R_top
		jge	haveTop
		mov	ax, ds:[di].VI_bounds.R_top
haveTop:
		add	bx, cx
		sub	bx, ax
		sar	bx
		add	bx, ax

		cmp	bx, ds:[di].VI_bounds.R_bottom
		jle	checkTooFarUp

		mov	bx, ds:[di].VI_bounds.R_bottom
		sub	bx, ds:[di].IMPI_pastedBounds.R_bottom
		add	bx, ds:[di].IMPI_pastedBounds.R_top

checkTooFarUp:
		cmp	bx, ds:[di].VI_bounds.R_top
		jge	setY

		mov	bx, ds:[di].VI_bounds.R_top
setY:

		mov	ds:[di].IMPI_lastPos.P_y, bx

	;
	; Create the bitmap for dragging around
	;

		mov	ax, MSG_INKMP_CREATE_PASTE_BITMAP
		call	ObjCallInstanceNoLock

	;
	;  The bitmap is yet uninverted, but since that's what we really
	;  want for Jedi, we'll draw it first, then invert it later.
	;

		call	GetGState
		tst	di
		jz	done

		mov	bp, di
		mov	ax, MSG_INKMP_DRAW_PASTE_BITMAP
		call	ObjCallInstanceNoLock

		call	GrDestroyState

done:
	.leave
	ret
InkMPMetaClipboardPaste	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkMPCreatePasteBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_META_CLIPBOARD_PASTE

PASS:		*ds:si	= InkMPClass object
		ds:di	= InkMPClass instance data
		ds:bx	= InkMPClass object (same as *ds:si)
		es 	= segment of InkMPClass
		ax	= message #

		cx - vm file to allocate bitmap in

RETURN:		ax - vm block handle
		bp - gstate to bitmap
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	9/19/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkMPCreatePasteBitmap	method InkMPClass, MSG_INKMP_CREATE_PASTE_BITMAP
	uses	cx, dx
	.enter

	;
	;  Get the bounds of the pasted ink
	;

	call	GetPasteSelectionBoundingBox

	;
	;  Get the bounds of the necessary bitmap
	;
	mov	bp, ds:[si]
	add	bp, ds:[bp].InkMP_offset
	mov	cx, ds:[bp].IMPI_pastedBounds.R_right
	sub	cx, ds:[bp].IMPI_pastedBounds.R_left
	mov	dx, ds:[bp].IMPI_pastedBounds.R_bottom
	sub	dx, ds:[bp].IMPI_pastedBounds.R_top

	;
	;  Set the exposed OD to our process thread. I never understood this.
	;
	call	GeodeGetProcessHandle
	mov	di, bx

	;
	;  We're stuffing this thing into the clipboard file
	;
	call	ClipboardGetClipboardFile

	;
	;  Just mono for me, thanks.
	;
        mov     al, BMF_MONO shl offset BMT_FORMAT
	call	GrCreateBitmap

	mov	ds:[bp].IMPI_pasteBitmap, ax		
	mov	ds:[bp].IMPI_pasteBitmapGState, di

	push	ax						;save block

	;
	;  Now let's draw all that lovely ink into the thing.
	;

	mov	dx, ds:[bp].IMPI_pastedBounds.R_left
	add	dx, ds:[bp].VI_bounds.R_left
	neg	dx
	mov	bx, ds:[bp].IMPI_pastedBounds.R_top
	add	bx, ds:[bp].VI_bounds.R_top
	neg	bx
	clr	cx, ax
	call	GrSaveState
	call	GrApplyTranslation

	mov	bp, di				;bp <- gstate
	push	si
	call	GetPointsArray
	call	ChunkArrayElementToPtr
	segmov	es, ds
	pop	si

	clr	dx
	call	DrawMultipleLineSegments

	mov	di, bp
	call	GrRestoreState

	call	InvertPasteBitmap

	pop	ax						;ax <- block

	.leave
	ret
if 0
	;
	;  Draw a big inverted rectangle over what we just drew, because
	;  the thing is apparently the opposite of what we need later,
	;  although I can't figure out why.
	;


	mov	al, MM_INVERT
	call	GrSetMixMode

	pop	cx, dx
	inc	cx
	inc	dx
	clr	ax, bx
	call	GrFillRect

	mov	al, BMD_LEAVE_DATA
	call	GrDestroyBitmap
endif

InkMPCreatePasteBitmap	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkMPMetaStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_META_DRAG_SELECT
PASS:		*ds:si	= InkMPClass object
		ds:di	= InkMPClass instance data
		ds:bx	= InkMPClass object (same as *ds:si)
		es 	= segment of InkMPClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	9/19/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkMPMetaStartSelect	method dynamic InkMPClass, 
			MSG_META_START_SELECT

		test	ds:[di].IMPI_flags, mask IMPF_HAS_PASTE_SELECTION
		LONG jz	callSuper

		ornf	ds:[di].IMPI_flags, mask IMPF_DRAGGING

	;
	;  If the mouse click occured outside of the inverted bounds, then
	;  we'll just drop the paste where it lies and go on with our lives.
	;

		sub	cx, ds:[di].IMPI_lastPos.P_x
		js	outOfBounds
		sub	dx, ds:[di].IMPI_lastPos.P_y
		js	outOfBounds

		mov	ax, ds:[di].IMPI_pastedBounds.R_right
		sub	ax, ds:[di].IMPI_pastedBounds.R_left

		cmp	cx, ax
		jae	outOfBounds
		
		mov	ax, ds:[di].IMPI_pastedBounds.R_bottom
		sub	ax, ds:[di].IMPI_pastedBounds.R_top

		cmp	dx, ax
		jb	inBounds

outOfBounds:

		mov	ax, MSG_INKMP_FINISH_PASTE
		call	ObjCallInstanceNoLock

		mov	ax, MSG_INK_SET_TOOL
		mov	di, ds:[si]
		add	di, ds:[di].InkMP_offset
		mov	cx, ds:[di].IMPI_oldTool
		call	ObjCallInstanceNoLock

		jmp	done

inBounds:
		neg	cx
		neg	dx
		mov	ds:[di].IMPI_bitmapMouseOffset.P_x, cx
		mov	ds:[di].IMPI_bitmapMouseOffset.P_y, dx

	;
	;  Erase the reverse video thing we did before 
	;
		call	GetGState
		tst	di
		jz	afterInvert

		mov	bp, di
		mov	ax, MSG_INKMP_DRAW_PASTE_BITMAP
		call	ObjCallInstanceNoLock

afterInvert:

	;
	;  Invert the bitmap so that it draws in "normal" video.
	;
		call	InvertPasteBitmap

		mov	bx, ds:[si]
		add	bx, ds:[bx].InkMP_offset
		clr	di
		xchg	di, ds:[bx].IMPI_pasteBitmapGState
		tst	di
		jz	afterBitmapGState
		mov	al, BMD_LEAVE_DATA
		call	GrDestroyBitmap

	;
	;  Compact the thing for quicker drawing...?
	;

if 0
		call	ClipboardGetClipboardFile
		mov	dx, bx
		mov	di, ds:[si]
		add	di, ds:[di].InkMP_offset
		mov	ax, ds:[di].IMPI_pasteBitmap
		call	GrCompactBitmap
		mov	ds:[di].IMPI_pasteBitmap, cx

		push	bp
		clr	bp
		call	VMFreeVMChain
		pop	bp
endif

afterBitmapGState:

	;
	;  Draw in the first normal video image
	;
		tst	bp
		jz	afterDestroy

		mov	ax, MSG_INKMP_DRAW_PASTE_BITMAP
		call	ObjCallInstanceNoLock

		mov	di, bp
		call	GrDestroyState

afterDestroy:

	;
	;  Compute the offset of the mouse & the bitmap


	;
	;  If the mouse event was within the inverted bounds, then we
	;  want to drag the 


		call	VisGrabMouse
done:
		mov	ax, mask MRF_PROCESSED
		ret
callSuper:
		
		andnf	ds:[di].IMPI_flags, not (mask IMPF_DRAGGING or \
						mask IMPF_HAS_PASTE_SELECTION)
		mov	di, offset InkMPClass
		GOTO	ObjCallSuperNoLock

InkMPMetaStartSelect	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			InvertPasteBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine to invert the bits of the paste bitmap

PASS:		*ds:si	= InkMPClass object

RETURN:		nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	28 dec 94	initial revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InvertPasteBitmap	proc	near
	class	InkMPClass
	uses	ax, bx, cx, dx, bp, di
	.enter

	mov	bp, ds:[si]
	add	bp, ds:[bp].InkMP_offset
	mov	di, ds:[bp].IMPI_pasteBitmapGState
	tst	di
	jz	done

	mov	al, MM_INVERT
	call	GrSetMixMode

	mov	cx, ds:[bp].IMPI_pastedBounds.R_right
	sub	cx, ds:[bp].IMPI_pastedBounds.R_left
	mov	dx, ds:[bp].IMPI_pastedBounds.R_bottom
	sub	dx, ds:[bp].IMPI_pastedBounds.R_top
	inc	cx
	inc	dx
	clr	ax, bx
	call	GrFillRect

done:
	.leave
	ret
InvertPasteBitmap	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkMPMetaPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_META_PTR
PASS:		*ds:si	= InkMPClass object
		ds:di	= InkMPClass instance data
		ds:bx	= InkMPClass object (same as *ds:si)
		es 	= segment of InkMPClass
		ax	= message #
		(cx,dx) = ptr coords
RETURN:		ax = MouseReturnFlags
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	9/19/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkMPMetaPtr	method dynamic InkMPClass, 
					MSG_META_PTR

		test	ds:[di].IMPI_flags, mask IMPF_DRAGGING
		LONG jz	callSuper
	;
	;  If this event isn't within the ink's vis bounds, then
	;  we put up the "no way" (modal) cursor, and bail
	;

		call	VisTestPointInBounds
		LONG jnc	notInBounds

	;
	; Tell ourselves to drag the bitmap
	;
		mov	bx, ds:[LMBH_handle]
		mov	ax, MSG_INKMP_DRAG_BITMAP
		mov	di, mask MF_FORCE_QUEUE or mask MF_CHECK_DUPLICATE or \
			    mask MF_REPLACE
		call	ObjMessage
		mov	ax, mask MRF_PROCESSED or mask MRF_CLEAR_POINTER_IMAGE
		ret

notInBounds:

		mov	ax, mask MRF_PROCESSED or mask MRF_SET_POINTER_IMAGE
		mov	cx, handle NoWayCursor
		mov	dx, offset NoWayCursor
		ret
callSuper:
		mov	di, offset InkMPClass
		GOTO	ObjCallSuperNoLock

InkMPMetaPtr	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IMPInkmpDragBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_INKMP_DRAG_BITMAP
PASS:		*ds:si	= InkMPClass object
		ds:di	= InkMPClass instance data
		ds:bx	= InkMPClass object (same as *ds:si)
		es 	= segment of InkMPClass
		ax	= message #
		(cx,dx) = ptr coords
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	4/11/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IMPInkmpDragBitmap	method dynamic InkMPClass, 
					MSG_INKMP_DRAG_BITMAP



	;
	; Draw the new ink
	;

		add	cx, ds:[di].IMPI_bitmapMouseOffset.P_x
		add	dx, ds:[di].IMPI_bitmapMouseOffset.P_y

	;
	; Do bounds checking on cx, dx here...
	;

		mov	ax, ds:[di].VI_bounds.R_left
		cmp	cx, ax
		jge	checkRight

		mov_tr	cx, ax
		jmp	checkY

checkRight:
		mov	ax, ds:[di].VI_bounds.R_right
		sub 	ax, ds:[di].IMPI_pastedBounds.R_right
		add	ax, ds:[di].IMPI_pastedBounds.R_left

		cmp	cx, ax
		jle	checkY

		mov_tr	cx, ax

checkY:
		mov	ax, ds:[di].VI_bounds.R_top
		cmp	dx, ax
		jge	checkBottom

		mov_tr	dx, ax
		jmp	haveNew

checkBottom:
		mov	ax, ds:[di].VI_bounds.R_bottom
		sub 	ax, ds:[di].IMPI_pastedBounds.R_bottom
		add	ax, ds:[di].IMPI_pastedBounds.R_top

		cmp	dx, ax
		jle	haveNew

		mov_tr	dx, ax
haveNew:			; (cx,dx) = clipped bitmap coords
	;
	; If we haven't moved far enough, don't redraw the bitmap, so
	; that on devices with very fine digitizers, the wobbling
	; coordinates don't cause really flickered redra
	;
		mov	bx, cx
		sub	bx, ds:[di].IMPI_lastPos.P_x
		add	bx, PEN_DRAG_WOBBLE_TOLERANCE
		cmp	bx, PEN_DRAG_WOBBLE_TOLERANCE*2
		ja	drawIt

		mov	bx, dx
		sub	bx, ds:[di].IMPI_lastPos.P_y
		add	bx, PEN_DRAG_WOBBLE_TOLERANCE
		cmp	bx, PEN_DRAG_WOBBLE_TOLERANCE*2
		jna	afterGState
drawIt:
		mov	bp, di

		call	GetGState
		tst	di
		jz	afterGState

		mov	bp, di
		mov	ax, MSG_INKMP_DRAW_PASTE_BITMAP
		call	ObjCallInstanceNoLock

	;
	;  Save the new ink, erase the old.
	;

		mov	di, ds:[si]
		add	di, ds:[di].InkMP_offset
		mov	ds:[di].IMPI_lastPos.P_x, cx
		mov	ds:[di].IMPI_lastPos.P_y, dx
		mov	ax, MSG_INKMP_DRAW_PASTE_BITMAP
		call	ObjCallInstanceNoLock

		mov	di, bp
		call	GrDestroyState

afterGState:

		ret


IMPInkmpDragBitmap	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DragPasteSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		*ds:si	= InkMPClass object
		ds:di	= InkMP instance
		cx,dx	= amount to move paste

RETURN:		ds	= pointing to same block as passed
DESTROYED:	nothing
SIDE EFFECTS:	IMPI_lastPos will be set to cx,dx, but possibly constrained
		so that the dragged region falls within the ink object.

	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  then on the heap and invalidating stored segment pointers
		  and current register or stored offsets to them.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	9/20/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DragPasteSelection	proc	near
	class	InkMPClass
	uses	ax, bx, di, si, bp
	.enter

	;
	; Move the bounding box, and massage the deltas if it causes
	; the upper left to go negative.
	;

		mov	bx, cx

	;
	; Get pointer to beginning of pasted segments
	;
		call	GetPointsArray
		jcxz	exit
		call	ChunkArrayElementToPtr	   ; ds:di = elt

loopTop:
	; Let point = point + delta

		add	ds:[di].P_x, bx
		add	ds:[di].P_y, dx

		add	di, size Point
		loop	loopTop
exit:
	.leave
	ret

DragPasteSelection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			InkMPDrawPasteBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws the paste bitmap, inverted, into the passed GState

PASS:		*ds:si	= InkMPClass object
		bp - gstate
		
RETURN:		nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	27 dec 1994	why didn't i take this week off?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkMPDrawPasteBitmap	method InkMPClass, MSG_INKMP_DRAW_PASTE_BITMAP
	uses	cx, dx
	.enter

	mov	cx, ds:[di].IMPI_pasteBitmap
	jcxz	done

	mov	bx, ds:[di].IMPI_lastPos.P_x
	mov	dx, ds:[di].IMPI_lastPos.P_y

	mov	di, bp
	call	SetClipRectToVisBounds

	call	GrGetMixMode
	push	ax
	mov	al, MM_INVERT
	call	GrSetMixMode

	mov_tr	ax, bx
	call	ClipboardGetClipboardFile
	xchg	dx, bx

	call	GrDrawHugeBitmap

	pop	ax
	call	GrSetMixMode

done:
	.leave
	ret
InkMPDrawPasteBitmap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetPasteSelectionBoundingBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Loads IMPI_pastedBounds with the bounds of the pasted
		selection.

CALLED BY:	
PASS:		*ds:si	= InkMP object

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	9/20/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetPasteSelectionBoundingBox	proc	near
	class	InkMPClass
	uses	ax,bx,cx,dx,si,di,bp
	.enter
	;
	; Get pointer to beginning of pasted segments
	;
		mov	bp, ds:[si]
		add	bp, ds:[bp].InkMP_offset

		push	si
		call	GetPointsArray
		call	ChunkArrayElementToPtr	   ; ds:di = elt

		mov	ds:[bp].IMPI_pastedBounds.R_left, 0x7fff
		mov	ds:[bp].IMPI_pastedBounds.R_top, 0x7fff
		mov	ds:[bp].IMPI_pastedBounds.R_right, 0x8000
		mov	ds:[bp].IMPI_pastedBounds.R_bottom, 0x8000
loopTop:
	;
	; Foreach point, expand the bounding box such that the point
	; falls within the bounding box
	;
;testLeft:
		mov	ax, ds:[di].P_x
		andnf	ax, 0x7fff
		cmp	ax, ds:[bp].IMPI_pastedBounds.R_left
		jge	testRight
		mov	ds:[bp].IMPI_pastedBounds.R_left, ax
testRight:
		cmp	ax, ds:[bp].IMPI_pastedBounds.R_right
		jle	testTop
		mov	ds:[bp].IMPI_pastedBounds.R_right, ax
testTop:
		mov	ax, ds:[di].P_y
		cmp	ax, ds:[bp].IMPI_pastedBounds.R_top
		jge	testBottom
		mov	ds:[bp].IMPI_pastedBounds.R_top, ax
testBottom:
		cmp	ax, ds:[bp].IMPI_pastedBounds.R_bottom
		jle	allsWell
		mov	ds:[bp].IMPI_pastedBounds.R_bottom, ax
allsWell:
		add	di, size Point
		loop	loopTop
	;
	; Add on the size of the ink stroke
	;
		pop	si
		mov	ax, ATTR_INK_STROKE_SIZE
		call	ObjVarFindData
		mov	ax, ds:[bx]
		jc	addInkSize
		call	SysGetInkWidthAndHeight

addInkSize:
		mov	bh, ah
		cbw
		add	ds:[bp].IMPI_pastedBounds.R_right, ax
		mov	al, bh
		cbw
		add	ds:[bp].IMPI_pastedBounds.R_bottom, ax 

	.leave
	ret
GetPasteSelectionBoundingBox	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkMPMetaEndSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_META_END_SELECT
PASS:		*ds:si	= InkMPClass object
		ds:di	= InkMPClass instance data
		ds:bx	= InkMPClass object (same as *ds:si)
		es 	= segment of InkMPClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	9/19/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkMPMetaEndSelect	method dynamic InkMPClass, 
					MSG_META_END_SELECT

		test	ds:[di].IMPI_flags, mask IMPF_DRAGGING
		jz	callSuper

		call	VisReleaseMouse

	;
	; If this mouse event lies outside of the ink's visual bounds,
	; then we nuke the paste.
	;
		mov	ax, MSG_INKMP_FINISH_PASTE
		call	VisTestPointInBounds
		jc	finishPaste
	;
	;  OK, we're to trash this paste.
	;
		mov	ax, MSG_INKMP_ABORT_PASTE
finishPaste:
		call	ObjCallInstanceNoLock

		mov	di, ds:[si]
		add	di, ds:[di].InkMP_offset

		mov	cx, ds:[di].IMPI_oldTool
		mov	ax, MSG_INK_SET_TOOL
		call	ObjCallInstanceNoLock

		mov	ax, mask MRF_PROCESSED
		ret
callSuper:
		andnf	ds:[di].IMPI_flags, not (mask IMPF_DRAGGING or \
						mask IMPF_HAS_PASTE_SELECTION)
		mov	di, offset InkMPClass
		GOTO	ObjCallSuperNoLock

InkMPMetaEndSelect	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IMPInkmpAbortPaste
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Removes any pasted ink that hasn't been dropped yet.

CALLED BY:	MSG_INKMP_ABORT_PASTE
PASS:		*ds:si	= InkMPClass object
		ds:di	= InkMPClass instance data
		ds:bx	= InkMPClass object (same as *ds:si)
		es 	= segment of InkMPClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	4/16/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IMPInkmpAbortPaste	method dynamic InkMPClass, 
					MSG_INKMP_ABORT_PASTE
	;
	; Only abort the paste if we were doing a paste
	;
		test	ds:[di].IMPI_flags, mask IMPF_DRAGGING or \
					mask IMPF_HAS_PASTE_SELECTION
		jz	done
	;
	; Get rid of the paste bitmap
	;
		call	EraseBitmap
		call	FreeBitmap

	;
	;  Nuke the pasted points
	;

		mov	di, si
		call	GetPointsArray
		jcxz	done
		call	ChunkArrayDeleteRange
		mov	si, di
		mov	di, ds:[si]
		add	di, ds:[di].InkMP_offset
		andnf	ds:[di].IMPI_flags, not (mask IMPF_DRAGGING or \
						mask IMPF_HAS_PASTE_SELECTION)
done:
	ret
IMPInkmpAbortPaste	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			InkMPFinishPaste
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_INKMP_FINISH_PASTE
PASS:		*ds:si	= InkMPClass object
		ds:di	= InkMPClass instance data
		ds:bx	= InkMPClass object (same as *ds:si)
		es 	= segment of InkMPClass
		ax	= message #
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	9/19/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkMPFinishPaste	method InkMPClass, MSG_INKMP_FINISH_PASTE
	uses	cx, dx, bp
	.enter

	;
	;  If we're not pasting, then screw it. If we are pasting, clear
	;  the bit and finish up.
	;
		test	ds:[di].IMPI_flags, mask IMPF_HAS_PASTE_SELECTION
		jz	done

		andnf	ds:[di].IMPI_flags, not (mask IMPF_DRAGGING or \
						mask IMPF_HAS_PASTE_SELECTION)

	;
	;  Erase the last bitmap image and free the thing
	;

		call	EraseBitmap
		call	FreeBitmap

	;
	;  Get the bounds of the paste so we can move them to align with
	;  IMPI_lastPos.
	;
		call	GetPasteSelectionBoundingBox

		mov	cx, ds:[di].IMPI_lastPos.P_x
		mov	dx, ds:[di].IMPI_lastPos.P_y
		sub	cx, ds:[di].IMPI_pastedBounds.R_left
		sub	dx, ds:[di].IMPI_pastedBounds.R_top

	;
	;  Convert to object coords
	;
		sub	cx, ds:[di].VI_bounds.R_left
		sub	dx, ds:[di].VI_bounds.R_top

	;
	;  Move the points
	;

		call	DragPasteSelection

	;
	;  Draw the thing in
	;

		mov	bp, di
		call	GetGState
		tst	di
		jz	done

		xchg	bp, di

		push	si
		call	GetPointsArray
		call	ChunkArrayElementToPtr
		segmov	es, ds
		pop	si

		clr	dx
		call	DrawMultipleLineSegments

		mov	di, bp
		call	GrDestroyState

done:
		.leave
		ret
InkMPFinishPaste	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GetPointsArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine to access ink's points array

PASS:		*ds:si	= InkMPClass object

RETURN:		ax - first point in pasted sequence
		cx - number of points in pasted sequence
		*ds:si - ChunkArray of points

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	28 dec 94	no, it didn't take the whole day.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetPointsArray	proc	near
	class	InkMPClass
	mov	si, ds:[si]
	add	si, ds:[si].InkMP_offset
	mov	cx, ds:[si].IMPI_pastedEnd
	mov	ax, ds:[si].IMPI_pastedStart
	sub	cx, ax
	mov	si, ds:[si].II_segments
	ret
GetPointsArray	endp
	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			EraseBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine to allocate a gstate and draw the paste
		bitmap into it.

PASS:		*ds:si	= InkMPClass object

RETURN:		nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	28 dec 94	initial revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EraseBitmap	proc	near
	class	InkMPClass
	uses	bp, di
	.enter

	;
	;  Allocate a GState to erase through
	;
	call	GetGState
	tst	di
	jz	done

	;
	;  boom.
	;
	mov	bp, di
	mov	ax, MSG_INKMP_DRAW_PASTE_BITMAP
	call	ObjCallInstanceNoLock

	;
	;  free the gstate
	;
	call	GrDestroyState

done:
	.leave
	ret
EraseBitmap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			FreeBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine to free the bitmap

PASS:		*ds:si	= InkMPClass object

RETURN:		nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	28 dec 94	initial revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FreeBitmap	proc	near
	class	InkMPClass
	uses	ax, bx, bp, di
	.enter

	;
	;  Free the bitmap, we're done with it.
	;

	mov	bx, ds:[si]
	add	bx, ds:[bx].InkMP_offset
	clr	ax, di
	xchg	ax, ds:[bx].IMPI_pasteBitmap
	xchg	di, ds:[bx].IMPI_pasteBitmapGState
	tst	di
	jnz	freeGState
	tst	ax
	jz	done
	call	ClipboardGetClipboardFile
	clr	bp
	call	VMFreeVMChain
done:
	.leave
	ret

freeGState:
	;
	;  The GState still exists, so we'll nuke the bitmap that way
	;

	mov	al, BMD_KILL_DATA
	call	GrDestroyBitmap
	jmp	done
FreeBitmap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				InkMPDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw handler for InkMPClass so draw the paste bitmap, if any

CALLED BY:	GLOBAL

PASS:		typical MSG_VIS_DRAW stuff
RETURN:		typical MSG_VIS_DRAW stuff

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	28 dec 94	initial revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkMPDraw	method	InkMPClass, MSG_VIS_DRAW
	.enter

	push	bp
	mov	di, offset InkMPClass
	call	ObjCallSuperNoLock
	pop	bp

	mov	ax, MSG_INKMP_DRAW_PASTE_BITMAP
	call	ObjCallInstanceNoLock

	.leave
	ret
InkMPDraw	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			InkMPSetTool
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the user changes the tool while a paste is active, then
		we drop the paste where it is and continue.
		Actually, any message which could change the ink data
		will do the same thing here.

CALLED BY:	MSG_INK_SET_TOOL,
		MSG_INK_LOAD_FROM_DB_ITEM,
		MSG_META_DELETE,
		MSG_INK_DELETE_LAST_GESTURE

PASS:		parameters to message

RETURN:		Whatever particular message returns

DESTROYED:	Whatever paticular message destroys
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/22/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkMPSetTool	method	InkMPClass,	MSG_INK_SET_TOOL,
					MSG_INK_LOAD_FROM_DB_ITEM,
					MSG_META_DELETE,
					MSG_INK_DELETE_LAST_GESTURE

	test	ds:[di].IMPI_flags, mask IMPF_HAS_PASTE_SELECTION
	jz	callSuper

	push	ax, cx, dx, bp
	pushf

	mov	ax, MSG_INKMP_FINISH_PASTE
	call	ObjCallInstanceNoLock
	
	popf
	pop	ax, cx, dx, bp

callSuper:
	mov	di, offset InkMPClass
	GOTO	ObjCallSuperNoLock
InkMPSetTool	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkMPRelocOrUnReloc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clears out instance data that is no longer valid

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/ 1/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkMPRelocOrUnReloc	method	InkMPClass, reloc
	.enter

;	Don't do this on VMRT_RELOCATE_AFTER_WRITE, as we were
;	guaranteed to have just done a VMRT_UNRELOCATE_BEFORE_WRITE
;
;	Don't do this on VMRT_RELOCATE_FROM_RESOURCE, as we *assume*
;	that the data is set up correctly straight from the resource...
;
;	Theoretically, we don't even need to do it on VMRT_RELOCATE_AFTER_READ,
;	but just to be safe...

	cmp	dx, VMRT_RELOCATE_AFTER_READ
	je	doClr
	cmp	dx, VMRT_UNRELOCATE_FROM_RESOURCE
	je	doClr
	cmp	dx, VMRT_UNRELOCATE_BEFORE_WRITE
	jne	callSuper
doClr:
	;
	; If we're unrelocating while we have a selection,
	; deallocate the bitmap
	;
	; It looks like this happens automatically, so we won't do this.
	;
		call	FreeBitmap

;	Nuke any current selection, and nuke the flags that say we have the
;	target/mouse grab/are selecting

	clr	ds:[di].IMPI_pasteBitmapGState
	andnf	ds:[di].IMPI_flags, not (mask IMPF_DRAGGING or \
						mask IMPF_HAS_PASTE_SELECTION)

callSuper:
	mov	di, offset InkMPClass
	call	ObjRelocOrUnRelocSuper
	.leave
	ret
InkMPRelocOrUnReloc	endp

InkMPCode	ends		;end of CommonCode resource

