COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	Pen library
MODULE:		Ink
FILE:		inkSelection.asm

AUTHOR:		Andrew Wilson, Sep  3, 1992

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/ 3/92		Initial revision

DESCRIPTION:
	This file contains all the routines needed to implement ink selection.

	$Id: inkSelection.asm,v 1.1 97/04/05 01:27:48 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkCommon	segment	resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetMaskPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns a near ptr to the indexed mask

CALLED BY:	GLOBAL
PASS:		ax - index of mask
		carry set if we are doing the bottom/left borders
RETURN:		ax - offset to mask
DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetMaskPtr	proc	near
	.enter
EC <	pushf								>
EC <	cmp	ax, NUM_ANT_MASKS					>
EC <	ERROR_AE	-1						>
EC <	popf								>



	jc	bottomRight
	add	ax, offset AntMasksTopLeft
exit:
	.leave
	ret

bottomRight:

;	The ant masks go in the other direction when drawing from the bottom
;	right...

	neg	ax
	add	ax, offset AntMasksTopLeft + NUM_ANT_MASKS + 1
	jmp	exit

GetMaskPtr	endp

AntMasksTopLeft	byte	11100001b,	
			11000011b,	
			10000111b,	
			00001111b,	
			00011110b,	
			00111100b,	
			01111000b,	
			11110000b,	
			11100001b,
			11000011b,
			10000111b,
			00001111b,
			00011110b,
			00111100b,
			01111000b,
			11110000b,
			11100001b
 
NUM_ANT_MASKS	equ	8



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetAntLineMask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the line mask appropriate to the current ant position.

CALLED BY:	GLOBAL
PASS:		*ds:si - ink object
		di - gstate handle
		carry set if we are doing the bottom/left borders, which use
			a different mask set
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetAntLineMask	proc	near	uses	ax, si, ds
	class	InkClass
	.enter
	pushf	
	mov	si, ds:[si]
	add	si, ds:[si].Ink_offset
	mov	al, ds:[si].II_antMask
	clr	ah
	popf
	call	GetMaskPtr
	mov_tr	si, ax			;ds:si <- ptr to mask	
	segmov	ds, cs	
	mov	al, SDM_CUSTOM shl offset SDM_MASK
	call	GrSetLineMask
	.leave
	ret
SetAntLineMask	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetMaskForAntUpdate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates/sets a draw mask for the passed items

CALLED BY:	GLOBAL
PASS:		di - gstate
		*ds:si - ink object (containing new II_antMask)
		bp - index of old mask
		carry set if we are doing the bottom/left borders, which use
			a different mask set
RETURN:		nada
DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetMaskForAntUpdate	proc	near
	class	InkClass


;	We want to convert from a drawing using the passed mask to a drawing
;	using the next mask - we get the passed mask, XOR it with the new mask,
;	and then draw with that mask - this will cause the screen to be updated
;	correctly.

;	We must call GetMaskPtr *before* the .enter, as the .enter will
;	trash the carry

	push	ax, bx, ds, si
	mov	ax, bp			;AX <- index of ant mask to use
	pushf				;Save passed-in carry flag
	call	GetMaskPtr


	mov_tr	bx, ax			;CS:BX <- old DrawMask

	mov	si, ds:[si]
	add	si, ds:[si].Ink_offset
	mov	al, ds:[si].II_antMask
	clr	ah	
	popf				;Restore passed-in carry flag
	call	GetMaskPtr
	mov_tr	si, ax			;CS:SI <- new DrawMask

	localMask	local	DrawMask
	.enter

;	We have the old draw mask and the new draw mask - XOR them both
;	together to create a new draw mask that, when drawn through, will
;	create an image that looks just as if we erased with the old mask and
;	redrew with the new mask.

CheckHack	<size DrawMask eq 8>

	mov	ax, cs:[bx] 
	xor	ax, cs:[si]
	mov	{word} localMask, ax
	mov	ax, cs:[bx][2]
	xor	ax, cs:[si][2]
	mov	{word} localMask+2, ax
	mov	ax, cs:[bx][4]
	xor	ax, cs:[si][4]
	mov	{word} localMask+4, ax
	mov	ax, cs:[bx][6]
	xor	ax, cs:[si][6]
	mov	{word} localMask+6, ax

	segmov	ds, ss
	lea	si, localMask			;DS:SI <- mask
	mov	al, SDM_CUSTOM shl offset SDM_MASK
	call	GrSetLineMask

	.leave
	pop	ax, bx, ds, si
	ret
