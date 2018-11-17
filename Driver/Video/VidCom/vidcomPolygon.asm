
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Video Drivers
FILE:		vidcomPolygon.asm

AUTHOR:		Jim DeFrisco, 7/31/90

ROUTINES:
	Name			Description
	----			-----------
    GLB VidPolygon		Draw a convex polygon
    INT FillPolygonRight	Scan the right edge of the polygon, filling
				as we go
    INT FillRightDDA		Fill in the scan lines
    INT ScanPolygonLeft		Scan left edge of polygon, storing coords
    INT ScanLeftDDA		Record the left edge points
    INT GetPolygonBounds	Calc the bounds of a Polygon from a list of
				points
    GLB VidDashFill		Draw a fat dashed line

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	7/30/90		Initial revision


DESCRIPTION:
	This file contains the code to draw a convex polygon
		
	$Id: vidcomPolygon.asm,v 1.1 97/04/18 11:41:52 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


MEM  <VidSegment Line	>
NMEM <VidSegment Polygon>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidPolygon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a convex polygon

CALLED BY:	GLOBAL
		DriverStrategy

PASS:		ds	- locked gstate
		es	- locked owned window
		bx:dx	- fptr to polygon coord block
		cx	- #points in buffer
		si	- offset to attributes to use in gstate
		al	- flag (0=always draw, 1=draw only if coords are given
			  in clockwise order)

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Scan convert the polygon
		Calculate the bounds, to pass to RectSetup;
		Get the max y coord, start there;
		Check flag for quick exit;
		Scan along left side of polygon, storing coords;
		Scan along right side, filling as we go;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	11/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VidPolygon	proc	far
		
		; store away some interesting info

		cmp	cx, 3
		jb	done				; skip if not enuf pts
		mov	ss:[polyCount], cx		; save #points
		mov	ss:[polyFlag], al		; save arguments
		mov	ss:[polyAttr], si		; save arguments
		mov	ss:[polyPoints].offset, dx	; save fptr
		mov	ss:[polyPoints].segment, bx
		mov	ss:[saveDS], ds			; save gstate segment
		mov	ds, bx				; bx:dx -> point buffer
		mov	si, dx				; ds:si -> points

		; get bounds for the entire polygon

		call	GetPolygonBounds		; ax...dx = bounds
		jc	done				; don't draw if ccw
		mov	si, ss:[polyAttr]		; need attr for setup
		mov	ds, ss:[saveDS]			; restore GState
		call	RectSetupFar			; si = routine to call
		pop	es				; pushed by RectSetup
		pop	ds
		jc	done				; totally clipped

MEM <		; the clip line buffer is trashed in vidmem		>
MEM <		andnf	es:[W_grFlags], not mask WGF_BUFFER_VALID	>

		call	ScanPolygonLeft			; scan left side
		jc	done				; totally clipped
		call	FillPolygonRight		; scan/fill to right 

		; all done with drawing, exit
done:
NMEM <	cmp	ss:[xorHiddenFlag],0	;check for ptr hidden.		>
NMEM <	jz	noRedrawXOR		;go and redraw it if it was hidden.>
NMEM <	call	ShowXORFar						>
NMEM <noRedrawXOR:							>

NMEM <		cmp	ss:[hiddenFlag],0				>
NMEM <		jz	VDL_redrawn					>
NMEM <		call	CondShowPtrFar					>
NMEM <VDL_redrawn:							>
		.leave
		ret

VidPolygon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillPolygonRight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scan the right edge of the polygon, filling as we go

CALLED BY:	VidPolygon

PASS:		variable setup in dgroup by VidPolygon

RETURN:		nothing

DESTROYED:	everything

PSEUDO CODE/STRATEGY:
		scan right edge, call FillRect for the approp scan lines

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	11/19/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FillPolygonRight proc	near
MEM <		uses	es						>
		.enter
		
		; initialize some things

		mov	di, si				; di = rect routine
		mov	ds, ss:[polyPoints].segment	; get pointer to points
		mov	si, ss:[polyMax]		; get offset to max
