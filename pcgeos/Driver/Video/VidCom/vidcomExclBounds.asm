COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Video Drivers
FILE:		vidcomExclBounds.asm

AUTHOR:		Jim DeFrisco, Nov 24, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	11/24/92	Initial revision


DESCRIPTION:
	These functions calculate the bounds of the operation and stuff 
	the result in some variables for later use.
		

	$Id: vidcomExclBounds.asm,v 1.1 97/04/18 11:41:55 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VidSegment	Exclusive


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidExclBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	High level routine called from DriverStrategy

CALLED BY:	INTERNAL
		DriverStrategy
PASS:		di	- function number
		ds	- video driver dgroup
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	11/25/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VidExclBounds		proc	far
		call	cs:[exclusiveBounds][di]	; save bounds
		ret
VidExclBounds		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExclNoBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do nothing, operation doesn't require any bounds checking

CALLED BY:	INTERNAL
		DriverStrategy
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	11/24/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExclNoBounds	proc	near
		ret
ExclNoBounds	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExclRectBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Incorporate RectBounds into results

CALLED BY:	INTERNAL
		DriverStrategy
PASS:		ax...dx		- rect bounds, sorted
		es		- Window structure
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	11/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExclRectBounds	proc	near
		uses	ax, bx, cx, dx
		.enter
if	ERROR_CHECK
		cmp	ax, cx
		ERROR_G	UNSORTED_BOUNDS
		cmp	bx, dx
		ERROR_G	UNSORTED_BOUNDS
endif
		; limit bounds to maskRect

		cmp	ax, es:[W_maskRect].R_left	; limit to mask rect
		jge	haveLeft
		mov	ax, es:[W_maskRect].R_left
haveLeft:
		cmp	bx, es:[W_maskRect].R_top	; limit to mask rect
		jge	haveTop
		mov	bx, es:[W_maskRect].R_top
haveTop:
		cmp	cx, es:[W_maskRect].R_right	; limit to mask rect
		jle	haveRight
		mov	cx, es:[W_maskRect].R_right
haveRight:
		cmp	dx, es:[W_maskRect].R_bottom	; limit to mask rect
		jle	haveBottom
		mov	dx, es:[W_maskRect].R_bottom
haveBottom:
		; If we're completely out of the mask rect, we'll just
		; get out without modifying exclBound.  -cbh 4/19/93

		cmp	ax, cx
		jg	done
		cmp	bx, dx
		jg	done

		; have limited coords, check bounds

		cmp	ax, ds:[exclBound].R_left	; see if new minimum
		jg	checkTop
		mov	ds:[exclBound].R_left, ax
checkTop:
		cmp	bx, ds:[exclBound].R_top	; see if new minimum
		jg	checkRight
		mov	ds:[exclBound].R_top, bx
checkRight:
		cmp	cx, ds:[exclBound].R_right	; see if new maximum
		jl	checkBottom
		mov	ds:[exclBound].R_right, cx
checkBottom:
		cmp	dx, ds:[exclBound].R_bottom	; see if new minimum
		jl	done
		mov	ds:[exclBound].R_bottom, dx
done:
if	ERROR_CHECK
		;
		; we could never have set exclBounds if we're completely
		; out of the mask rect - brianc 5/2/95
		;
		mov	ax, MAX_COORD
		cmp	ax, ds:[exclBound].R_left
		jne	checkIt
		cmp	ax, ds:[exclBound].R_top
		jne	checkIt
		mov	ax, MIN_COORD
		cmp	ax, ds:[exclBound].R_right
		jne	checkIt
		cmp	ax, ds:[exclBound].R_bottom
		je	noCheck
checkIt:
		mov	ax, ds:[exclBound].R_left
		cmp	ax, ds:[exclBound].R_right
		ERROR_G	UNSORTED_BOUNDS
		mov	ax, ds:[exclBound].R_top
		cmp	ax, ds:[exclBound].R_bottom
		ERROR_G	UNSORTED_BOUNDS
noCheck:
endif
		.leave
		ret
ExclRectBounds	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExclLineBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Same as RectBounds, but coords are not yet sorted

CALLED BY:	INTERNAL
		DriverStrategy
PASS:		ax...dx		- line endpoints
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	11/24/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExclLineBounds		proc	near
		uses	ax,bx,cx,dx
		.enter

		cmp	ax, cx
		jl	xOK
		xchg	ax, cx
xOK:
		cmp	bx, dx
		jl	yOK
		xchg	bx, dx