SetMaskForAntUpdate	endp
					



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetAndCheckForSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the current selection and checks if valid

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		ax, bx, cx, dx - selection bounds (sorted)
		carry set if selection
DESTROYED:	
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetAndCheckForSelection	proc	near	uses	si
	class	InkClass
	.enter

EC <	call	ECCheckIfInkObject					>
	mov	si, ds:[si]
	add	si, ds:[si].Ink_offset
	mov	ax, ds:[si].II_selectBounds.R_left
	mov	bx, ds:[si].II_selectBounds.R_top
	mov	cx, ds:[si].II_selectBounds.R_right
	mov	dx, ds:[si].II_selectBounds.R_bottom
	or	ax, bx
	or	ax, cx
	or	ax, dx		;Clears carry
	jz	exit		;Exit with carry clear if no selection
	mov	ax, ds:[si].II_selectBounds.R_left

	; Sort the bounds

	cmp	ax, cx
	jbe	10$
	xchg	ax, cx
10$:
	
	cmp	bx, dx
	jbe	20$
	xchg	bx, dx
20$:
	stc
exit:
	.leave
	ret
GetAndCheckForSelection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertBoundsToWindowCoords
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Converts the passed bounds from being relative to the origin
		of the ink object to being relative to the origin of the
		parent window.

CALLED BY:	GLOBAL
PASS:		*ds:si - Ink object
		ax, bx, cx, dx - bounds
RETURN:		ax, bx, cx, dx - updated
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/ 1/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertBoundsToWindowCoords	proc	near	uses	di
	class	VisClass
	.enter

EC <	call	ECCheckIfInkObject					>
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	add	ax, ds:[di].VI_bounds.R_left
	add	cx, ds:[di].VI_bounds.R_left
	add	bx, ds:[di].VI_bounds.R_top
	add	dx, ds:[di].VI_bounds.R_top
	.leave
	ret
ConvertBoundsToWindowCoords	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RedrawSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Redraws the selected area. This either draws a new selected
		area, or erases the old one.

CALLED BY:	GLOBAL
PASS:		*ds:si - object
		di - gstate to draw through (or 0 if you want to create one)
RETURN:		carry set if there was a selection
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RedrawSelection	proc	far	uses	ax, bx, cx, dx, di
	class	InkClass
	.enter
EC <	call	ECCheckIfInkObject					>

;	If we aren't drawable, don't do anything

	push	di
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_attrs, mask VA_DRAWABLE
	pop	di
	jz	exit


;	Get the bounds. If the bounds are 0,0,0,0 this means that there is
;	no selection, so don't draw anything.

	call	GetAndCheckForSelection		;Exit if no selection
	jnc	exit

;	Convert the bounds of the selection to window coords.

	call	ConvertBoundsToWindowCoords
	dec	cx
	dec	dx
	cmp	ax, cx
	jg	stcExit	
	

	tst	di
	jnz	notCached
	mov	di, ds:[si]
	add	di, ds:[di].Ink_offset
	mov	di, ds:[di].II_cachedGState

	call	DrawMarquee

stcExit:
	stc
exit:
	.leave
	ret

notCached:

;	Set the draw mode and mask appropriately (the cached gstate already
;	has this set up).

	call	GrSaveState
	push	ax, dx

	clrdw	dxax
	call	GrSetLineWidth

	mov	al, MM_INVERT
	call	GrSetMixMode

	pop	ax, dx

	call	SetAntLineMask

	call	DrawMarquee
	call	GrRestoreState
	jmp	stcExit

DrawMarquee:

;	To achieve a true "marquee" appearance, we set a different mask for
;	the bottom/right lines.

	clc				;Set mask for Top/Right lines
	call	SetAntLineMask
	call	DrawTopRightLine

	stc				;
	call	SetAntLineMask		;Set mask for Bottom/Left lines
	call	DrawBotLeftLine
	retn
	
