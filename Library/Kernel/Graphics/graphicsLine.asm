COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1988 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		Graphics
FILE:		Graphics/graphicsLine.asm

AUTHOR:		Jim DeFrisco

ROUTINES:
	Name		Description
	----		-----------
   GBL	GrDrawLine	Draw a line
   GBL	GrDrawLineTo	Draw a line

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	jad	12/88	initial version


DESCRIPTION:
	This file contains the application interface for the draw line
	routine.

	$Id: graphicsLine.asm,v 1.1 97/04/05 01:13:40 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

kcode segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrDrawVLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a vertical line.

CALLED BY:	GLOBAL
PASS:		di	- GState handle
		ax,bx	- first coordinate
		dx	- y coordinate of second endpoint
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrDrawVLine	proc	far
		call	EnterGraphics
		xchg	bx, dx
		call	SetDocPenPos
		xchg	bx, dx
		jc	vlGString

		; drawing to a device

		mov	cx,ax			; setup all four coords
		call	TrivialRejectFar	; won't return if no draw
		call	DrawFatOrThinLine	; draw the line
		jmp	ExitGraphics

		; handle writing out the gstring
vlGString:
		mov	si, dx			; last coord goes in si
		mov	dl, GR_DRAW_VLINE	; graphics opcode
		xchg	ax, bx			; ax is first word (put in bx)
		xchg	ax, dx			; bx was 2nd word (put in dx)
		mov	cl, size OpDrawVLine - 1 ; #databytes
		mov	ch, GSSC_FLUSH
		call	GSStoreBytes		;and call the store routine
		jmp	ExitGraphicsGseg
GrDrawVLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrDrawHLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a horizontal line.

CALLED BY:	GLOBAL

PASS:		di	- GState handle
		ax,bx	- coordinates of first endpoint
		cx	- x coordinate of second endpoint
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrDrawHLine	proc	far
		call	EnterGraphics
		xchg	ax, cx			; need to update the cur pos
		call	SetDocPenPos
		xchg	ax, cx
		jc	hlGString

		; drawing to a real device

		mov	dx,bx			; set all four coords
		call	TrivialRejectFar	; do the basic test
		call	DrawFatOrThinLine	; call into line module
		jmp	ExitGraphics

		; writing to a graphics string
hlGString:
		mov	al, GR_DRAW_HLINE	; graphics opcode
		mov	cx, size OpDrawHLine - 1 ; # data bytes
		call	WriteGSElementFar
		jmp	ExitGraphicsGseg
GrDrawHLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrDrawLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a line.

CALLED BY:	GLOBAL

PASS:		di	- GState handle
		ax,bx	- first endpoint (document coords)
		cx,dx	- second endpoint 
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrDrawLine	proc	far
		call	EnterGraphics
		xchgdw	axbx, cxdx
		call	SetDocPenPos			; set new pen position
		jc	dlGString	

		; we're drawing to a device.  Make sure we have a window, 
		; then see if we can draw the line the easy way.

		call	TrivialRejectFar		; valid window, etc ?
		xchgdw	axbx, cxdx
		call	DrawFatOrThinLine		; do the drawing

		jmp	ExitGraphics

		; handle writing to a graphics string
dlGString:
		mov	al, GR_DRAW_LINE
		mov	cx, 8			; # data bytes
		call	WriteGSElementFar	; write info to GString
		jmp	ExitGraphicsGseg
GrDrawLine	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawFatOrThinLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a single line, either fat or thin

CALLED BY:	INTERNAL
		GrDrawLine, others
PASS:		EnterGraphics called
		ax..dx		- line endpoints (document coords)
RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,di,si,bp

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	11/ 4/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawFatOrThinLine	proc	far

		; if it's a fat line, use the slower routine

		call	CheckThinLine
		jc	fatLine

		; nothing special, just draw a 1-pixel line

		call	DrawLine
done:
		ret

		; call the general polyline routine.
