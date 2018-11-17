COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		inkBackspace.asm

AUTHOR:		Steve Kertes, May  2, 1994

ROUTINES:
	Name			Description
	----			-----------
FaxviewInkDeleteLastGesture	deletes the last gesture of ink made
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SK	5/ 2/94   	Initial revision


DESCRIPTION:
	temp file holding the backspace ink code until I can install it into
	the real library
		

	$Id: inkBackspace.asm,v 1.1 97/04/05 01:27:50 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InkEdit	segment	resource

INK_ERROR_INK_ELEMENTS_NOT_FIXED_SIZE	enum	FatalErrors
; It is assumed that the elements of the chunk array are of a fixed size, but
; they are not.
;


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkDeleteLastGesture
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	deletes the last gesuture in the ink

CALLED BY:	MSG_INK_DELETE_LAST_GESTURE
PASS:		*ds:si	= InkClass object
		ds:di	= InkClass instance data
		ds:bx	= InkClass object (same as *ds:si)
		es 	= segment of InkClass
		ax	= message #
RETURN:		ax = 0 if gesture not deleted (no points)
DESTROYED:	cx, dx, bp
SIDE EFFECTS:	an ink gesture is deleted

PSEUDO CODE/STRATEGY:
		count back to the beginning of the last gesture, collecting
		bounds info

		when the end of the second to last gesture is found delete
		the range

		invalidate the region bounded by the max/min points in the ink

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SK	4/15/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkDeleteLastGesture	method dynamic InkClass, 
					MSG_INK_DELETE_LAST_GESTURE
	ourHandle	local	lptr	push si
	inkPointSize	local	word			; size of ink elements
	inkPointsLeft	local	word

	.enter
		;*ds:si is object
		call	NukeSelection

		mov	si, ds:[di].II_segments		; *ds:si <- chunk array
		clr	ax				; return 0 if no points
		tst	si
		LONG jz	done				; no points
	;
	; get the number of points in the ink
	;		
		;*ds:si is chunk array
		call	ChunkArrayGetCount		; cx <- count
		clr	ax				; return 0 if no points
		tst	cx
		LONG jz	done				; no points	
		mov	inkPointsLeft, cx
	;
	; get the size of elements
	;
		mov	di, ds:[si]			; deref
		mov	ax, ds:[di].CAH_elementSize
		tst	ax
NEC <		jz	done						>
EC <		ERROR_Z INK_ERROR_INK_ELEMENTS_NOT_FIXED_SIZE		>
		mov	inkPointSize, ax
	;
	; last element
	;
		mov	ax, cx				; number of points
		dec	ax				; last element
		call	ChunkArrayElementToPtr		; ds:di <- element ptr
	;
	; in the loop:
	;		ax = min x value
	;		bx = min y value
	;		cx = max x value
	;		dx = max y value
	;
	;		ss:bp = stack frame
	;		*ds:si = chunk array
	;		ds:di  = ptr to current element
	;

	;
	; initilize boundries to the last point (the one at ds:di)
	;
		mov	bx, ds:[di].P_y			; top and bottom
		mov	dx, bx
		mov	ax, ds:[di].P_x			; left and right
		and	ax, 0x7FFF			; don't use high bit
		mov	cx, ax

countPointsLoop:		
	;
	; get the next element
	;
		sub	di, inkPointSize		; move back one element
		dec	inkPointsLeft
		jz	foundBeginnning
	;
	; see if this is the end of a new gesture
	;
		test	ds:[di].P_x, 0x8000		; is high bit set?
		jnz	foundBeginnning
	;
	; update all the bounds
	;
		cmp	ax, ds:[di].P_x			; left edge
		jb	gotMinX
		mov	ax, ds:[di].P_x
gotMinX:
		cmp	cx, ds:[di].P_x			; right edge
		ja	gotMaxX
		mov	cx, ds:[di].P_x
gotMaxX:
		cmp	bx, ds:[di].P_y			; top edge
		jb	gotMinY
		mov	bx, ds:[di].P_y
gotMinY:
		cmp	dx, ds:[di].P_y			; bottom edge
		ja	gotMaxY
		mov	dx, ds:[di].P_y
gotMaxY:
		
		jmp	countPointsLoop
; end countPointsLoop

foundBeginnning:
	;
	; while we have the bounds in the registers, create the undo action
	;
		push	bp, si				; save locals, array
		mov	di, inkPointsLeft		; get local now

		mov	si, ourHandle
		;*ds:si is ink object
		call	CheckForUndo			; 0 set if no undo
		jz	noUndo

		mov	bp, offset DeleteUndoString	;BP <- undo title
		;*ds:si is ink object
		call	StartUndoChain

		mov_tr	bp, di				; inkPointsLeft
		;ax, bx, cx, dx are bounds
		;*ds:si is ink object
		call	GenerateNumStrokesAction

		mov	bp, offset DeleteUndoString	;BP <- undo title
		;*ds:si is ink object
		call	EndUndoChain

noUndo:
		pop	bp, si				; restore locals, array
	;
	; inkPointsLeft is the element number of the first point in the
	; last gesture, delete from it to the end of the array
	;
		push	ax, cx				; save bounds

		mov	ax, inkPointsLeft		; first element to nuke
		mov	cx, -1				; delete to end
		;*ds:si is array
		call	ChunkArrayDeleteRange

		pop	ax, cx				; restore bounds
	;
	; now invalidate the region we so carefully found
	;
		mov	si, ourHandle
		push	bp

		sub	sp, size VisAddRectParams
		mov	bp, sp
	;
	; expand the bounds by the width and height of the ink so that
	; everything on the screen gets cleared, otherwise little bits
	; stick around.
	;
		mov	ss:[bp].VARP_bounds.R_left, ax	; ax trashed soon

		;*ds:si is ink object
		call	GetStrokeWidthAndHeight		; al/ah <- width/height

		shl	al
		shl	ah

		sub	bl, ah
		sbb	bh, 0 
		add	dl, ah
		adc	dh, 0

		clr	ah				; now ax is width
		add	cx, ax

	;
	; fill in the bounds and invalidate the region
	;
		sub	ss:[bp].VARP_bounds.R_left, ax
		mov	ss:[bp].VARP_bounds.R_top, bx
		mov	ss:[bp].VARP_bounds.R_right, cx
		mov	ss:[bp].VARP_bounds.R_bottom, dx
		clr	ss:[bp].VARP_flags
		mov	dx, size VisAddRectParams
		mov	ax, MSG_VIS_ADD_RECT_TO_UPDATE_REGION ;ax,cx,dx,bp gone
		call	ObjCallInstanceNoLock

		add	sp, size VisAddRectParams

		call	MarkInkDirty

		pop	bp
	;
	; set ax to non 0 since ink was deleted
	;
		mov	ax, TRUE
done:
	.leave
	ret
InkDeleteLastGesture	endm


InkEdit	ends