RedrawSelection	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawTopRightLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the top and right line of the marquee.

CALLED BY:	GLOBAL
PASS:		di - gstate with appropriate mask
		ax, bx, cx, dx - gstate
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/ 3/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawTopRightLine	proc	near	uses	bx, dx
;		uses	ax, bx, dx
	.enter
if 0
draw:
	call	GrDrawHLine
	inc	bx
	inc	ax
	cmp	bx, dx
	ja	exit
	cmp	ax, cx
	jb	draw
exit:
endif

	call	GrDrawHLine
	xchg	ax, cx

;	Tweak the endpoints of the right edge of the marquee so they won't
;	overlap the top and bottom.

	dec	dx
	inc	bx
	cmp	bx, dx
	jg	noDraw
	call	GrDrawVLine
noDraw:
	xchg	ax, cx
	.leave
	ret
DrawTopRightLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawBotLeftLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the bottom and left line of the marquee.

CALLED BY:	GLOBAL
PASS:		di - gstate with appropriate mask
		ax, bx, cx, dx - gstate
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/ 3/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawBotLeftLine	proc	near	uses	bx, dx
	.enter
if 0

	inc	bx
draw:
	call	GrDrawVLine
	inc	bx
	inc	ax
	cmp	ax, cx
	jg	exit
	cmp	bx, dx
	jl	draw
exit:
endif
;	Tweak the endpoints of the right edge of the marquee so they won't
;	overlap the top and bottom.

	push	dx
	inc	bx
	dec	dx
	cmp	bx, dx
	jg	noDraw
	call	GrDrawVLine
noDraw:
	pop	bx			;BX <- bottom edge
	call	GrDrawHLine
	.leave
	ret
DrawBotLeftLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NukeSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Erases the current selection, if there is one.

CALLED BY:	GLOBAL
PASS:		*ds:si - object
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NukeSelection	proc	far	uses	di
	class	InkClass
	.enter
EC <	call	ECCheckIfInkObject					>

	mov	di, ds:[si]
	add	di, ds:[di].Ink_offset
	andnf	ds:[di].II_flags, not mask IF_SELECTING
	clr	di
	call	RedrawSelection		;Erase the selection, if one exists
	jnc	exit

;	Nuke the selection, and destroy the cached gstate.

	call	StopAntTimer
	push	si
	mov	si, ds:[si]
	add	si, ds:[si].Ink_offset
	xchg	di, ds:[si].II_cachedGState
	tst	di
	jz	noGState
	call	GrDestroyState
noGState:
	clr	ds:[si].II_selectBounds.R_left
	clr	ds:[si].II_selectBounds.R_right
	clr	ds:[si].II_selectBounds.R_top
	clr	ds:[si].II_selectBounds.R_bottom
	pop	si
	push	ax, bx, cx, dx, bp
	call	UpdateEditControlStatus
	pop	ax, bx, cx, dx, bp
exit:
	.leave
	ret
NukeSelection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrabMouse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This grabs the mouse and the gadget exclusive.

CALLED BY:	GLOBAL
PASS:		*ds:si - object
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrabMouse	proc	near	uses	ax, cx, dx, bp
	class	InkClass
	.enter
	mov	bp, ds:[si]
	add	bp, ds:[bp].Ink_offset
	test	ds:[bp].II_flags, mask IF_HAS_MOUSE_GRAB
	jnz	exit
	ornf	ds:[bp].II_flags, mask IF_HAS_MOUSE_GRAB

	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	ax, MSG_VIS_TAKE_GADGET_EXCL
	call	VisCallParent
	call	VisGrabMouse
exit:
	.leave
	ret
GrabMouse	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReleaseMouse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Releases the mouse

CALLED BY:	GLOBAL
PASS:		*ds:si - object
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReleaseMouse	proc	near	uses	ax, cx, dx, bp
	.enter
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	ax, MSG_VIS_RELEASE_GADGET_EXCL
	call	VisCallParent
	.leave
	ret
ReleaseMouse	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkLostGadgetExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This method is called when we lose the gadget excl. We want
		to give up the mouse in this case.