fatLine:
		push	dx, cx, bx, ax		;pass to DrawPolyline
		mov	cx, 2			;two points
		clr	dl			;not connected
		mov	si, sp			;si - offset to points
		mov	bp, ss			;segment of points list
		mov	di, GS_lineAttr		;offset to attributes
		call	DrawPolylineFar
		add	sp, 4 * (size word)	;clear stack
		jmp	done
DrawFatOrThinLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckThinLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check the transformed line width to see if we can draw
		a single pixel line. If not, the caler of this routine
		will need to call a slower, more complex routine like
		DrawPolylineFar() (as opposed to just calling the video
		driver to render the line).

CALLED BY:	INTERNAL
		various line drawing routines
PASS:		ds	- GState
		es	- Window

RETURN:		carry	- clear if the line width is one pixel

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		jim	4/ 7/92		Initial version
		Don	8/10/94		Made logic match PolylineSpecial

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckThinLine	proc	far
		uses	ax, dx
		.enter
	;
	; No scale or rotation, and width must be 1.0
	;
		movwwf	dxax, ds:[GS_lineWidth]
		test	es:[W_TMatrix].TM_flags, TM_COMPLEX
		jnz	complex
		tst	ax
		jnz	special
checkOne:
		cmp	dx, 1
		ja	special
		clc
exit:		
		.leave
		ret
	;
	; There is something complex, so go slowly
	;
special:
		stc
		jmp	exit
	;
	; We have some sort of complex transformation (rotation or scaling)
	; The caller of this routine can deal with any complex transformation,
	; so all we must determine is whether or not the scaled width is 1.
complex:
		call	ScaleScalar		; scaled line width => AX
		mov_tr	dx, ax
		jmp	checkOne		
CheckThinLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a straight line

CALLED BY:	INTERNAL

PASS:		ax,bx	- first point
		cx,dx	- second point
		ds	- points to GState

RETURN:		nothing

DESTROYED:	ax-dx,di,si

PSEUDO CODE/STRATEGY:
		translate the coords;
		check for optimizations;
		draw the line;

		IMAGING CONVENTIONS NOTE:
			This routine has been fixed to conform to the imaging
			conventions for version 2.0.  In particular, the 
			end type of the line is taken into account when figuring
			out which pixels should be filled.   This handles

			GrDrawLine, GrDrawLineTo, GrDrawRect, GrDrawRectTo,
			GrDrawHLine, GrDrawHLineTo, GrDrawVLine, GrDrawVLineTo

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	03/89		Initial version
	Steve	7/18/89		Corrected destroyed list
	Steve	7/25/89		broke into two routines with fall thru
	jim	3/91		fixed for imaging conventions

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DrawLine	proc	near

		;  translate coordinates

		call	GrTransCoord2Far	; translate both coords
		jnc	checkStyle		; skip draw if overflow
		ret					

		; coords are OK.  Draw the line.
checkStyle:
		mov	di, GS_lineAttr			; pass line attributes
		call	DrawLineLow
		ret
DrawLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawLineLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a straight line

CALLED BY:	INTERNAL

PASS:		ax,bx	- first point already translated
		cx,dx	- second point already translated
		ds	- points to GState
		di	- offset to attributes to use

RETURN:		nothing

DESTROYED:	ax-dx,si

PSEUDO CODE/STRATEGY:
		check for optimizations;
		draw the line;

		IMAGING CONVENTIONS NOTE:
			This routine assumes that the line coordinates have
			been fiddled with to account for the line end type.
			The line drawn from this point on includes the endpoints
			(in device coordinates) specified.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	03/89		Initial version
	Steve	7/18/89		Corrected destroyed list
	Steve	7/25/89		Broke into two routines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DrawLineLow proc far

		; check for styled line, and call other routine if so

		cmp	ds:[GS_lineStyle], LS_SOLID
		jne	drawStyled

		; adjust line ends for imaging conventions

		call	AdjustLineEnds

		; check coords for trivial reject

		call	TrivialRejectRect
		jc	done				;  reject: before left

		; call the driver

		push	di				; save attributes
		mov	si, di				;use passed attributes

		; if actually a rectangle then use the faster one

		cmp	ax, cx
		jz	useRect
		cmp	bx, dx
		jz	useRect

		mov	di,DR_VID_LINE