MEM <		mov	es, ss:[bm_segment]		; get ptr to bitmap >
		mov	bx, ss:[polyMaxY]		; get bottom coord
		lodsw					; get first point
		mov	ss:[lineX2], ax			;  as X2 to start off
		lodsw
		mov	ss:[lineY2], ax
		jmp	nextLine
		
		; for each line in the edge, fill in the appropriate scan lines
loadNextLine:
		lodsw					; load x coord
		xchg	ax, ss:[lineX2]			; make old X2 new X1, 
		mov	ss:[lineX1], ax
		lodsw
		xchg	ax, ss:[lineY2]			; save with y coord
		mov	ss:[lineY1], ax
		cmp	ax, ss:[lineY2]			; skip horiz lines
		je	nextLine

		clr	al				; dont skip anything
		mov	dx, cs
		mov	cx, offset FillRightDDA		; dx:cx -> callback 
		call	VidLineDDA

		; only do the left edge until we hit the minimum
nextLine:
		tst	ss:[polyFlag]			; check counterclock
		jnz	clockwise
		sub	si, 2*(size Point)		; back up to prev point
		cmp	si, ss:[polyPoints].offset	; if first, set to last
		jge	haveNextPtr
		mov	si, ss:[polyLast]
haveNextPtr:
		mov	ax, ss:[lineY2]			; going downhill
		cmp	ax, ss:[polyMinY]		; are we done ?
		jg	loadNextLine			;  no, continue

		.leave
		ret

clockwise:
		cmp	si, ss:[polyLast]		; see if past end
		jle	haveNextPtr
		mov	si, ss:[polyPoints].offset
		jmp	haveNextPtr
FillPolygonRight endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillRightDDA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill in the scan lines

CALLED BY:	VidLineDDA

PASS:		ax...dx		- Rect coords for line segment
		di		- routine to call in dgroup

RETURN:		nothing

DESTROYED:	ax..dx

PSEUDO CODE/STRATEGY:
		use the info in the polyEdge buffer to fill in scan lines

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	11/20/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FillRightDDA	proc	far
		uses	es, ds, si, di
		.enter

		; make sure we're on-screen.

		tst	dx			; if bottom is off the top...
		LONG js	done			;  ..don't draw
		tst	bx			;  ..else force top on top
		jns	topOK
		clr	bx
topOK:
		mov	si, cx			; save si = right coord
ifdef	MULT_RESOLUTIONS
NMEM <		mov	cx, ss:[DriverTable].VDI_pageH			>
NMEM <		dec	cx						>
else
NMEM <		mov	cx, SCREEN_HEIGHT-1				>
endif
MEM  <		mov	ds, ss:[bm_segment]	; ds -> bitmap		>
MEM  <		mov	cx, ds:[EB_bm].CB_simple.B_height		>
MEM  <		dec	cx						>
		cmp	bx, cx			; see if it's on screen
		ja	done
		cmp	dx, cx			; force bottom to on-screen at
		jbe	bottomOK		;   bottom
		mov	dx, cx
bottomOK:
		mov	cx, dx			; calc #scan lines to do
		segmov	ds, es, dx		; ds -> window
		SetBuffer es, dx		; es -> frame buffer
		xchg	ax, di			; ax = routine, di = left side
		sub	cx, bx			; cx = #scans to do (not last)
		inc	cx			; #scans passed to this routine
		mov	di, si			; si = left side, di = right
		dec	di			; don't draw rightmost pixel

		; we need to fill in (possibly) multiple scan lines.  We'd like
		; to find all the biggest rectangles, so that we can do those
		; with one call.  What we have is a polyEdge buffer, with one
		; word per scan line, filled with the left side x value for 
		; that scan line (actually, it may be the right side, but we'll
		; handle that later).  The passed info represents one section
		; (either vertical or horizontal) for the right edge of the
		; convex polygon.  So, the passed info is a straight line, and
		; the buffer info may or may not be a straight line.  To start
		; do it the easy way and see how fast it is.