yOK:
		call	ExclRectBounds
		.leave
		ret
ExclLineBounds		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExclStringBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine bounds of PutString operation

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	11/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExclStringBounds		proc	near
		uses	ax,bx,cx,dx
		.enter

		; if there is rotation in the window, then invalidate the
		; whole mask rect

		mov	cx, es:[W_curTMatrix].TM_12.WWF_int ; check for rot
		or	cx, es:[W_curTMatrix].TM_12.WWF_frac
		jnz	doRotation

		; no rotation.  Just invalidate from the draw position
		; to the right side of the maskRect

		mov	dx, es:[W_maskRect].R_bottom	; this is eash

		; if there is a negative scale factor, load the left bounds 
		; and swap left/right

		tst	es:[W_curTMatrix].TM_11.WWF_int	; see if flipped in X
		js	handleScale
		mov	cx, es:[W_maskRect].R_right	; to save time
doBounds:
		call	ExclLineBounds

		.leave
		ret

		; negative X scale factor -- use left bound
handleScale:
		mov	cx, es:[W_maskRect].R_left
		jmp	doBounds


		; there is rotation.  handle it.
doRotation:
		mov	ax, es:[W_maskRect].R_left
		mov	bx, es:[W_maskRect].R_left
		mov	cx, es:[W_maskRect].R_left
		mov	dx, es:[W_maskRect].R_left
		jmp	doBounds	
ExclStringBounds		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExclBltBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find bounds of blt operation

CALLED BY:	INTERNAL
		DriverStrategy
PASS:		ax,bx	- source position
		cx,dx	- dest position
		si,bp	- width,height
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	11/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExclBltBounds		proc	near
		uses	ax,bx,cx,dx
		.enter

		cmp	ax, cx
		jl	xOK
		xchg	ax, cx
xOK:
		cmp	bx, dx
		jl	yOK
		xchg	bx, dx
yOK:

		; add in width/height to right/bottom

		add	cx, si
		add	dx, bp
		call	ExclRectBounds
		
		.leave
		ret
ExclBltBounds		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExclBitmapBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find bounds of bitmap operation

CALLED BY:	INTERNAL
		DriverStrategy
PASS:		ax,bx	- position to draw
		es	- Window
		ss:bp	- pointer to PutBitsArgs struct
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	11/24/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExclBitmapBounds	proc	near
		uses	cx,dx, bp
		.enter
		mov	cx, ss:[bp][-size PutBitsArgs].PBA_bm.B_width
		add	cx, ax
		mov	dx, ss:[bp].[-size PutBitsArgs].PBA_bm.B_height
		add	dx, bx
		call	ExclLineBounds

		.leave
		ret
ExclBitmapBounds	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExclRegionBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get bounds of a region

CALLED BY:	INTERNAL
		DriverStrategy
PASS:		ax	- amt to offset region in x to get screen crds
		bx	- amt to offset region in y to get screen crds
		dx.cx	- segment/offset to region definition
		ss:bp	- pointer to region parameters
			  ss:bp+0 - PARAM_0
			  ss:bp+2 - PARAM_1
			  ss:bp+4 - PARAM_2
			  ss:bp+6 - PARAM_3
		si	- offset in gstate to CommonAttr struct
		ds	- gstate
		es	- window
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	11/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExclRegionBounds		proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter

		push	ds			; save pointer to dgroup
		push	bx			; save offsets for later
		push	ax
		push	bp			; save param ptr
		mov	bp, ds			; save GState
		mov	ds, dx			; ds -> Region
		mov	di, cx			;ds:di = bounds
		mov	ax, ds:[di].R_left
		mov	bx, ds:[di].R_top
		mov	cx, ds:[di].R_right
		mov	dx, ds:[di].R_bottom
		mov	ds, bp			;ds = GState
		pop	di			; di = region param ptr

		test 	ah, 0xc0
		jpe	doTop
		call	GetRegCoord
doTop:
		test	bh, 0xc0
		jpe	doRight
		xchg	ax, bx
		call	GetRegCoord
		xchg	ax, bx
doRight:
		test	ch, 0xc0
		jpe	doBottom
		xchg	ax, cx
		call	GetRegCoord
		xchg	ax, cx
doBottom:
		test	dh, 0xc0
		jpe	doneTrans
		xchg	ax, dx
		call	GetRegCoord
		xchg	ax, dx