CALLED BY:	GLOBAL
PASS:		*ds:si - object
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkLostGadgetExcl	method	InkClass, MSG_VIS_LOST_GADGET_EXCL


	call	VisReleaseMouse

	mov	di, ds:[si]
	add	di, ds:[di].Ink_offset
	andnf	ds:[di].II_flags, not (mask IF_HAS_MOUSE_GRAB)

	mov	di, offset InkClass
	GOTO	ObjCallSuperNoLock
InkLostGadgetExcl	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StopAntTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Nukes the ant timer.

CALLED BY:	GLOBAL
PASS:		*ds:si - ink object
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StopAntTimer	proc	near		uses	ax, bx, di
	class	InkClass
	.enter
EC <	call	ECCheckIfInkObject					>
	mov	di, ds:[si]
	add	di, ds:[di].Ink_offset
	clr	bx
	xchg	bx, ds:[di].II_antTimer	;If no ant timer, just exit
	tst	bx
	jz	exit
	mov	ax, ds:[di].II_antTimerID
	call	TimerStop
exit:
	.leave
	ret
StopAntTimer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartAntTimerIfNotAlreadyStarted
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates a new timer for updating the marching ants selection,
		if one does not already exist.

CALLED BY:	GLOBAL
PASS:		*ds:si - ink object
RETURN:		nada
DESTROYED:	ax, bx, cx, dx, di
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StartAntTimerIfNotAlreadyStarted	proc	near
	class	InkClass
	.enter