fillLoop:
		shl	bx, 1			; access left-side buffer
		mov	si, di			; set buffer to curr right
NMEM <		xchg	si, cs:[polyEdge][bx]	; load left coordinate	>
MEM  <		mov	es, ss:[bm_segment]	; reload point buf segment >
MEM  <		xchg	si, es:[VIDMEM_POINT_BUF][bx]			>
		shr	bx, 1
		cmp	si, di			; make sure it's sorted
		jg	skipDraw
		cmp	bx, ss:[polyMaxY]	; don't draw last scan line
		jge	skipDraw
		push	ax, bx, cx, di		; save coords, count, rout
		mov	bp, 1

		call	DrawRectFront		; fill this section
		pop	ax, bx, cx, di		; restore coords, count, rout
skipDraw:
		inc	bx			; onto next scan
		loop	fillLoop
done:
		.leave
		ret

FillRightDDA	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScanPolygonLeft
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scan left edge of polygon, storing coords

CALLED BY:	VidPolygon

PASS:		values setup in VidPolygon (in dgroup vars)

RETURN:		carry	- don't continue drawing.

DESTROYED:	everything

PSEUDO CODE/STRATEGY:
		starting from the bottom of the polygon, scan the left side
		storing the coords in an internal buffer

		Use the VidLineDDA function to compute the points along the
		edge

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:p
	Name	Date		Description
	----	----		-----------
	jim	11/19/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScanPolygonLeft	proc	near
		uses	si
		.enter
		
		; init point buffer to something big

		push	es, di
MEM  <		mov	es, ss:[bm_segment]	; es -> HugeArray dir block >
NMEM <		segmov	es, cs, ax					>
		mov	ax, MAX_COORD		; use a big one
		mov	cx, ss:[polyMaxY]	; get max Y value
MEM <		mov	di, es:[EB_bm].CB_simple.B_height ; limit to dev size>
MEM <		dec	di						>
ifdef	MULT_RESOLUTIONS
NMEM <		mov	di, ss:[DriverTable].VDI_pageH			>
NMEM <		dec	di						>
else
NMEM <		mov	di, SCREEN_HEIGHT-1	; limit to device size  >
endif
		cmp	cx, di			; if larger, clip it.
		jbe	checkMin
		mov	cx, di
checkMin:
		mov	di, ss:[polyMinY]	;  and minimum
		tst	di			; can't be negative
		jns	calcNumScans
		clr	di
calcNumScans:
		sub	cx, di			; cx = #scan lines -1
		js	bailQuick		; don't draw negative #scans
		inc	cx
		shl	di, 1			; offset into buffer
MEM  <		add	di, VIDMEM_POINT_BUF	; es:di -> left side buffer >
NMEM <		add	di, offset polyEdge	; es:di -> edge buffer	 >
		rep	stosw
		pop	es, di

		; initialize some things

		mov	ds, ss:[polyPoints].segment	; get pointer to points
		mov	si, ss:[polyMax]		; get offset to max
		lodsw					; get first point
		mov	ss:[lineX2], ax			;  as X2 to start off
		lodsw
		mov	ss:[lineY2], ax
		jmp	nextLine
		
		; nothing to draw.  Return.
bailQuick:
		pop	es, di			; restore the stack
		stc	
		jmp	done

		; for each line in the edge, add the points into the buffer
loadNextLine:
		lodsw					; load x coord
		xchg	ax, ss:[lineX2]			; make old X2 new X1, 
		mov	ss:[lineX1], ax
		lodsw
		xchg	ax, ss:[lineY2]			; save with y coord
		mov	ss:[lineY1], ax
		cmp	ax, ss:[lineY2]			; see if horizontal
		je	nextLine

		clr	al				; dont skip anything
		mov	dx, cs
		mov	cx, offset ScanLeftDDA		; dx:cx -> callback 
		call	VidLineDDA

		; only do the left edge until we hit the minimum