common:
		push	bp
		call	es:[W_driverStrategy]		; make call to driver
		pop	bp
		pop	di

done:
		ret

drawStyled:
		mov	si, offset GS_numOfDashPairs	; ds:si -> dash info
		call	DrawLineLowStyled
		ret

		; call the driver drawing a rect instead, but we now want to
		; sort the coordinates first.
useRect:
		mov	di, DR_VID_RECT
		cmp	ax, cx
		jle	checkY
		xchg	ax, cx
checkY:
		cmp	bx, dx
		jle	common
		xchg	bx, dx
		jmp	common

DrawLineLow	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AdjustLineEnds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust the endpoints of a line for imaging conventions

CALLED BY:	INTERNAL
		DrawLineLow
PASS:		ax,bx,cx,dx	- endpoints of line
		ds		- GState
RETURN:		ax,bx,cx,dx	- adjusted appropriately
DESTROYED:	si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AdjustLineEnds	proc	far

		push	di
		cmp	ds:[GS_lineEnd], LE_BUTTCAP	; if SQUARE or ROUND, o
		je	adjustLine			;  nope, adjust line
done:
		pop	di
EC <		call	Check4CoordsFar			; validate coords >
		ret

		; OK, we are drawing a buttcap end type line.  If the line is
		; more horizontal than vertical, subtract 1 from the rightmost
		; x position.  If it is more vertical, decrement the bottomost
		; y position.  If it is exactly 45 degrees, decrement both.
		; use di=delta x, si=delta y

adjustLine:
		mov	di, cx				; calc delta x
		sub	di, ax
		jns	calcydiff
		neg	di
calcydiff:
		mov	si, dx				; calc delta y
		sub	si, bx
		jns	checkSlope
		neg	si
checkSlope:
		cmp	si, di				; y > x ?
		jb	decHorizontal			;  more horizontal
		je	decBoth				;  equal, decrement both

		; line is more vertical, decrement the bottom y position

		cmp	bx, dx				; see which is which
		je	done				; can only get so small
		jg	vswitched
		dec	dx				; assume normal case
		jmp	done				;  check for odd-case
vswitched:
		dec	bx				;   odd case, handle it
		jmp	done

		; handle decrementing both the horiz and vertical.  do vertical
		; first
decBoth:
		cmp	bx, dx				; see which is which
		je	decHorizontal			; can only get so small
		jg	bswitched
		dec	dx				; assume normal case
		jmp	decHorizontal			;  check for odd-case
bswitched:
		dec	bx				;   odd case, handle it

		; now decrement the horizontal
decHorizontal:
		cmp	ax, cx				; see which is which
		je	done				; can only get so small
		jg	hswitched
		dec	cx				; assume normal case
		jmp	done				;  check for odd-case
hswitched:
		dec	ax				;   odd case, handle it
		jmp	done
AdjustLineEnds	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TrivialRejectRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do trivial reject test on rectangle bounds

CALLED BY:	INTERNAL
		DrawLineLow

PASS:		es		- Window
		ax,bx,cx,dx	- rectangle bounds (could be non-sorted)
RETURN:		carry		- set if can be trivially rejected
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	3/25/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TrivialRejectRect proc	far
		cmp	ax, cx				; sortem
		jg	xNotSorted
		cmp	cx,es:[W_maskRect.R_left]
		jl	doneReject			;  reject: before left
		cmp	ax,es:[W_maskRect.R_right]
		jg	doneReject			;  reject: past right
checkY:
		cmp	bx, dx				; sortem
		jg	yNotSorted
		cmp	dx,es:[W_maskRect.R_top]
		jl	doneReject			;  reject: before top
		cmp	bx,es:[W_maskRect.R_bottom]
finalCheck:
		jg	doneReject			;  reject: past bottom
		clc

		ret