EC <	call	ECCheckIfInkObject					>
	mov	di, ds:[si]			;If there is already a timer
	add	di, ds:[di].Ink_offset		; running (from a previous
	tst	ds:[di].II_antTimer		; selection, for example, 
	jnz	exit				; don't create a new one)

	call	StartAntTimer

exit:
	.leave
	ret
StartAntTimerIfNotAlreadyStarted	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartAntTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Starts the ant one-shot timer up

CALLED BY:	GLOBAL
PASS:		*ds:si - Ink object
RETURN:		nada
DESTROYED:	ax, bx, cx, dx, di
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/12/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StartAntTimer	proc	near
	class	InkClass	
EC <	call	ECCheckIfInkObject					>
	mov	ax, TIMER_EVENT_ONE_SHOT
	mov	cx, TICKS_BETWEEN_ANT_UPDATES
	mov	dx, MSG_INK_ADVANCE_SELECTION_ANTS
	mov	bx, ds:[LMBH_handle]
	call	TimerStart

	mov	di, ds:[si]
	add	di, ds:[di].Ink_offset
	mov	ds:[di].II_antTimer, bx
	mov	ds:[di].II_antTimerID, ax
	ret
StartAntTimer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertPointToObjectCoordinates
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Converts a point to be relative to the upper edge of the
		object, instead of the window

CALLED BY:	GLOBAL
PASS:		cx, dx - point
		*ds:si - Ink object
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/ 1/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertPointToObjectCoordinates	proc	near
	class	VisClass
	.enter
EC <	call	ECCheckIfInkObject					>
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	sub	cx, ds:[di].VI_bounds.R_left
	sub	dx, ds:[di].VI_bounds.R_top
	.leave
	ret
ConvertPointToObjectCoordinates	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This method handler is called when the user presses the
		mouse over our object.

CALLED BY:	GLOBAL
PASS:		cx, dx - position of start select
RETURN:		nada
DESTROYED:	ax, cx, dx, bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/ 3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkStartSelect	method	dynamic InkClass, MSG_META_START_SELECT
	.enter

	call	ConvertPointToObjectCoordinates
	call	GrabTarget
	mov	di, ds:[si]
	add	di, ds:[di].Ink_offset
	mov	ax, mask MRF_PROCESSED or mask MRF_CLEAR_POINTER_IMAGE
	cmp	ds:[di].II_tool, IT_SELECTOR
	jne	exit
	tst	ds:[di].II_cachedGState
	jnz	noCreate

;	Create a cached GState to draw through

	call	GetGState
	mov	bp, di
	mov	di, ds:[si]
	add	di, ds:[di].Ink_offset
	mov	ds:[di].II_cachedGState, bp
	mov	di, bp				;DI <- gstate to draw through

	push	dx
	clrdw	dxax
	call	GrSetLineWidth
	pop	dx

	mov	al, MM_INVERT
	call	GrSetMixMode

noCreate:
	
;	If there is a selection already, erase it.

	clr	di
	call	RedrawSelection

	mov	bx, ds:[si]
	add	bx, ds:[bx].Ink_offset
	ornf	ds:[bx].II_flags, mask IF_SELECTING
	mov	ds:[bx].II_selectBounds.R_left, cx
	mov	ds:[bx].II_selectBounds.R_right, cx
	mov	ds:[bx].II_selectBounds.R_top, dx
	mov	ds:[bx].II_selectBounds.R_bottom, dx

;	Take the gadget exclusive and the mouse grab. We will give up the
;	mouse grab when we lose the gadget exclusive.

	call	GrabMouse

;	Draw the new selection

	call	RedrawSelection

;	Start a timer to do the marching ants update

	call	StartAntTimerIfNotAlreadyStarted

	mov	ax, mask MRF_PROCESSED or mask MRF_SET_POINTER_IMAGE
	mov	cx, handle SelectCursor
	mov	dx, offset SelectCursor
exit:
	.leave
	ret
InkStartSelect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnsureSelectionInBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the passed point is not in bounds, massages it until it is

CALLED BY:	GLOBAL
PASS:		cx, dx - point in window coordinates
		*ds:si - vis object
RETURN:		cx, dx - massaged point
DESTROYED:	bx
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnsureSelectionInBounds	proc	near
	class	InkClass
	.enter
	mov	bx, ds:[si]
	add	bx, ds:[bx].Vis_offset
	cmp	cx, ds:[bx].VI_bounds.R_left
	jge	10$
	mov	cx, ds:[bx].VI_bounds.R_left
10$:
	cmp	cx, ds:[bx].VI_bounds.R_right
	jle	20$
	mov	cx, ds:[bx].VI_bounds.R_right
20$:
	cmp	dx, ds:[bx].VI_bounds.R_top
	jge	30$
	mov	dx, ds:[bx].VI_bounds.R_top
30$:
	cmp	dx, ds:[bx].VI_bounds.R_bottom
	jle	40$
	mov	dx, ds:[bx].VI_bounds.R_bottom
40$:
	.leave
	ret
EnsureSelectionInBounds	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the current selection is different from the old selection,
		we redraw/update it.

CALLED BY:	GLOBAL
PASS:		cx, dx - coord
		*ds:si - object
RETURN:		nothing
DESTROYED:	bx, cx, dx, di
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateSelection	proc	near
	class	InkClass
	.enter
	call	EnsureSelectionInBounds

	call	ConvertPointToObjectCoordinates

;	If the new coord is the same as the old coord, don't redraw anything

	mov	bx, ds:[si]
	add	bx, ds:[bx].Ink_offset
	cmp	ds:[bx].II_selectBounds.R_right, cx
	jne	doUpdate
	cmp	ds:[bx].II_selectBounds.R_bottom, dx
	je	exit

doUpdate:
	clr	di
	call	RedrawSelection			;Erase the old selection
	mov	bx, ds:[si]
	add	bx, ds:[bx].Ink_offset
	mov	ds:[bx].II_selectBounds.R_right, cx
	mov	ds:[bx].II_selectBounds.R_bottom, dx
	call	RedrawSelection
exit:
	.leave
	ret
UpdateSelection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is called when the user moves the mouse over the ink
		object. If we are selecting, we update the selection.
		

CALLED BY:	GLOBAL
PASS:		cx, dx - position
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/ 3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkPtr	method	dynamic InkClass, MSG_META_PTR
	.enter

	test	ds:[di].II_flags, mask IF_SELECTING
	jne	handleSelection

	mov	ax, mask MRF_PROCESSED or mask MRF_CLEAR_POINTER_IMAGE
	cmp	ds:[di].II_tool, IT_SELECTOR
	jne	exit

;	If the ptr event was outside of our bounds, release the mouse and clear
;	out the pointer image. Otherwise, grab the mouse and set the pointer
;	image.

	test	bp, mask UIFA_IN shl 8
	jnz	doGrab
	call	ReleaseMouse
	jmp	exit
 
doGrab:
	call	GrabMouse
setCursor:
	mov	ax, mask MRF_PROCESSED or mask MRF_SET_POINTER_IMAGE
	mov	cx, handle SelectCursor
	mov	dx, offset SelectCursor
exit:
	.leave
	ret

handleSelection:

;	If we are currently selecting, redraw the selection and update our
;	internal stuff.

	call	UpdateSelection
	jmp	setCursor
InkPtr	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkEndSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This method handler completes the selection.

CALLED BY:	GLOBAL
PASS:		*ds:si - object
		cx, dx - coord of end select
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkEndSelect	method	InkClass, MSG_META_END_SELECT
	.enter
	test	ds:[di].II_flags, mask IF_SELECTING
	je	notSelecting

	call	UpdateSelection

	mov	di, ds:[si]
	add	di, ds:[di].Ink_offset
	andnf	ds:[di].II_flags, not mask IF_SELECTING

;	Sort the bounds

	mov	ax, ds:[di].II_selectBounds.R_left
	cmp	ax, ds:[di].II_selectBounds.R_right
	jb	10$
	xchg	ax, ds:[di].II_selectBounds.R_right
	mov	ds:[di].II_selectBounds.R_left, ax
10$:
	mov	ax, ds:[di].II_selectBounds.R_top
	cmp	ax, ds:[di].II_selectBounds.R_bottom
	jb	update
	xchg	ax, ds:[di].II_selectBounds.R_bottom
	mov	ds:[di].II_selectBounds.R_top, ax
update:
	call	UpdateEditControlStatus	
notSelecting:

;	Now, we need to do resolve things with the mouse:
;
;	We need to release the mouse and clear the ptr image if:
;
;	1) The current tool is not the selector
;	2) The release was outside the bounds of the object
;


	test	bp, mask UIFA_IN shl 8	;If the release was outside the bounds
	jz	releaseMouse		; of the mouse, branch

	mov	ax, mask MRF_PROCESSED
	mov	di, ds:[si]
	add	di, ds:[di].Ink_offset
	cmp	ds:[di].II_tool, IT_SELECTOR
	jz	exit
