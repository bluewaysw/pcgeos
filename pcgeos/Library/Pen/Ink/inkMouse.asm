COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	Pen
MODULE:		Ink
FILE:		inkMouse.asm

AUTHOR:		Andrew Wilson, Feb 18, 1992

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/18/92		Initial revision

DESCRIPTION:
	This file contains routines to implement the mouse-input
	ink stuff.	

	$Id: inkMouse.asm,v 1.1 97/04/05 01:27:51 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkEnsureMouseGrab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ensures that the passed ink object has the mouse grab and
		gadget exclusive.

CALLED BY:	GLOBAL
PASS:		ds:di - ptr to ink object instance data
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkEnsureMouseGrab	proc	near
	class	InkClass
	test	ds:[di].II_flags, mask IF_GRABBED
	jnz	exit		;if mouse already grabbed, branch
	call	VisTakeGadgetExclAndGrab
	mov	di, ds:[si]
	add	di, ds:[di].Ink_offset
	ornf	ds:[di].II_flags, mask IF_GRABBED
exit:
	ret
InkEnsureMouseGrab	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Method sent out when user clicks in the ink object.

CALLED BY:	GLOBAL
PASS:		BP - ButtonInfo
		CX - x coord of mouse
		DX - y coord of mouse
RETURN:		nada
DESTROYED:	bx
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/14/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkStartSelect	method	dynamic InkClass, MSG_META_START_SELECT
	mov	ax, mask MRF_CLEAR_POINTER_IMAGE or mask MRF_PROCESSED
	test	bp, (mask UIFA_IN) shl 8	;ignore if not in bounds
	jz	exit
	call	InkEnsureMouseGrab
	ornf	ds:[di].II_flags, mask IF_SELECTING
	mov	ds:[di].II_oldPoint.P_x, cx		;Save coord of mouse
	mov	ds:[di].II_oldPoint.P_y, dx

;	Create a GSTATE to cache and draw through. It will be destroyed in
;	the MSG_META_END_SELECT handler.

	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	call	VisCallParent

	mov	di, ds:[si]
	add	di, ds:[di].Ink_offset
	clr	ah			;Set the pen color
	mov	al, ds:[di].II_penColor
	mov	di, bp
	call	GrSetLineColor

;	Set the area draw color to white, for Erasing

	mov	ax, CF_INDEX shl 8 or C_WHITE
	call	GrSetAreaColor

;	Set the clip region to be the object's bounds

	call	SetClipRectToVisBounds

;	Save the gstate in the instance data, and draw a "dot" in the current
;	position (just as one would expect if you were using a real pencil)
;

	mov	di, ds:[si]
	add	di, ds:[di].Ink_offset
	mov	ds:[di].II_gstate, bp
	mov	cx, ds:[di].II_oldPoint.P_x
	mov	dx, ds:[di].II_oldPoint.P_y
	cmp	ds:[di].II_tool, IT_ERASER
	je	erase

	call	GetNumPoints
	cmp	ax, MAX_INK_POINTS
	ja	setExit

	ornf	ds:[di].II_flags, mask IF_CONTINUE_LINE_SEGMENT
	call	DrawCurrentLineSegment	;Draw just a single point
	call	AddCoord
setExit:
	call	GetCursorOptr
	mov	ax, mask MRF_PROCESSED or mask MRF_SET_POINTER_IMAGE
exit:
	ret
erase:
	call	DoErase
	jmp	setExit
InkStartSelect	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetCursorOptr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the cursor for the current tool

CALLED BY:	GLOBAL
PASS:		ds:di - ptr to ink object instance data
RETURN:		^lcx:dx - cursor image
DESTROYED:	di
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetCursorOptr	proc	near
	class	InkClass
	mov	cx, handle Cursors
	mov	di, ds:[di].II_tool
EC <	cmp	di, InkTool						>
EC <	ERROR_AE	BAD_TOOL					>
	mov	dx, cs:[cursorTable][di]
	ret
GetCursorOptr	endp

cursorTable	lptr	pencilCursor
		lptr	eraserCursor

	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawCurrentLineSegment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws a line segment from the old x/y coord to the current
		one.

CALLED BY:	GLOBAL
PASS:		ds:di - ptr to Ink object instance data
		cx:dx - current coord
RETURN:		nada
DESTROYED:	ax
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/15/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawCurrentLineSegment	proc	near	uses	di, si, cx
	.enter
	class	InkClass
	mov	ds:[di].II_curPoint.P_x, cx
	mov	ds:[di].II_curPoint.P_y, dx
	lea	si, ds:[di].II_oldPoint		;DS:SI <- point array
	mov	cx, 2
	mov	ax, PENCIL_WIDTH_AND_HEIGHT
	mov	di, ds:[di].II_gstate
	call	GrBrushPolyline
	.leave
	ret
DrawCurrentLineSegment	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkReleaseGadgetExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Releases the current gadget exclusive (assuming we have it)

CALLED BY:	GLOBAL
PASS:		ds:di - ptr to ink instance data
RETURN:		ds:di - ptr to ink instance data
DESTROYED:	ax, cx, dx, bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkReleaseGadgetExcl	proc	near
	class	InkClass

	mov	ax, MSG_VIS_RELEASE_GADGET_EXCL
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	call	VisCallParent
	mov	di, ds:[si]
	add	di, ds:[di].Ink_offset
	ret
InkReleaseGadgetExcl	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is the method sent out with pointer events.