nextLine:
		tst	ss:[polyFlag]			; if other way, handle
		jnz	cclockwise			;  if counterclock...
		cmp	si, ss:[polyLast]		; if last, set to first
		jle	haveNextPtr
		mov	si, ss:[polyPoints].offset	
haveNextPtr:
		mov	ax, ss:[lineY2]			; going downhill
		cmp	ax, ss:[polyMinY]		; are we done ?
		jg	loadNextLine			;  no, continue
		clc
done:
		.leave
		ret

		; if counter clockwise, load coords other way
cclockwise:
		sub	si, 2*(size Point)		; back up 
		cmp	si, ss:[polyPoints].offset	;  but not too far
		jge	haveNextPtr
		mov	si, ss:[polyLast]
		jmp	haveNextPtr
ScanPolygonLeft	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScanLeftDDA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record the left edge points

CALLED BY:	VidLineDDA	

PASS:		ax...dx		- Rect coords for this segment

RETURN:		nothing

DESTROYED:	ax...dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	11/19/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScanLeftDDA	proc	far
		uses	es, di
		.enter

		; make sure we're on-screen.

		tst	dx			; if bottom is off the top...
		js	done			;  ..don't draw
		tst	bx			;  ..else force top on top
		jns	topOK
		clr	bx
topOK:
ifdef	MULT_RESOLUTIONS
NMEM <		mov	cx, ss:[DriverTable].VDI_pageH			>
NMEM <		dec	cx						>
else
NMEM <		mov	cx, SCREEN_HEIGHT-1				>
endif
MEM  <		mov	es, ss:[bm_segment]	; es -> HugeArray dir block >
MEM  <		mov	cx, es:[EB_bm].CB_simple.B_height	>
MEM  <		dec	cx						>
		cmp	bx, cx			; see if it's on screen
		ja	done
		cmp	dx, cx			; force bottom to on-screen at
		jbe	bottomOK		;   bottom
		mov	dx, cx
bottomOK:
		mov	cx, dx
		sub	cx, bx			; cx = #scans - 1
		inc	cx			; cx = #scans to fill
NMEM <		segmov	es, cs, dx		; es -> scan line buffer >
NMEM <		mov	di, offset polyEdge	; es:di -> edge buffer	 >
MEM  <		mov	di, VIDMEM_POINT_BUF	; add offset to buffer	>
		shl	bx, 1			; top coordinate
		add	di, bx			; es:di -> into edge buffer
storeLoop:
		cmp	ax, es:[di]
		jge	nextStore
		mov	es:[di], ax		; store it
nextStore:
		add	di, 2
		loop	storeLoop
done:
		.leave
		ret
ScanLeftDDA	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetPolygonBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calc the bounds of a Polygon from a list of points

CALLED BY:	VidPolygon

PASS:		ds:si		- point list
		cx		- #points
		al		- clockwise flag (see VidPolygon, above)

RETURN:		ax..dx		- Rect bounds
		carry		- set if we shouldn't draw it due to ordering
				  of points and passed clockwise flag
		ss:[polyMax]	- buffer offset to max y position
		ss:[polyMaxY]	- max y position

DESTROYED:	everything

PSEUDO CODE/STRATEGY:
		scan the points, keep track of the right things

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	11/19/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetPolygonBounds proc	near
		.enter

		; just loop through all the points.  Use the first set of 
		; points as initializers.
		; bx = miny,  dx = maxy, di = minx,  bp = maxx

		push	si, cx
		mov	ss:[polyMax], si		; init bottom pointer
		mov	ax, ds:[si].P_x			; get x value at that
		mov	ss:[polyMaxYxval], ax		;  point
		mov	ss:[polyMin], si		; init top pointer
		lodsw
		mov	di, ax
		mov	bp, ax
		lodsw
		mov	bx, ax
		mov	dx, ax
		dec	cx
		jcxz	doneList
pointLoop:
		lodsw					; get next x coord
		cmp	ax, di				; check minX
		jge	checkMaxX
		mov	di, ax
		jmp	loadY