doneTrans:
		pop	di			; recover x offset
		add	ax,di
		add	cx,di
		pop	di			; recover y offset
		add	bx,di
		add	dx,di
		pop	ds			; restore pointer to dgroup
		call	ExclLineBounds		; just to make sure

		.leave
		ret
ExclRegionBounds		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetRegCoord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy of TransRegCoord, for this function

CALLED BY:	INTERNAL
		ExclRegionBounds
PASS:		ax	- coord to translate
RETURN:		ax	- translated coord
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	11/24/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetRegCoord	proc	near
	uses	cx, di
	.enter
	mov	ch, ah
	mov	cl, 4
	shr	ch, cl
	mov	cl, ch
	and	cx, 1110b		;bl = 4, 6, 8, a for AX, BX, CX, DX
	add	di, cx
	and	ah, 00011111b		;mask off top three
	sub	ax, 1000h		;make +/-
	add	ax, ss:[di][-4]
	.leave
	ret
GetRegCoord	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExclPolygonBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get bounds of polygon operation

CALLED BY:	INTERNAL
		DriverStrategy
PASS:		bx:dx	- ptr to coord buffer
		cx	- #points in buffer
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	11/24/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExclPolygonBounds	proc	near
		uses	ax,bx,cx,dx,si,di
		.enter
	
		push	ds
		mov	ds, bx
		mov	si, dx		; ds:si -> coords
	;
	; Initialize ax, cx to X coordinate of first point, and bx, dx
	; to Y coordinate of first point.  Can't just use MAX_COORD
	; and MIN_COORD because a set of points where the X (or Y) 
	; coordinates are monotonically decreasing will leave cx (or dx)
	; at MIN_COORD, resulting in UNSORTED_BOUNDS death in 
	; ExclRectBounds. (6/22/95 -- jwu)
	;
		lodsw	
		mov	di, ax
		mov	bx, ds:[si]
		mov	dx, bx
		jmp	nextPoint
coordLoop:
		cmp	ax, ds:[si]	; new min ?
		jle	checkRight
		mov	ax, ds:[si]
		jmp	doneX
checkRight:
		cmp	di, ds:[si]
		jge	doneX
		mov	di, ds:[si]
doneX:
		add	si, 2
		cmp	bx, ds:[si]	; do Y
		jle	checkBottom
		mov	bx, ds:[si]
		jmp	nextPoint
checkBottom:
		cmp	dx, ds:[si]
		jge	nextPoint
		mov	dx, ds:[si]
nextPoint:		
		add	si, 2
		loop	coordLoop

		mov	cx, di		; copy right side over
		pop	ds		; restore ptr to dgroup
		call	ExclRectBounds

		.leave
		ret
ExclPolygonBounds	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExclPolylineBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get bounds of polyline operation

CALLED BY:	INTERNAL
		DriverStrategy
PASS:		bx:si	- pointer to disjoint polyline buffer
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	11/24/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExclPolylineBounds	proc	near
		uses	ax,bx,cx,dx,si
		.enter

		push	ds
		mov	ds, bx		; ds:si -> coords

	;
	; Initialize ax, cx to X coordinate of first point, and bx, dx
	; to Y coordinate of first point.  Can't just use MAX_COORD
	; and MIN_COORD because a set of points where the X (or Y) 
	; coordinates are monotonically decreasing will leave cx (or dx)
	; at MIN_COORD, resulting in UNSORTED_BOUNDS death in 
	; ExclRectBounds. (6/22/95 -- jwu)
	;
		lodsw
		mov	cx, ax
		mov	bx, ds:[si]
		mov	dx, bx
		add	si, 2
coordLoop:
		cmp	ds:[si], 8000h	; check for end
		je	checkEnd
		cmp	ax, ds:[si]	; new min ?
		jle	checkRight
		mov	ax, ds:[si]
		jmp	doneX
checkRight:
		cmp	cx, ds:[si]
		jge	doneX
		mov	cx, ds:[si]
doneX:
		add	si, size sword
		cmp	bx, ds:[si]	; do Y
		jle	checkBottom
		mov	bx, ds:[si]
		jmp	nextPoint
checkBottom:
		cmp	dx, ds:[si]
		jge	nextPoint
		mov	dx, ds:[si]
nextPoint:		
		add	si, size sword
		jmp	coordLoop
doBounds:
		pop	ds			; restore pointer to dgroup
		call	ExclRectBounds

		.leave
		ret

checkEnd:
		cmp	ds:[si+2], 8000h 
		je	doBounds
		jmp	nextPoint