xNotSorted:
		cmp	ax,es:[W_maskRect.R_left]
		jl	doneReject			;  reject: before left
		cmp	cx,es:[W_maskRect.R_right]
		jle	checkY				;  OK, continue with Y
doneReject:
		stc					; indicate rejected
		ret

yNotSorted:
		cmp	bx,es:[W_maskRect.R_top]
		jl	doneReject			;  reject: above top
		cmp	dx,es:[W_maskRect.R_bottom]
		jmp	finalCheck
		
TrivialRejectRect endp

kcode ends

;------------------------------

GraphicsLine	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrDrawLineTo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a straight line from the current pen position

CALLED BY:	GLOBAL

PASS:		di	- GState handle
		cx	- x2 (right)
		dx	- y2 (bottom)
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		call GSStore to try to store command to memory
		if we're writing to the screen:
			translate coords to screen coords;
			call line function in driver;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	12/88...	Initial version
	Jim	3/89		Changed to support transformation matrix

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrDrawLineTo	proc	far
		call	EnterGraphics		; get started
		jc	ltGString

		; writing to a device.

		call	TrivialRejectFar	; make sure it's OK to draw
		call	GetDevPenPos		; ax/bx = current pos
		jc	done
		call	CheckThinLine		; check for 1-pixel line
		jc	fatLine

		; do the optimial amount of work for a thin line

		xchgdw	axbx, cxdx		; get coords in ax/bx
		call	SetDocPenPos		; set the current pen position
		call	GrTransCoordFar		; 2nd endpoint in ax/bx already
		xchgdw	axbx, cxdx		; get coords in ax/bx
		jc	done
		mov	di, GS_lineAttr		; pass line attributes
		call	DrawLineLow
done:
		jmp	ExitGraphics

		; drawing a fat line
fatLine:
		call	GetDocPenPos		; get/set current pen pos
		xchgdw	axbx, cxdx
		call	SetDocPenPos		; set new pen position
		push	dx, cx, bx, ax
		mov	cx, 2			; two points
		clr	dl			; not connected
		mov	si, sp			; si - offset to points
		mov	bp, ss			; segment of points list
		mov	di, GS_lineAttr		; offset to attributes
		call	DrawPolylineFar
		add	sp, 4 * (size word)	; clean up the stack
		jmp	ExitGraphics		; exit if done already

		; handle writing to a graphics string
ltGString:
		movdw	axbx, cxdx		; get coords in ax/bx
		call	SetDocPenPos		; set the current pen position
		mov	al, GR_DRAW_LINE_TO
		mov	bx, cx			; set up right register
		mov	cl, size OpDrawLineTo - 1 ; #databytes
		mov	ch, GSSC_FLUSH
		call	GSStoreBytes		; write out to string
		jmp	ExitGraphicsGseg
GrDrawLineTo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrDrawRelLineTo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a line from the current pen position, given a displacement
		from the current pen position to draw to.

CALLED BY:	GLOBAL
PASS:		di	- GState handle
		dx.cx	- WWFixed X displacement (document coords)
		bx.ax	- WWFixed Y displacement (document coords)
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrDrawRelLineTo	proc	far
		call	EnterGraphics		; get started
		jc	ltGString

		; writing to a device.

		call	TrivialRejectFar	; make sure it's OK to draw
		call	CheckThinLine		; check for 1-pixel line
		jc	fatLine
		
		; do the optimial amount of work for a thin line

		call	TransRelCoord		; 2nd endpoint in ax/bx already
		jc	done
		mov	di, GS_lineAttr		; pass line attributes
		call	DrawLineLow
done:
		jmp	ExitGraphics

		; drawing a fat line
fatLine:
		call	GetRelDocPenPos		; get/set current pen pos
		push	bx, ax, dx, cx		; pass to DrawPolyline
		mov	cx, 2			; two points
		clr	dl			; not connected
		mov	si, sp			; si - offset to points
		mov	bp, ss			; segment of points list
		mov	di, GS_lineAttr		; offset to attributes
		call	DrawPolylineFar
		add	sp, 8			; clean up stack
		jmp	ExitGraphics		; exit if done already

		; handle writing to a graphics string