releaseMouse:
	call	ReleaseMouse
	mov	ax, mask MRF_PROCESSED or mask MRF_CLEAR_POINTER_IMAGE
exit:
	.leave
	ret
InkEndSelect	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkAdvanceSelectionAnts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Advances the selected area (moves the "ants" forward a notch).

CALLED BY:	GLOBAL
PASS:		*ds:si, ds:di - ink object
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkAdvanceSelectionAnts	method	dynamic InkClass,
					MSG_INK_ADVANCE_SELECTION_ANTS	
	.enter
	tst	ds:[di].II_antTimer		;If the timer has been stopped,
	jz	exit				; just get out.

	cmp	bp, ds:[di].II_antTimerID
	jnz	exit

	test	ds:[di].VI_attrs, mask VA_DRAWABLE
	jz	exit

;	Get the selection - if there is a selection, create a draw mask that
;	will cause the "ants" to advance, and draw it

	clr	ds:[di].II_antTimer
	call	GetAndCheckForSelection		;Exit if no selection
	jnc	exit

;	Convert the bounds of the selection to window coords.

	call	ConvertBoundsToWindowCoords
	dec	cx		;Move the right and bottom bounds in one
	dec	dx		; pixel, to stay in the bounds of the object
	cmp	ax, cx
	jg	noDraw

	push	ax
	mov	al, ds:[di].II_antMask
	dec	ds:[di].II_antMask
	jns	draw
	mov	ds:[di].II_antMask, NUM_ANT_MASKS-1
draw:
	clr	ah
	mov	bp, ax				;BP <- ant mask index
	mov	di, ds:[di].II_cachedGState
	pop	ax


;	Set the mask approriate for the top/right lines, draw them, set the
;	mask for the bottom/left lines, and draw them too.

	clc
	call	SetMaskForAntUpdate
	call	DrawTopRightLine

	stc
	call	SetMaskForAntUpdate	
	call	DrawBotLeftLine
noDraw:
;
;	Start the ant timer again
;
	call	StartAntTimer
exit:
	.leave
	ret
InkAdvanceSelectionAnts	endp

InkCommon	ends