CALLED BY:	GLOBAL
PASS:		bp - ButtonInfo
		cx, dx - mouse offset
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/15/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkPtr	method	dynamic InkClass, MSG_META_PTR
	test	ds:[di].II_flags, mask IF_SELECTING
	jne	selecting
			;If not currently selecting, then:
			;If mouse is in bounds, grab it and change the
			; mouse ptr
			;If mouse is out of bounds, release it and restore
			; the mouse ptr

	test	bp, (mask UIFA_IN) shl 8
	jne	inBounds

;	Release the gadget exclusive, clear the pointer image, and replay
;	the mouse event

	call	InkReleaseGadgetExcl

	mov	ax, mask MRF_REPLAY or mask MRF_CLEAR_POINTER_IMAGE
	jmp	exit
inBounds:

;	Grab the mouse, and set the pointer image

	call	InkEnsureMouseGrab
	call	GetCursorOptr
	mov	ax, mask MRF_PROCESSED or mask MRF_SET_POINTER_IMAGE
	jmp	exit

selecting:
	
	cmp	cx, ds:[di].II_oldPoint.P_x
	jne	10$
	cmp	dx, ds:[di].II_oldPoint.P_y
	je	selectedExit
10$:

;	If the mouse is no longer in the bounds of the object, then terminate
;	the current line segment (if any).

	test	bp, (mask UIFA_IN) shl 8
	je	outOfBounds

;	If we are starting a new line segment, then draw a point here
;	Else, draw a line from the old X coord.
;
	cmp	ds:[di].II_tool, IT_ERASER
	je	erase

	call	GetNumPoints
	cmp	ax, MAX_INK_POINTS
	ja	selectedExit

	test	ds:[di].II_flags, mask IF_CONTINUE_LINE_SEGMENT
	jne	20$
	mov	ds:[di].II_oldPoint.P_x, cx
	mov	ds:[di].II_oldPoint.P_y, dx
	call	DrawCurrentLineSegment
	ornf	ds:[di].II_flags, mask IF_CONTINUE_LINE_SEGMENT
	jmp	30$	
20$:
	call	DrawCurrentLineSegment
30$:

	call	AddCoord
	mov	ds:[di].II_oldPoint.P_x, cx
	mov	ds:[di].II_oldPoint.P_y, dx
selectedExit:
	mov	ax, mask MRF_PROCESSED
exit:
	ret
erase:
	call	DoErase
	jmp	selectedExit

outOfBounds:

;	This event is not in the bounds of the object, so...
;	If a line segment is currently being created, then terminate it.

	test	ds:[di].II_flags, mask IF_CONTINUE_LINE_SEGMENT
	je	exit
	andnf	ds:[di].II_flags, not mask IF_CONTINUE_LINE_SEGMENT
	call	TerminateSegment
	jmp	selectedExit

InkPtr	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DestroyCachedGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroys any cached gstate for the passed ink object

CALLED BY:	GLOBAL
PASS:		*ds:si - ptr to ink object
RETURN:		ds:di - ptr to ink object instance data
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/28/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DestroyCachedGState	proc	near
	class	InkClass
	mov	di, ds:[si]						
	add	di, ds:[di].Ink_offset
	push	di							
   	mov	di, ds:[di].II_gstate
	tst	di
	jz	exit
	call	GrDestroyState
exit:
	pop	di							
	clr	ds:[di].II_gstate					
	ret
DestroyCachedGState	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkEndSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Method sent out when the user releases the mouse button

CALLED BY:	GLOBAL
PASS:		cx, dx - x,y coord of release
		bp - ButtonInfo
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/14/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkEndSelect	method	dynamic InkClass, MSG_META_END_SELECT
	cmp	ds:[di].II_tool, IT_ERASER
	je	erase
	call	GetNumPoints
	cmp	ax, MAX_INK_POINTS
	ja	noAdd

	test	ds:[di].II_flags, mask IF_CONTINUE_LINE_SEGMENT
	jz	ignoreCoordinate
	test	bp, (mask UIFA_IN) shl 8
	jz	noAdd
	call	DrawCurrentLineSegment
	cmp	ds:[di].II_oldPoint.P_x, cx
	jne	addCoord
	cmp	ds:[di].II_oldPoint.P_y, dx
	je	noAdd
addCoord:
	call	AddCoord
noAdd:

;	Terminate the current drawing, release the mouse, and destroy
;	our cached gstate.

	call	TerminateSegment
ignoreCoordinate:
	call	DestroyCachedGState

	mov	ax, mask MRF_PROCESSED
	test	bp, (mask UIFA_IN) shl 8	
	jnz	stillIn
	call	InkReleaseGadgetExcl
	mov	ax, mask MRF_CLEAR_POINTER_IMAGE or mask MRF_PROCESSED
stillIn:
	andnf	ds:[di].II_flags, not (mask IF_CONTINUE_LINE_SEGMENT or mask IF_SELECTING)
	ret
erase:
	test	bp, (mask UIFA_IN) shl 8	;If not in bounds, no erasing!
	jz	ignoreCoordinate
	call	DoErase
	jmp	ignoreCoordinate
InkEndSelect	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkLostGadgetExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	When we lose the gadget exclusive, we need to release the
		mouse grab.

CALLED BY:	GLOBAL
PASS:		ds:di - ink object
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkLostGadgetExcl	method	dynamic InkClass, MSG_VIS_LOST_GADGET_EXCL
EC <	test	ds:[di].II_flags, mask IF_GRABBED			>
EC <	ERROR_Z	INK_OBJECT_DOES_NOT_HAVE_GADGET_EXCLUSIVE		>
	andnf	ds:[di].II_flags, not mask IF_GRABBED

	test	ds:[di].II_flags, mask IF_CONTINUE_LINE_SEGMENT
	jz	10$
	call	TerminateSegment
10$:
	call	DestroyCachedGState
	call	VisReleaseMouse
	ret
InkLostGadgetExcl	endp

endif