ltGString:
		call	SetRelDocPenPos		; set the current pen position
		push	ds, si, bx, ax, dx, cx	; save coords
		segmov	ds, ss, si
		mov	si, sp
		mov	cx, size PointWWFixed
		mov	ah, GSSC_DONT_FLUSH
		mov	al, GR_DRAW_REL_LINE_TO
		call	GSStore			; write out to string
		pop	ds, si, bx, ax, dx, cx	; save coords
		jmp	ExitGraphicsGseg
GrDrawRelLineTo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawLineLowStyled
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a single pixel line, using the current line style

CALLED BY:	INTERNAL
		DrawLine

PASS:		ax,bx	- first point already translated
		cx,dx	- second point already translated
		ds	- points to GState
		di	- offset in GState to attributes to use
		si	- offset in GState to DashStruct

RETURN:		nothing

DESTROYED:	ax-dx,si

PSEUDO CODE/STRATEGY:
		check for optimizations;
		draw the line;

		IMAGING CONVENTIONS NOTE:
			This routine assumes that the line coordinates have
			been fiddled with to account for the line end type.
			The line drawn from this point on includes the 
			endpoints (in device coordinates) specified.

		STACK USAGE:
			This routine allocates two buffers on the stack which
			are used to pass info to the video driver.  The 
			organization of these buffers are as follows:

			+-----------------------+  <- SP
			|			|
			| DashPairArray		|
			|			|
			+-----------------------+
			|			|
			| DashInfo structure	|
			|			|
			+-----------------------+  <- BP

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	3/25/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

dInfo	equ	<bp-size DashInfo>

DrawLineLowStyled	proc	far

		; adjust line ends for imaging conventions

		push	si
		call	AdjustLineEnds
		pop	si			; save ptr to dash array

		; before we do anything, check for trivial reject of line
	
		call	TrivialRejectRect
		jc	done

		; we need to allocate space on the stack for a structure to
		; pass to the video driver.  It's size will depend on the
		; number of on/off pairs in the dash info.

		push	bp, di			; save old frame pointer/attrib
		mov	bp, sp			; setup stack frame
		sub	sp, size DashInfo	; make room for initial struct
		mov	ss:[dInfo].DI_pt1.P_x, ax ; save away params we know
		mov	ss:[dInfo].DI_pt1.P_y, bx
		mov	ss:[dInfo].DI_pt2.P_x, cx
		mov	ss:[dInfo].DI_pt2.P_y, dx
		mov	al, ds:[si].DS_nPairs	; get #pairs (CHANGE TO WORD)
		clr	ah
		mov	ss:[dInfo].DI_nPairs, ax ; save # pairs
		shl	ax, 1			; *8 for size buffer we'll need
		shl	ax, 1
		shl	ax, 1
		sub	sp, ax			; allocate buffer space
		mov	ss:[dInfo].DI_patt.offset, sp
		mov	ss:[dInfo].DI_patt.segment, ss
		mov	al, ds:[si].DS_offset	; get offset into pattern
		clr	ah
		mov	ss:[dInfo].DI_pattIdx, ax ; save for video driver

		; we've initialized all the info, now we have to traslate/copy
		; the scalar dash lengths (given in points) info word device
		; coordinates.

		push	di			; save offset to Attrib info
		mov	dx, es			; save it here
		les	di, ss:[dInfo].DI_patt	; load pointer to buffer
		call	ScaleDashLengths
		pop	si			; si -> offset to attrib info
		mov	es, dx			; es -> Window

		; at this point, we have all the info to call the video driver

		mov	bx, ss			; setup pointer to DashInfo
		mov	dx, bp			; bx:dx -> DashInfo
		sub	dx, size DashInfo
		clr	al			; include first pixel
		mov	di, DR_VID_DASH_LINE	; load function number
		push	bp
		call	es:[W_driverStrategy]
		pop	bp

		mov	sp, bp			; restore stack pointer
		pop	bp, di