ExclPolylineBounds	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExclDashBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get bounds of DashLine function

CALLED BY:	INTERNAL
		DriverStrategy
PASS:		bx:dx	- pointer to DashInfo structure
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	11/24/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExclDashBounds	proc	near
		uses	bx, dx, si
		.enter

		push	ds
		mov	si, dx
		mov	ds, bx
		mov	ax, ds:[si].DI_pt1.P_x
		mov	bx, ds:[si].DI_pt1.P_y
		mov	cx, ds:[si].DI_pt2.P_x
		mov	dx, ds:[si].DI_pt2.P_y
		pop	ds
		call	ExclLineBounds
		
		.leave
		ret
ExclDashBounds	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExclFatDashBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Same as ExclDashBounds, except handles fat lines

CALLED BY:	INTERNAL
		DriverStrategy
PASS:		bx:dx	- DashInfo struct
		ax	- x displacement to other side
		cx	- y displacement to other side
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	11/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExclFatDashBounds proc	near
		uses	si,di,ax,bx,cx,dx
		.enter

		push	ds
		mov	si, dx
		mov	ds, bx
		push	ax, cx
		mov	ax, ds:[si].DI_pt1.P_x
		mov	bx, ds:[si].DI_pt1.P_y
		mov	cx, ds:[si].DI_pt2.P_x
		mov	dx, ds:[si].DI_pt2.P_y
		pop	si, di

		cmp	ax, cx
		jle	xOK
		xchg	ax, cx
xOK:
		cmp	bx, dx
		jle	yOK
		xchg	bx, dx
yOK:

		tst	si
		js	negXOffset
addXOffset:
		sub	ax, si
		add	cx, si

		tst	di
		js	negYOffset
addYOffset:
		sub	bx, di
		add	dx, di

		pop	ds
		call	ExclRectBounds

		.leave
		ret

negXOffset:
		neg	si
		jmp	addXOffset

negYOffset:
		neg	di
		jmp	addYOffset
ExclFatDashBounds endp


	; table of routines to keep track of the bounds of operations that
	; were aborted due to an exclusive holding.
exclusiveBounds	label	word
	dw	offset ExclNoBounds		; initialization
	dw	offset ExclNoBounds		; last gasp
	dw	offset ExclNoBounds	; suspend system
	dw	offset ExclNoBounds	; unsuspend system
	dw	offset ExclNoBounds	; test for device existance
	dw	offset ExclNoBounds	; set device type
	dw	offset ExclNoBounds	; get ptr to info block
	dw	offset ExclNoBounds	; get exclusive
	dw	offset ExclNoBounds	; start exclusive
	dw	offset ExclNoBounds	; end exclusive

	dw	offset ExclNoBounds	; get pixel color
	dw	offset ExclNoBounds	; GetBits in another module
	dw	offset ExclNoBounds	; set the ptr pic
	dw	offset ExclNoBounds	; hide the cursor
	dw	offset ExclNoBounds	; show the cursor
	dw	offset ExclNoBounds	; move the cursor
	dw	offset ExclNoBounds	; set save under area
	dw	offset ExclNoBounds	; restore save under area
	dw	offset ExclNoBounds	; nuke save under area
	dw	offset ExclNoBounds	; request save under
	dw	offset ExclNoBounds	; check save under
	dw	offset ExclNoBounds	; get save under info
	dw	offset ExclNoBounds	; check s.u. collision
	dw	offset ExclNoBounds	; set xor region
	dw	offset ExclNoBounds	; clear xor region

	dw	offset ExclRectBounds	; rectangle
	dw	offset ExclStringBounds	; char string
	dw	offset ExclBltBounds	; BitBlt in another module
	dw	offset ExclBitmapBounds	; PutBits in another module
	dw	offset ExclLineBounds	; DrawLine in another module
	dw	offset ExclRegionBounds	; draws a region
	dw	offset ExclLineBounds	; PutLine in another module
	dw	offset ExclPolygonBounds	; Polygon in another module
	dw	offset ExclNoBounds	; ScreenOn in another module
	dw	offset ExclNoBounds	; ScreenOff in another module
	dw	offset ExclPolylineBounds ; Polyline in another module
	dw	offset ExclDashBounds	; DashLine in another module
	dw	offset ExclFatDashBounds	; DashFill in another module
	dw	offset ExclNoBounds	; SetPalette 
	dw	offset ExclNoBounds	; GetPalette 

.assert ($-exclusiveBounds) eq VidFunction

VidEnds	Exclusive