checkMaxX:
		cmp	ax, bp				; check maxX
		jle	loadY
		mov	bp, ax
loadY:
		lodsw
		cmp	ax, bx				; check minY
		jge	checkMaxY
		mov	bx, ax
		sub	si, 4				; backup to start of pt
		mov	ss:[polyMin], si
		add	si, 4				; restore pointer
		jmp	nextPoint
checkMaxY:
		cmp	ax, dx				; check maxY
		jl	nextPoint
		je	checkNewMax			; if not definite, chk
		mov	dx, ax
reallyNewMax:
		sub	si, 4				; backup to start of pt
		mov	ss:[polyMax], si
		lodsw					; load X val for Y max
		mov	ss:[polyMaxYxval], ax		; ...and store it
		add	si, 2				; restore pointer
nextPoint:
		loop	pointLoop
doneList:
		mov	cx, bp
		mov	ss:[polyMaxY], dx		; store bottom point
		mov	ss:[polyMinY], bx		; store top point
		pop	si, bp				; bp = count
		push	di				; save minX
		push	bx				; save minY

		; check to see if the points are clockwise.  If they are, 
		; return carry clear.  If they aren't, check flag passed to
		; VidPolygon to see if we should draw the figure or not.
		; We check "clockwiseness" by looking at the max Y coord.  In
		; general, x coords BEFORE this in the list should be GREATER
		; in value, while points AFTER this should be LESS in value.

		dec	bp				; dist is one less
		shl	bp, 1
		shl	bp, 1				; points are 4 bytes
		add	bp, si				; ds:bp -> last y coord
		mov	ss:[polyLast], bp		; save for later
		mov	di, ss:[polyMax]		; get pointer to maxY

		; The test goes like this:
		;  If (prevY == thisY)
		;     if (prevX < thisX) then counterclockwise else clockwise
		;  If (nextY == thisY)
		;     If (prevX < thisX) then clockwise else counterclockwise
		;  If (prevX >= thisX and nextX <= thisX) it's clockwise
		;  If (prevX <= thisX and nextX >= thisX) it's counterclockwise
		; set ds:si -> prev,  ds:di -> this,  ds:bp -> next

		mov	ax, ds:[di].P_x			; get assoc x coord
		mov	bx, ds:[di].P_y			;    and y coord
		cmp	di, bp				; if last one, wrap
		jne	checkFirst
		mov	bp, si				; next one is first
		mov	si, di
		sub	si, size Point
		jmp	havePoints

		; I stuck this here so it's close enough to do a near jmp
		; from above.  When searching for a new max Y value, make sure
		; it's a local minimum in x too.  (Could have chosen max, it
		; doesn't matter.  As long as it's not neither).
checkNewMax:
		mov	ax, ds:[si-(size Point)].P_x
		cmp	ax, ss:[polyMaxYxval]		; use if less
		jg	nextPoint
		jmp	reallyNewMax

checkFirst:
		cmp	di, si				; if first one, wrap
		jne	makePrev
		mov	si, bp				; prev is last
		jmp	makeNext
makePrev:
		mov	si, di				; prev = this - 4
		sub	si, size Point
makeNext:
		mov	bp, di				; next = this + 4
		add	bp, size Point

		; have pointers to points.  Start the tests
		;  If (prevY == thisY)
		;     if (prevX < thisX) then counterclockwise else clockwise
		;  If (nextY == thisY)
		;     If (prevX < thisX) then clockwise else counterclockwise
havePoints:
		cmp	bx, ds:[si].P_y			; if Y = prevY or nextY
		je	flatPrev			;  then special cases
		cmp	bx, ds:[bp].P_y	
		LONG je	flatNext

		;  If (prevX > thisX and nextX <= thisX) it's clockwise
		cmp	ax, ds:[si].P_x
		jg	checkCounter
		je	prevSame		; previous is same. check next
		cmp	ax, ds:[bp].P_x
		jge	clockwise