done:
		ret
DrawLineLowStyled	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScaleDashLengths
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scale the lengths of the dashes, taking into account the
		angle of the line

CALLED BY:	INTERNAL
		DrawLineLowStyled

PASS:		ds	- points to gstate
		ds:si	- pointer to DashStruc
		es:di	- pointer to where to store pixel lengths
		bp	- pointer to DashInfo struct (bp-size DashInfo)
		dx	- pointer to Window structure
RETURN:		nothing
DESTROYED:	ax,bx,di,cx

PSEUDO CODE/STRATEGY:
		We need to normalize the lengths of the dashes in pixels 
		depending on the angle of the line.  Specifically, since 
		Bresenham's algorithm will user exactly one pixel for each
		coordinate along the major axis, dash lengths along a diag
		line would appear longer than those on a horizontal line,
		even though the same number of pixels are used.  So we need
		to shorten the dashes for diagonal lines.  The ratio by which
		we shorten them is the ratio of the length along the major 
		axis (either deltaX or deltaY) to the length of the line.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	3/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScaleDashLengths proc	near
		uses	dx		
		.enter

		mov	ax, ss:[dInfo].DI_pt1.P_x
		sub	ax, ss:[dInfo].DI_pt2.P_x	; ax = deltaX
		mov	bx, ss:[dInfo].DI_pt1.P_y
		sub	bx, ss:[dInfo].DI_pt2.P_y	; ax = deltaY
		call	CalcDistance		; bx.ax = magic ratio

		; calculate the final scale factor for each dash, by getting
		; the length of a scalar of length 1.0 and multiplying that
		; factor by the previous factor

		xchgdw	dxcx, bxax		; dxcx = magic ratio
		mov	ax, es			; save target buffer pointer
		xchg	ax, bx			; ax -> Window, bx -> targ buff
		mov	es, ax			; es -> Window
		push	dx
		mov	dx, 256			; so we can get a fraction 
		clr	ax
		call	ScaleScalar		; ax = scaled 1.0 length *256
		pop	dx
		mov	es, bx			; restore target buffer seg
		clr	bh
		mov	bl, ah
		mov	ah, al
		clr	al			; bx.ax = unit length, dev crds
		call	GrMulWWFixed		; dx.cx = scale factor
		movdw	bxax, dxcx		; bx.ax = scale factor

		; next, we scale the individual dash lengths by our magic #.

		mov	cl, ds:[si].DS_nPairs	; get loop count
		clr	ch
		shl	cx, 1			; #on/offs
		add	si, offset DS_pairs	; ds:si -> DashPairArray
transLoop:
		push	cx
		mov	dl, ds:[si]		; add in next length
		clr	dh
		clr	cx
		call	GrMulWWFixed		; dx = length
		tst	dx			; check for zero.  Then store 1
		jz	checkforzero
storeIt:
		movwwf	es:[di], dxcx		; store dash length
		add	di, size WWFixed	; bump to next storage location
		inc	si
		pop	cx
		loop	transLoop

		.leave
		ret

checkforzero:
		tst	cx			; if result=0, store 1
		jnz	storeIt
		inc	dx
		jmp	storeIt
ScaleDashLengths endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcDistance
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the distance between two points, given deltaX/deltaY

CALLED BY:	INTERNAL
		various routines
PASS:		ax	- deltaX (signed)
		bx	- deltaY (signed)
RETURN:		bx.ax	- max(deltaX,deltaY) / distance  (WWFixed)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	3/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcDistance	proc	near
		uses	dx,cx
		.enter

		tst	ax			; get absolute value
		jns	haveDeltaX
		neg	ax			; take abs value
haveDeltaX:
		tst	bx			; take absolute value
		jns	haveDeltaY
		neg	bx			; take abs value
haveDeltaY:
		cmp	ax, bx			; see which to use
		ja	haveMax			;  have maximum
		xchg	ax, bx			; set ax = maximum
haveMax:
		push	ax
		mov	dx, ax
		mul	dx
		mov	cx, dx
		xchg	ax, bx			;
		mov	dx, ax
		mul	dx
		add	ax, bx
		adc	dx, cx			; dxax = sqr(a) + sqr(b)

		; now we need a squareroot

		call	SqrRootDWordLine	; axbx = WWFixed distance
		xchg	bx, ax			; bxax = distance
		pop	dx			; restore max side
		clr	cx
		call	GrSDivWWFixed		; dxcx = magic ratio
		movdw	bxax, dxcx
		.leave
		ret
CalcDistance	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SqrRootDWordLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the square root of a 32 bit number

CALLED BY:	CalcPointPointDistance

PASS:		DX:AX	= DWord (High:Low) - ALL INTEGER, NO FRAC

RETURN:		Carry	= Set (success)
			  AX.BX	= Square Root (WWFixed)
				- or -
			= Clear (failure)
			  AX,BX	= Destroyed

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
	A = (N/A +A)/2		

	
	The following produces a reasonable good fraction with little effort.
	In almost all cases repeatedly using this formula returns the
	floor of the square root. So i know that
	(A+x)(A+x) = N = A^2 + R
	x^2 + 2Ax + A^2 = A^2 + R
	X^2 + 2Ax = R
	since x < 1 , throw out X^2
	2Ax = R
	x = R/2A
	In a very few cases (actually I've only found one) the formula
	returns the ceiling. If this happens, I reduce my approximation
	by 1 and and calc x again

	The max value for passed dx is calced by 8192*65535, so that
	the calculation of the initial approx does not puke.

	ffffffh is chosen as the split point for calcing the 
	initial approximation because 300 * 65535 > ffffffh and it
	is easy to check for ffffffh just be checking for dh = 0

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/13/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SqrRootDWordLine		proc	near
	uses	cx, dx, di, si
	.enter
	
	cmp	dx,1fffh					
	jae	done				;implied clc

	;; The initial approximation is chosen in a very arbitary fashion
	;;(N/300)+2 if N < ffffffh
	;;(N/8192)+2 if N >= ffffffh
	;; It is important that the above division returns a number
	;; less than 65536 to prevent a divide by 0 error
	;; a much better algorithm is used in GrSqrRootWWFixed but I am
	;; under a tight deadline so I am using this for now

	mov	di,dx				;save value
	mov	si,ax
	mov	bx,300				
	tst	dh
	jz	10$				;jmp if N > ffffffh
	mov	bx,8192				
10$:
	div	bx				;calc initial approx
	add	ax,2				;initial approx

	; Approximate until we get a suitable root
	;
nextApprox:
	mov	bx,ax				;save current approx
	mov	ax,si				;value
	mov	dx,di
	div	bx				;value/approx
	add	ax,bx				;add approx
	shr	ax,1				;take average
	cmp	ax,bx				;cmp new to old
	je	gotInteger			;jmp if last 2 approxs same
	sub	bx,ax				;sub new from old
	cmp	bx,1
	je	gotInteger			;jmp if only 1 dif from last
	cmp	bx,-1
	jne	nextApprox			;fall if only 1 dif from last

	; We've got the integer - go get the fraction
	;
gotInteger:
	clr	dx				;A high
	mov	bx,ax				;A 
	mul	bx				;A^2
	sub	ax,si				
	sbb	dx,di				;A^2 - N = -R
	jg	aWeirdCase
	neg	ax				;+R
	mov	dx,ax				;R
	clr	cx				;R frac
	push	bx				;A
	shl	bx,1				;2 * A
	clr	ax				;2*A frac
	call	GrUDivWWFixed
	mov	bx,cx				;frac of quotient
	pop	ax
	stc					;signal success
done:
	.leave
	ret

aWeirdCase:
	mov	ax,bx				;A
	dec	ax				;better A
	jmp	short gotInteger
SqrRootDWordLine		endp

GraphicsLine	ends