; bothRight:
		mov	bx, ds:[bp].P_y
		sub	bx, ds:[si].P_y			; need differences
		jmp	commonPlane


		; prevX = X.  Check next.
prevSame:
		cmp	ax, ds:[bp].P_x
		jg	clockwise
		jmp	counterclockwise
		
		;  If (prevX < thisX and nextX >= thisX) it's counterclockwise
checkCounter:
		cmp	ax, ds:[bp].P_x			; check nextX
		jle	counterclockwise

		; if (prevX < thisX and nextX < thisX) (true at this point)
		; if you look at the slope between the previous point and the
		; next point, you can divide the values between clockwise and
		; counterclockwise about the line where deltaX = deltaY.  This
		; requires a few tests to figure out.

		mov	bx, ds:[si].P_y
		sub	bx, ds:[bp].P_y			; need differences
commonPlane:
		mov	ax, ds:[si].P_x
		sub	ax, ds:[bp].P_x
		jge	deltaXPos
		tst	bx
		jns	counterclockwise		
		cmp	ax, bx
		jl	counterclockwise
		jmp	clockwise
deltaXPos:
		tst	bx
		js	clockwise
		cmp	ax, bx
		jle	counterclockwise
clockwise:
		clr	ss:[polyFlag]			; signal clockwise
drawIt:
		clc
done:
		pop	bx				; restore minY
		pop	ax				; restore minX
		.leave
		ret

counterclockwise:
		tst	ss:[polyFlag]			; if flag clear, draw
		mov	ss:[polyFlag], 1		; signal CCW
		jz	drawIt
		stc
		jmp	done
		
		; prevY == thisY.
		;     if (prevX < thisX) then counterclockwise else clockwise
flatPrev:
		; first check to see if all three points are on the same
		; level. If they are, choose another point that is not
		; on the same level, otherwise it is impossible to determine
		; which way the polygon is created. Consider the case of
		; a clipped ellipse, and you'll see why this is so.
		; -- DLR (1/5/94)

		cmp	bx, ds:[bp].P_y			; if all 3 on the same
		je	chooseNewPrev			;   level then new prev
		cmp	ax, ds:[si].P_x			; if less than...
		jl	clockwise
		jg	counterclockwise

		; if equal, we have a double point.  change prev and try again
chooseNewPrev:
		cmp	ss:[polyCount], 3		; if only three, it
		je	clockwise			;  doesn't matter
		dec	ss:[polyCount]			; in case we come back
		cmp	si, ss:[polyPoints].offset	; if wrapped...
		je	wrapped
		sub	si, (size Point)		; make new prev
		jmp	havePoints
wrapped:
		mov	si, ss:[polyLast]		;  ...then wrap ptr
		jmp	havePoints

		; nextY == thisY.
		;     If (nextX < thisX) then clockwise else counterclockwise
flatNext:
		cmp	bx, ds:[si].P_y			; if all 3 on the same
		je	chooseNewNext			;  level then new next
		cmp	ax, ds:[bp].P_x			; if less than...
		jl	counterclockwise
		jg	clockwise

		; if equal, we have a double point.  change next and try again
chooseNewNext:
		cmp	ss:[polyCount], 3		; if only three, it
		je	clockwise			;  doesn't matter
		dec	ss:[polyCount]			; in case we come back
		add	bp, (size Point)		; make new next
		cmp	bp, ss:[polyLast]		; if wrapped...
		LONG jbe havePoints
		mov	bp, ss:[polyPoints].offset	;  ...then wrap ptr
		jmp	havePoints

GetPolygonBounds endp

		; polygon coordinate buffer.  One word/scan line.  Holds x 
		; coordinate of left edge
ifdef	MULT_RESOLUTIONS
NMEM <polyEdge	sword	MAX_POLYGON_EDGE_TABLE dup (?)		>
else
NMEM <polyEdge	sword	SCREEN_HEIGHT dup (?)			>
endif

NMEM <VidEnds		Polygon	>
MEM  <VidEnds		Line	>
