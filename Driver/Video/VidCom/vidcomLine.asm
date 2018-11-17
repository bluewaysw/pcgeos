
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Video Drivers
FILE:		vidcomLine.asm

AUTHOR:		Jim DeFrisco

ROUTINES:
	Name			Description
	----			-----------
    INT VidLineDDA		Compute Bresenham's algorithm between two
				endpoints
    INT DDA_X			X part of line calculation
    INT DDA_Y			Y part of line calculation
    GLB VidDrawLine		Draw a single pixel wide line
    INT DrawRectDDA		callback routine for VidDrawLine
    GLB VidPolyline		Draw a series of connected lines
    INT PolyRectDDA		Callback function for VidPolyline
    GLB VidDashLine		Draw a dashed line

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	12/88		Initial revision


DESCRIPTION:
	This file contains the line routine common to all video drivers.
	
	$Id: vidcomLine.asm,v 1.1 97/04/18 11:41:55 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VidSegment	Line


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidLineDDA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compute Bresenham's algorithm between two endpoints

CALLED BY:	INTERNAL
		VidDrawLine, VidPutLine, VidPolygon

PASS:		ss		- points to local video stack in dgroup
		ss:[lineX1]	- line endpoints
		ss:[lineY1]
		ss:[lineX2]
		ss:[lineY2]
		al		- flag to determine if first pixel should be
				  skipped.  (0=no, 1=yes)
		dx:cx		- far routine to call with each line segment 
		es		- video RAM

RETURN:		nothing

DESTROYED:	everything except bp

PSEUDO CODE/STRATEGY:
		This performs Bresenham's algorithm (a Digital Differential
		Analyzer), calling the supplied function for each 
		horizontal/vertical line segment that makes up the whole line.
		The function is called with the following parameters:

			ax,bx	    - upper left corner of rectangle 
			cx,dx	    - lower right corner of rectangle
			es,ds,si,di - as passed to this routine

		Note: callback routine can trash ax,bx,cx,dx,bp but must 
		      preserve es,ds,si, and di

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	11/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VidLineDDA	proc	far

		uses	bp
		.enter

		; figure absolute differences, and select a routine to call

		and	cs:[DX_test1st], 0xfe	; force CLC
		or	cs:[DX_test1st], al	; force STC if al = 1
		and	cs:[DY_test1st], 0xfe	; force CLC
		or	cs:[DY_test1st], al	; force STC if al = 1
		mov	ax, ss:[lineX2]		
		sub	ax, ss:[lineX1]
		mov	bp, 1
		jns	haveAbsX
		neg	bp			; no, it's right to left
		neg	ax			; ax = absolute value
haveAbsX:
		mov	ss:[signX], bp		; assume left to right
		mov	bx, ss:[lineY2]		
		sub	bx, ss:[lineY1]
		mov	bp, 1			; assume top to bottom
		jns	haveAbsY
		neg	bp			; no, it's bottom to top
		neg	bx			; bx = absolute value
haveAbsY:
		mov	ss:[signY], bp		; assume left to right
		cmp	ax, bx
		jge	VLD_drawX		; draw along the x axis

		; save away the callback address and draw along y axis

		mov	cs:[DY_call].offset, cx
		mov	cs:[DY_call].segment, dx
		call	DDA_Y			
done:
		.leave
		ret

		; save away the callback address and draw along x axis
VLD_drawX:
		mov	cs:[DX_call].offset, cx
		mov	cs:[DX_call].segment, dx
		call	DDA_X			; else along x axis
		jmp	done
VidLineDDA	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DDA_X
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	X part of line calculation

CALLED BY:	VidLineDDA

PASS:		ax	- abs delta x
		bx	- abs delta y
		es		- video RAM

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		put pseudo code here

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	11/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DECREMENT_BIT	equ	0x08		; tells inc from dec
LE_BIT		equ	0x02		; tells jle from jl

DDA_X		proc	near
		sal	bx, 1			; bx = 2*abs(detlay)
		mov	dx, bx
		sub	dx, ax			; init d = 2dy - dx
		sal	ax, 1			; ax = 2*abs(delta x)
		mov	cs:[DX_dbumpy], ax	; store dec var bump amts
		mov	cs:[DX_dbumpx], bx
		mov	ax, ss:[lineX1]		; start at the beginning
		mov	bx, ss:[lineY1]		; start at the beginning
		mov	cx, ax			; init x2
DX_test1st equ  (this byte)
		clc				; set to SKIP first pixel
		jc	skipFirstPixel

		; if we're drawing right to left, we need to fix a few things
testRightLeft:
		and	cs:[DX_incx], not DECREMENT_BIT
		and	cs:[DX_modJump], not LE_BIT
		tst	ss:[signX]		; see which way we're drawing
		js	rightToLeft		;   drawing right to left
		jmp	startX

		; bumping both x and y.  First, send out the run of pixels
bumpY:
		push	cx,bx,dx		; save dec var and curr point
		mov	dx, bx			; dx get same y value
		tst	ss:[signX]		; swap points 
		jns	haveOrder
		xchg	ax, cx			; swap x coords
haveOrder:
		.inst byte 9ah
;		call	DrawRectFront		; perform far callback
DX_call	equ 	this dword
		.inst word 1234h
		.inst word 1234h
		pop	cx,bx,dx		; restore vars
		cmp	cx, ss:[lineX2]		; are we done yet ?
		je	done
		mov	ax, cx			; reload new X1
		add	ax, ss:[signX]
		add	bx, ss:[signY]		; bump y
DX_dbumpy equ	(this word)+2
		sub	dx, 1234h		; adjust decision variable

		; bump X (we always need to do this)
bumpX:
DX_incx equ	(this byte)
		inc	cx			; bump to a new x pos
		cmp	cx, ss:[lineX2]		; are we done yet ?
		je	bumpY
DX_dbumpx equ	(this word)+2
		add	dx, 1234h

		; OK, we're ready to go.
startX:
		cmp	dx, 0			; see which direction to go

		; we have to modify this jump from jl to a jle depending on
		; whether we are drawing the line from left to right or from
		; right to left.  This is to ensure that the same pixels are
		; written for each case.
DX_modJump equ	(this byte)
		jl	bumpX
		jmp	bumpY
done:
		ret

		; skip the first pixel.  Here we modify lineX1 and lineY1 so
		; that we're one pixel along the line
skipFirstPixel:
		cmp	cx, ss:[lineX2]		; skip whole line ?
		je	done
		tst	dx			; check out decision variable
		jz	checkLeftRight		; if zero, need more checking
		js	bump1stX
bump1stY:
		add	bx, ss:[signY]
		sub	dx, cs:[DX_dbumpy]
bump1stX:
		add	cx, ss:[signX]
		add	dx, cs:[DX_dbumpx]
		mov	ax, cx
		mov	ss:[lineX1], ax	
		cmp	cx, ss:[lineX2]		; ready to draw ?
		je	bumpY			;  yes, go for it
		jmp	testRightLeft

		; drawing right to left, slightly change one of the branches
rightToLeft:
		or	cs:[DX_incx], DECREMENT_BIT
		or	cs:[DX_modJump], LE_BIT
		jmp	startX

		; second part of skipFirstPixel
checkLeftRight:
		tst	ss:[signX]		; if going right to left...
		js	bump1stX
		jmp	bump1stY
DDA_X	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DDA_Y
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Y part of line calculation

CALLED BY:	VidLineDDA

PASS:		ax	- abs delta x
		bx	- abs delta y
		es		- video RAM

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		put pseudo code here

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	11/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DDA_Y		proc	near
		sal	ax, 1			; ax = 2*abs(detlax)
		mov	cx, ax
		sub	cx, bx			; init d = 2dx - dy
		sal	bx, 1			; bx = 2*abs(delta y)
		mov	cs:[DY_dbumpy], ax	; store dec var bump amts
		mov	cs:[DY_dbumpx], bx
		mov	ax, ss:[lineX1]		; start at the beginning
		mov	bx, ss:[lineY1]		; start at the beginning
		mov	dx, bx			; init y2
DY_test1st equ  (this byte)
		clc				; set to SKIP first pixel
		jc	skipFirstPixel

		; if we're drawing bottom to top, we need to fix a few things
testUpDown:
		and	cs:[DY_incy], not DECREMENT_BIT
		and	cs:[DY_modJump], not LE_BIT
		tst	ss:[signY]		; see which way we're drawing
		LONG js	bottomToTop		;   drawing right to left
		jmp	startY

		; bumping both x and y.  First, send out the run of pixels
bumpX:
		push	cx,ax,dx		; save dec var and curr point
		mov	cx, ax			; dx get same y value
		tst	ss:[signY]		; swap points 
		jns	haveOrder
		xchg	bx, dx			; swap x coords
haveOrder:
		.inst byte 9ah
;		call	DrawRectFront		; perform far callback
DY_call	equ 	this dword
		.inst word 1234h
		.inst word 1234h

		pop	cx,ax,dx		; restore vars
		cmp	dx, ss:[lineY2]		; are we done yet ?
		je	done
		mov	bx, dx			; reload new Y1
		add	bx, ss:[signY]
		add	ax, ss:[signX]		; bump x
DY_dbumpx equ	(this word)+2
		sub	cx, 1234h		; adjust decision variable

		; bump Y (we always need to do this)
bumpY:
DY_incy equ	(this byte)
		inc	dx			; bump to a new y pos
		cmp	dx, ss:[lineY2]		; are we done yet ?
		je	bumpX
DY_dbumpy equ	(this word)+2
		add	cx, 1234h

		; OK, we're ready to go.
startY:
		cmp	cx, 0			; see which direction to go

		; we have to modify this jump from jl to a jle depending on
		; whether we are drawing the line from top to bottom or from
		; bottom to top.  This is to ensure that the same pixels are
		; written for each case.
DY_modJump equ	(this byte)
		jl	bumpY
		jmp	bumpX
done:
		ret

		; skip the first pixel.  Here we modify lineX1 and lineY1 so
		; that we're one pixel along the line
skipFirstPixel:
		cmp	dx, ss:[lineY2]		; skip whole line ?
		je	done
		tst	cx			; check out decision variable
		jz	checkDownUp		; if zero, need more checking
		js	bump1stY
bump1stX:
		add	ax, ss:[signX]
		sub	cx, cs:[DY_dbumpx]
bump1stY:
		add	dx, ss:[signY]
		add	cx, cs:[DY_dbumpy]
		mov	bx, dx
		mov	ss:[lineY1], bx	
		cmp	dx, ss:[lineY2]		; ready to draw ?
		je	bumpX			;  yes, go for it
		jmp	testUpDown

		; second part of skipFirstPixel
checkDownUp:
		tst	ss:[signY]		; if going up or down
		js	bump1stY
		jmp	bump1stX

		; drawing right to left, slightly change one of the branches
bottomToTop:
		or	cs:[DY_incy], DECREMENT_BIT
		or	cs:[DY_modJump], LE_BIT
		jmp	startY
DDA_Y	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidDrawLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a single pixel wide line

CALLED BY:	GLOBAL

PASS:
		ax - x1
		bx - y1
		cx - x2
		dx - y2
		ds - graphics state
		es - Window struct
		si - offset to CommonAttr Structure to use

RETURN:		es - Window structure (may have moved)

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	12/88		Initial version
	srs	3/7/89		Gets attributes in si now

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VidDrawLine	proc	far

		; save coordinates

		mov	ss:[lineX1], ax		; save endpoints
		mov	ss:[lineY1], bx
		mov	ss:[lineX2], cx
		mov	ss:[lineY2], dx

		; get coords in sorted order for RectSetup

		cmp	ax, cx
		jle	VDL_noSwitchX
		xchg	ax, cx
VDL_noSwitchX:
		cmp	bx, dx
		jle	VDL_noSwitchY
		xchg	bx, dx
VDL_noSwitchY:
		mov	di, cx
		sub	di, ax		
		mov	ss:[d_dx], di		; d_dx = ABS(x2-x1)
		mov	di, dx
		sub	di, bx	
		mov	ss:[d_dy], di		; d_dy = ABS(y2-y1)

		; do standard setup and clipping checks
		
		call	RectSetupFar		;returns routine to use in si
		jc	VDL_allDone
		mov	dx, cs
		mov	cx, offset DrawRectDDA ; dx:si -> routine to call
		clr	al			; draw first pixel
		call	VidLineDDA		; do it

		; all done with line drawing, exit
VDL_allDone:

NMEM <	cmp	ss:[xorHiddenFlag],0	;check for ptr hidden.	>
NMEM <	jz	noRedrawXOR		;go and redraw it if it was hidden.>
NMEM <	call	ShowXORFar					>
NMEM <noRedrawXOR:						>

NMEM <		cmp	ss:[hiddenFlag],0			>
NMEM <		jnz	VDL_redraw				>
NMEM <VDL_afterRedraw:						>
		pop	es			; pushed by RectSetup
		pop	ds
		ret

		; special case: must redraw pointer
NMEM <VDL_redraw:						>
NMEM <		call	CondShowPtrFar				>
NMEM <		jmp	short VDL_afterRedraw			>

VidDrawLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawRectDDA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	callback routine for VidDrawLine

CALLED BY:	VidLineDDA
PASS:		ax,bx,cx,dx	- rect coords
		si		- routine to call in dgroup (from RectSetup)
RETURN:		nothing
DESTROYED:	ax,bx,cx,dx,bp

PSEUDO CODE/STRATEGY:
		Setup the proper parameters for the rect routine and call
		into dgroup

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	11/13/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawRectDDA		proc	far
		push	si
		mov	bp, dx			; calc #scan lines high
		sub	bp, bx
		inc	bp			; bp = #scans high
		mov	di, cx			; di = x2
		xchg	ax, si			; si = x1, ax = routine offset
		call	DrawRectFront
		pop	si
		ret
DrawRectDDA		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidPolyline
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a series of connected lines

CALLED BY:	GLOBAL

PASS:		bx:si	- fptr to disjoint polyline coordinates
		ah	- brush height (pixels)
		al	- brush width (pixels)
		ds	- GState
		es	- Window

RETURN:		nothing

DESTROYED:	everything

PSEUDO CODE/STRATEGY:
		just repeatedly call DrawLine.  

		The buffer passed is set up in "Separator" format.  The 
		constant SEPARATOR (8000h, defined in vidcomConstant.def) is
		used to separate disjoint polylines.  Two SEPARATORs in a row
		mark the end of the buffer.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

		There are some random lines in this routine that are commented
		out.  If put back in, then they could implement a version of 
		this routine where an optional point count was passed in cx.
		This would allow the calling function to use the separator 
		format, or not. (jim 2/18/92)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	11/14/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VidPolyline	proc	far
		.enter

		; store away the brush size

		sub	ax, 101h		; dec both width/height
		jns	haveBrushHeight		; allow zero size
		clr	ah
haveBrushHeight:
		tst	al
		jns	haveBrushSize
		clr	al
haveBrushSize:
		mov	cs:[PRD_incWidth], al	; bump width
		mov	cs:[PRD_incHeight], ah	; bump height
		mov	cs:[VP_incWidth], al	
		mov	cs:[VP_incHeight], ah	
		mov	cs:[VP_pointBuf], bx	; save segment address of buf
		clr	cs:VDL_skip1st		; draw first pixel
		mov	dx, ds			; save GState pointer
		mov	ds, bx			; init lineX2 and lineY2 with
		lodsw				;  first point
		mov	ss:[lineX2], ax
		lodsw
		mov	ss:[lineY2], ax
		mov	ds, dx			; restore GState segment
;		tst	cx			; see if using separator fmt
;		jnz	lineLoop		
;		mov	cx, 0xffff		; else simulate with large #

		; cycle through all the points...
lineLoop:
;		push	cx			; save point count
		mov	bx, ds			; save GState segment

	;
	;  The following *seemingly* worthless jmp has been added to clear
	;  the prefetch queue, which was beating the self-modifying line
	;  to the punch.
	;

		jmp	selfModifyingCodeReallySucks

selfModifyingCodeReallySucks:
VP_pointBuf equ (this word) + 1
		mov	ax, 1234h		; load up buffer segment
		mov	ds, ax			; ds -> point buffer

		; load up next coords, check for buffer end or disjoint part
loadNextCoord:
		lodsw				; get next point
		cmp	ax, SEPARATOR		; is it a separator ? 
		je	foundSeparator
		mov	cx, ax			; save X2
		xchg	ax, ss:[lineX2]		;  no, set up as 2nd point
		mov	ss:[lineX1], ax		; old X2 becomes new X1
		lodsw
		mov	dx, ax			; save Y2
		xchg	ax, ss:[lineY2]
		mov	ss:[lineY1], ax
		mov	ds, bx			; restore GState

		; get coordinates to do rectangle check

		mov	bx, ax			; save endpoints
		mov	ax, ss:[lineX1]

		; get coords in sorted order for RectSetup

		cmp	ax, cx
		jle	VDL_noSwitchX
		xchg	ax, cx
VDL_noSwitchX:
		cmp	bx, dx
		jle	VDL_noSwitchY
		xchg	bx, dx
VDL_noSwitchY:
VP_incWidth equ (this byte) + 2
		add	cx, 0012h
VP_incHeight equ (this byte) + 2
		add	dx, 0012h
		mov	di, cx
		sub	di, ax		
		mov	ss:[d_dx], di		; d_dx = ABS(x2-x1)
		mov	di, dx
		sub	di, bx	
		mov	ss:[d_dy], di		; d_dy = ABS(y2-y1)

		; do standard setup and clipping checks
		
		push	si			; save buffer offset
		mov	si, offset GS_lineAttr	; use line attributes
		call	RectSetupFar		;returns routine to use in si
		jc	nextLine
		mov	dx, cs
		mov	cx, offset PolyRectDDA  ; dx:cx -> routine to call
VDL_skip1st equ (this byte) + 1
		mov	al, 12h			; 1 to skip first pixel in line
		call	VidLineDDA		; do it
		mov	cs:VDL_skip1st, 1	; skip 1st pixel on next line
nextLine:
		pop	es			; pushed by RectSetup
		pop	ds
		pop	si			; restore buffer offset
;		pop	cx			; restore point count
;		loop	lineLoop		; 
		jmp	lineLoop

		; all done with line drawing, exit
done:
NMEM <	cmp	ss:[xorHiddenFlag],0	;check for ptr hidden.	>
NMEM <	jz	noRedrawXOR		;go and redraw it if it was hidden.>
NMEM <	call	ShowXORFar					>
NMEM <noRedrawXOR:						>

NMEM <		cmp	ss:[hiddenFlag],0			>
NMEM <		jnz	VDL_redraw				>
NMEM <VDL_afterRedraw:						>
		.leave
		ret

		; found a SEPARATOR constant in the bunch.  If another, all 
		; done.  else act reset all as if we're starting out fresh
foundSeparator:
		lodsw					; check for 2nd SEP
		cmp	ax, SEPARATOR			; done ?
		jne	newLines
		mov	ds, bx				; restore GState
;		pop	cx				; restore bogus count
		jmp	done
newLines:
		clr	cs:[VDL_skip1st]		; draw first pixel
		mov	ss:[lineX2], ax
		lodsw
		mov	ss:[lineY2], ax
		jmp	loadNextCoord
		
		; special case: must redraw pointer
NMEM <VDL_redraw:						>
NMEM <		call	CondShowPtrFar				>
NMEM <		jmp	short VDL_afterRedraw			>

VidPolyline	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PolyRectDDA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function for VidPolyline

CALLED BY:	DDA_X and DDA_Y

PASS:		ax,bx,cx,dx	- rect coords to draw

RETURN:		nothing

DESTROYED:	everything

PSEUDO CODE/STRATEGY:
		draw the next segment of the polyline

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	11/14/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PolyRectDDA	proc	far
		uses	si
		.enter

		mov	bp, dx			; calc #scan lines high
		sub	bp, bx
		inc	bp			; bp = #scans high
		mov	di, cx			; di = x2
		xchg	ax, si			; si = x1, ax = routine offset
		
		; adjust the rectangle size for the pen width and height

PRD_incWidth equ (this byte) + 2
		add	di, 0012h		; adjust right side for brush
PRD_incHeight equ (this byte) + 2
		add	bp, 0012h		; adjust #scans for brush size

		call	DrawRectFront
CASIO <		push	dx						>
CASIO <		mov	dx, {word} ss:[currentDrawMode] 		>
CASIO <		call	SetCasioModeFar					>
CASIO <		pop	dx						>
		.leave
		ret
PolyRectDDA	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidDashLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a dashed line

CALLED BY:	GLOBAL
PASS:           bx:dx	- fptr to DashInfo
	
				DashInfo	struct
				    DI_pt1	Point <>	; 1st endpoint
				    DI_pt2	Point <>	; 2nd endpoint
				    DI_patt	fptr.DashPairArray ; patt def
				    DI_pattIdx	byte		; patt offset
				    DI_nPairs	byte		; #dash pairs
				DashInfo	ends

		al	- flag to include the first pixel or not 
				(0 = include it.  1 = don't include it)
		si	- offset into GState to CommonAttr
		ds	- gstate
		es	- window
RETURN:         es	- window (may have moved)
		In addition, the DI_pattIdx field is modified to 
		reflect where the dashing code left off at the end
		of the line.
DESTROYS:       ax,bx,cx,dx,si,di,bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	3/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExtDashInfo	struct
    EDI_dash	DashInfo
    EDI_size	WWFixed		; overall size of pattern
    EDI_bIndex	word		; byte index into pattern
    EDI_pIndex	word		; pixel index into current record
    EDI_error	WWFixed		; accumulated error over dashes
    EDI_poly1	Point		; points to pass to Polygon routine
    EDI_poly2	Point		;  (these are used for DashFill, not
    EDI_poly3	Point		;   DashLine)
    EDI_poly4	Point		;
ExtDashInfo	ends

VidDashLine	proc	far
lineInfo	local	ExtDashInfo

		; see if the line is solid (no pattern).  If that is the case,
		; just call the regular line routine.

		push	ds			; save GState pointer
		xchg	bx, dx			; dx:bx -> Dash Info
		mov	ds, dx			; ds:bx -> Dash Info
		tst	ds:[bx].DI_patt.segment	; if zero, no pattern
		jnz	realPattern

		; it's a solid line.  So just load up the coords and call line

		mov	ax, ds:[bx].DI_pt1.P_x	; load up coordinates
		mov	cx, ds:[bx].DI_pt2.P_x
		mov	dx, ds:[bx].DI_pt2.P_y
		mov	bx, ds:[bx].DI_pt1.P_y
		pop	ds			; restore GState
		jmp	VidDrawLine		; 

		; save coordinates
realPattern:
		pop	ds			; restore stack
		.enter
		push	dx, bx			; save pointer to orig struct
		push	ds
		mov	ds, dx			
		xchg	bx, si			; ds:si -> DashInfo
		mov	cx, size DashInfo
		push	es			; save Window
		segmov	es, ss, di		; es:di -> structure on stack
		lea	di, lineInfo.EDI_dash
		rep	movsb			; copy structure to local stack
		pop	es			; restore Window
		pop	ds			; restore GState

		; set up as if for DrawLine

		mov	cs:[firstPixelFlag], al	; save first pixel flag
		mov	si, bx			; restore attributes pointer
		mov	ax, lineInfo.EDI_dash.DI_pt1.P_x
		mov	ss:[lineX1], ax
		mov	bx, lineInfo.EDI_dash.DI_pt1.P_y
		mov	ss:[lineY1], bx
		mov	cx, lineInfo.EDI_dash.DI_pt2.P_x
		mov	ss:[lineX2], cx
		mov	dx, lineInfo.EDI_dash.DI_pt2.P_y
		mov	ss:[lineY2], dx

		; get coords in sorted order for RectSetup

		cmp	ax, cx
		jle	VDL_noSwitchX
		xchg	ax, cx
VDL_noSwitchX:
		cmp	bx, dx
		jle	VDL_noSwitchY
		xchg	bx, dx
VDL_noSwitchY:
		mov	di, cx
		sub	di, ax		
		mov	ss:[d_dx], di		; d_dx = ABS(x2-x1)
		mov	di, dx
		sub	di, bx	
		mov	ss:[d_dy], di		; d_dy = ABS(y2-y1)

		; do standard setup and clipping checks
		
		mov	ss:[saveBP], bp
		call	RectSetupFar		; returns routine to use in si
		mov	bp, ss:[saveBP]
		jc	VDL_allDone
		mov	dx, cs
		mov	cx, offset DashLineDDA 	; dx:cx -> routine to call
		lea	di, lineInfo		; pass pointer to structure
firstPixelFlag	equ	(this byte) + 1
		mov	al, 12h			; load up flag
		call	InitDashPattern		; compute total length
		call	VidLineDDA		; do it
		mov	bp, ss:[saveBP]

		; all done with line drawing, exit

VDL_allDone:
NMEM <	cmp	ss:[xorHiddenFlag],0	;check for ptr hidden.	>
NMEM <	jz	noRedrawXOR		;go and redraw it if it was hidden.>
NMEM <	call	ShowXORFar					>
NMEM <noRedrawXOR:						>

NMEM <		cmp	ss:[hiddenFlag],0			>
NMEM <		jz	VDL_afterRedraw				>
NMEM <		call	CondShowPtrFar				>
NMEM <VDL_afterRedraw:						>

		pop	es			; pushed by RectSetup
		pop	ds

		; update the line pattern index in the passed structure

		mov	dx, es
		pop	es, di			; es:di -> orig Dash struct
		mov	ax, lineInfo.EDI_dash.DI_pattIdx
		mov	es:[di].DI_pattIdx, ax	; save new index
		mov	es, dx			; restore es

		.leave
		ret
VidDashLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DashLineDDA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Does the actual dashing of the line.

CALLED BY:	INTERNAL
		VidLineDDA
PASS:		ax,bx,cx,dx	- bounds of rectangle to draw (if all solid)
		ss:di		- offset to ExtDashInfo structur
		si		- rectangle routine offset
RETURN:		nothing
DESTROYED:	

PSEUDO CODE/STRATEGY:
		The rectangle coords that are passed are actually a 
		horizontal or vertical line.
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

	register usage:
		ax = current x/y value
		cx = current x/y goal value
		dx = #pixels left to do

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	3/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DashLineDDA	proc	far

		; go different ways depending on if it's horiz or vert

		cmp	bx, dx			; if not equal, it's vertical
		jne	vertical

		; it's horizontal, so bx=dx.  use dx for length of line.
		; and save bx for later
	
		mov	dx, cx
		sub	dx, ax
		inc	dx			; dx = length of horiz line
		tst	ss:[signX]		; see if we need to flip them
		js	horizLeft
		mov	cs:[rightYPos], bx
rightLoop:
		call	NextPatternRun
		jnz	bumpRight
		
		; OK, we need to draw something

		push	ax,bx,cx,dx,si,di
		mov	di, ax			; setup rect bounds
		add	di, bx
		mov	bp, 1
rightYPos	equ 	(this word) + 1
		mov	bx, 1234h		
		xchg	ax, si			; ax = routine, si = left 
		call	DrawRectFront
		pop	ax,bx,cx,dx,si,di
bumpRight:
		add	ax, bx
		tst	dx			; go until no more to do
		jnz	rightLoop

		ret
		
horizLeft:
		xchg	ax, cx
		mov	cs:[leftYPos], bx
leftLoop:
		call	NextPatternRun
		jnz	bumpLeft
		
		; OK, we need to draw something

		push	ax,bx,cx,dx,si,di
		mov	di, ax			; setup rect bounds
		sub	ax, bx
		mov	bp, 1
leftYPos	equ 	(this word) + 1
		mov	bx, 1234h		
		xchg	ax, si			; ax = routine, si = left 
		call	DrawRectFront
		pop	ax,bx,cx,dx,si,di
bumpLeft:
		sub	ax, bx
		tst	dx			; go until no more to do
		jnz	leftLoop
		ret
		
		; it's vertical, so ax=cx.  use cx for length of line
vertical:
		mov	cx, dx
		sub	cx, bx
		inc	cx			; cx = vertical line length
		xchg	cx, dx			; dx = line length, cx = y2
		tst	ss:[signY]		; see if we need to flip them
		js	vertUp
		mov	cs:[downXPos], ax
		mov	ax, bx			; set ax/cx = y1/y2

		; we're going to loop around, calling the rect fill for each
		; tiny piece.
downLoop:
		call	NextPatternRun		; carry set if no draw 
		jnz	bumpDown
		
		; OK, we need to draw something

		push	ax,bx,cx,dx,si,di
		tst	bx
		jnz	haveBX
		inc	bx
haveBX:
		mov	bp, bx
		mov	bx, ax			; setup rect bounds
downXPos	equ	(this word) + 1
		mov	ax, 1234h
		mov	di, ax
		xchg	ax, si			; ax = routine, si = left 
		call	DrawRectFront
		pop	ax,bx,cx,dx,si,di
bumpDown:
		add	ax, bx
		tst	dx
		jnz	downLoop
		ret

vertUp:
		mov	cs:[upXPos], ax
		mov	ax, bx			; set ax/cx = y1/y2
		xchg	ax, cx
upLoop:
		call	NextPatternRun		; carry set if no draw 
		jnz	bumpUp
		
		; OK, we need to draw something

		push	ax,bx,cx,dx,si,di
		tst	bx
		jnz	haveBXUp
		inc	bx
haveBXUp:
		mov	bp, bx
		xchg	bx, ax			; setup rect bounds
		sub	bx, ax
upXPos		equ	(this word) + 1
		mov	ax, 1234h
		mov	di, ax
		xchg	ax, si			; ax = routine, si = left 
		call	DrawRectFront
		pop	ax,bx,cx,dx,si,di
bumpUp:
		sub	ax, bx
		tst	dx
		jnz	upLoop
		ret
DashLineDDA	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitDashPattern
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do some initial figuring.

CALLED BY:	INTERNAL
		VidDashLine
PASS:		DashInfo	- on stack
		
RETURN:		nothing
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	3/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitDashPattern		proc	near
		uses	ds, si, cx, ax, dx
lineInfo	local	ExtDashInfo
		.enter	inherit

		clr	ax				     ; init size
		mov	dx, ax
		movwwf	ss:[lineInfo].EDI_error, dxax	     ; init error
		lds	si, ss:[lineInfo].EDI_dash.DI_patt   ; ds:si -> pattern
		mov	cx, ss:[lineInfo].EDI_dash.DI_nPairs ; cx = loop count
		shl	cx, 1				     ; on/off count
		push	si
sizeLoop:
		addwwf	dxax, ds:[si]
		add	si, size WWFixed
		loop	sizeLoop
		movwwf	ss:[lineInfo].EDI_size, dxax
		pop	si

		; init byte and pixel indices
initIndex:
		cmp	dx, ss:[lineInfo].EDI_dash.DI_pattIdx ; start index
		jbe	indexTooBig			; should be >=

		; go through dash pattern and figure current byte and
		; pixel indices
haveIndex:
		clr	ss:[lineInfo].EDI_bIndex
		mov	cx, ss:[lineInfo].EDI_dash.DI_nPairs ; cx = loop count
		shl	cx, 1
		mov	dx, ss:[lineInfo].EDI_dash.DI_pattIdx
		clr	ax				; dx.ax = total
indexLoop:
		subwwf	dxax, ds:[si]			; in this group ?
		js	foundSection			; this is OK for subwwf
		add	ss:[lineInfo].EDI_bIndex, size WWFixed	; next index
		loop	indexLoop

foundSection:
		addwwf	dxax, ds:[si]			; restore pIndex
		mov	ss:[lineInfo].EDI_pIndex, dx	; save pixel Index
		.leave
		ret

indexTooBig:
		tst	dx				; if zero, OK
		jz	haveIndex
		sub	ss:[lineInfo].EDI_dash.DI_pattIdx, dx ; reduce index
		jmp	initIndex
InitDashPattern		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NextPatternRun
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compute length of next dash (on or off)

CALLED BY:	INTERNAL
		VidDashLine

PASS:		dx		- #pixels left to do
		ss:di		- pointer to ExtDashInfo struct 
RETURN:		dx		- #pixels left after we do bx pixels
		bx		- #pixels to do in this run (always < dx)
		zero		- flag SET   if we should draw it
				       CLEAR if we should skip this distance
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	3/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NextPatternRun proc	near
		uses	ds, si, ax, cx
		.enter	

		mov	bx, ss:[di].EDI_bIndex	; get byte index
		lds	si, ss:[di].EDI_dash.DI_patt
		movwwf	cxax, ds:[si][bx]	; #pixs in this stretch
		addwwf	cxax, ss:[di].EDI_error ; add in error accumulated
		sub	cx, ss:[di].EDI_pIndex	; #left to do
		cmp	dx, cx			; just one dash ?
		jae	finishCurrent		;  yes, handle it
		add	ss:[di].EDI_pIndex, dx	; bump pixel index
		add	ss:[di].EDI_dash.DI_pattIdx, dx	; keep this up to date
		test	bx, 4			; set zero flag
		mov	bx, dx			; do this many
		mov	dx, 0			; none left after this

		.leave
		ret

finishCurrent:
		mov	ss:[di].EDI_error.WWF_frac, ax	; save new error value
		clr	ss:[di].EDI_error.WWF_int
		clr	ss:[di].EDI_pIndex	; start at beg of next
		add	ss:[di].EDI_bIndex, size WWFixed ; onto next index
		sub	dx, cx			; fewer to do
		xchg	cx, bx			; bx = # to do, cx = bIndex
		mov	si, bx			; get # going to do
		add	si, ss:[di].EDI_dash.DI_pattIdx
		mov	ss:[di].EDI_dash.DI_pattIdx, si ; update index
		sub	si, ss:[di].EDI_size.WWF_int
		js	wrappedIfNeeded
		clr	ss:[di].EDI_bIndex	; back to first byte
		clr	ss:[di].EDI_dash.DI_pattIdx
wrappedIfNeeded:
		test	cx, 4			; set zero flag
		.leave
		ret
NextPatternRun endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidDashFill
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a fat dashed line

CALLED BY:	GLOBAL
PASS:           bx:dx	- fptr to DashInfo
		si	- offset into GState to CommonAttr
		ds	- gstate
		es	- window
		ax	- x displacement
		cx	- y displacement
RETURN:         es	- window (may have moved)
		In addition, the DI_pattIdx field is modified to 
		reflect where the dashing code left off at the end
		of the line.
DESTROYS:       ax,bx,cx,dx,si,di,bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	3/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VidDashFill	proc	far
lineInfo	local	ExtDashInfo

		.enter

		; see if the line is solid (no pattern).  If that is the case,
		; just call the polygon routine

		push	ds			; save GState pointer
		xchg	bx, dx			; dx:bx -> Dash Info
		mov	ds, dx			; ds:bx -> Dash Info
		tst	ds:[bx].DI_patt.segment	; if zero, no pattern
		jnz	realPattern

		; it's a solid line.  So just load up the coords and call pgon

		mov	dx, ds:[bx].DI_pt1.P_x	; load up coordinates
		mov	lineInfo.EDI_poly1.P_x, dx
		add	dx, ax			; add x displacement
		mov	lineInfo.EDI_poly4.P_x, dx
		mov	dx, ds:[bx].DI_pt2.P_x
		mov	lineInfo.EDI_poly2.P_x, dx
		add	dx, ax			; add x displacement
		mov	lineInfo.EDI_poly3.P_x, dx
		mov	dx, ds:[bx].DI_pt1.P_y
		mov	lineInfo.EDI_poly1.P_y, dx
		add	dx, cx			; add y displacement
		mov	lineInfo.EDI_poly4.P_y, dx
		mov	dx, ds:[bx].DI_pt2.P_y
		mov	lineInfo.EDI_poly2.P_y, dx
		add	dx, bx			; add y displacement
		mov	lineInfo.EDI_poly3.P_y, dx
		pop	ds			; restore GState
		mov	cx, 4			; passing 4 points
		clr	al			; always draw it
		mov	bx, ss			; pass pointer oin bx:dx
		lea	dx, ss:lineInfo.EDI_poly1 ; pass pointer to first point
		call	VidPolygon		; fill the polygon
		.leave
		ret

		; save coordinates
realPattern:
		pop	ds			
		push	dx, bx			; save pointer to orig struct
		push	ds
		mov	ds, dx
		xchg	bx, si			; ds:si -> DashInfo
		mov	cx, size DashInfo
		push	es			; save Window
		segmov	es, ss, di		; es:di -> structure on stack
		lea	di, lineInfo.EDI_dash
		rep	movsb			; copy structure to local stack
		pop	es			; restore Window
		pop	ds			; restore GState

		; set up as if for DrawLine.  Store some of the values for
		; use later

		mov	si, bx			; restore attributes pointer

		mov	cs:[xOffFill], ax	; store in callback routine
		mov	cs:[yOffFill], cx
		mov	cs:[gstateSeg], ds
		mov	cs:[winSeg], es

		mov	ax, lineInfo.EDI_dash.DI_pt1.P_x
		mov	ss:[lineX1], ax
		mov	bx, lineInfo.EDI_dash.DI_pt1.P_y
		mov	ss:[lineY1], bx
		mov	cx, lineInfo.EDI_dash.DI_pt2.P_x
		mov	ss:[lineX2], cx
		mov	dx, lineInfo.EDI_dash.DI_pt2.P_y
		mov	ss:[lineY2], dx
		clr	ss:lineInfo.EDI_poly3.P_x 	; clear flag we use to 
							; indicate that the 
							; setting of coords for
							; the polygon are in 
							; progress (this is 
							; used in the callback
							; routine below)

		; get coords in sorted order for RectSetup

		cmp	ax, cx
		jle	VDF_noSwitchX
		xchg	ax, cx
VDF_noSwitchX:
		cmp	bx, dx
		jle	VDF_noSwitchY
		xchg	bx, dx
VDF_noSwitchY:
		mov	di, cx
		sub	di, ax		
		mov	ss:[d_dx], di		; d_dx = ABS(x2-x1)
		mov	di, dx
		sub	di, bx	
		mov	ss:[d_dy], di		; d_dy = ABS(y2-y1)

		; do standard setup and clipping checks
		
		mov	dx, cs
		mov	cx, offset DashFillDDA 	; dx:cx -> routine to call
		lea	di, lineInfo		; pass pointer to structure
		mov	al, 0			; always do first pixel
		call	InitDashPattern		; compute total length
		call	VidLineDDA		; do it
		mov	bp, ss:[saveBP]

		; all done with line drawing, exit

NMEM <	cmp	ss:[xorHiddenFlag],0	;check for ptr hidden.	>
NMEM <	jz	noRedrawXOR		;go and redraw it if it was hidden.>
NMEM <	call	ShowXORFar					>
NMEM <noRedrawXOR:						>

NMEM <		cmp	ss:[hiddenFlag],0			>
NMEM <		jz	VDF_afterRedraw				>
NMEM <		call	CondShowPtrFar				>
NMEM <VDF_afterRedraw:						>

		; update the line pattern index in the passed structure

		mov	dx, es
		pop	es, di			; es:di -> orig Dash struct
		mov	ax, lineInfo.EDI_dash.DI_pattIdx
		mov	es:[di].DI_pattIdx, ax	; save new index
		mov	es, dx			; restore es

		.leave
		ret
VidDashFill	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DashFillDDA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine for Dashed Filled Lines

CALLED BY:	INTERNAL
		VidLineDDA
PASS:		ax,bx,cx,dx	- bounds of rectangle for this line segment
		ss:di		- pointer to ExtDashInfo struct
		si		- attributes pointer into GState
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	3/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DashFillDDA		proc	far

		; go different ways depending on if it's horiz or vert

		cmp	bx, dx			; if not equal, it's vertical
		LONG jne	vertical

		; it's horizontal, so bx=dx.  use dx for length of line.
		; and save bx for later
	
		mov	dx, cx
		sub	dx, ax
		inc	dx			; dx = length of horiz line
		mov	ss:[di].EDI_poly2.P_y, bx
		tst	ss:[signX]		; see if we need to flip them
		js	horizLeft
rightLoop:
		call	NextPatternRun
		jnz	bumpRightClear
		
		; OK, we need to draw something

		add	ax, bx
		mov	ss:[di].EDI_poly2.P_x, ax
		sub	ax, bx
		tst	ss:[di].EDI_pIndex	; if zero, at end of run
		jnz	notYetRight
		call	DrawDashPoly
		jmp	bumpRightClear
notYetRight:
		tst	ss:[di].EDI_poly3.P_x	; if in progress, but no done
		jnz	bumpRight		;   then continue
		mov	ss:[di].EDI_poly1.P_x, ax
		mov	cx, ss:[di].EDI_poly2.P_y ; store y coord too
		mov	ss:[di].EDI_poly1.P_y, cx
		mov	ss:[di].EDI_poly3.P_x, 1  ; set in-progress flag 
bumpRightClear:
		clr	ss:[di].EDI_poly3.P_x	; clear in progress flag
bumpRight:
		add	ax, bx
		tst	dx			; go until no more to do
		jnz	rightLoop

		ret
		
horizLeft:
		xchg	ax, cx
leftLoop:
		call	NextPatternRun
		jnz	bumpLeftClear
		
		; OK, we need to draw something

		sub	ax, bx
		mov	ss:[di].EDI_poly2.P_x, ax
		add	ax, bx			; restore ax
		tst	ss:[di].EDI_pIndex	; if zero, at end of run
		jnz	notYetLeft
		call	DrawDashPoly
		jmp	bumpLeftClear
notYetLeft:
		tst	ss:[di].EDI_poly3.P_x	; if in progress, but no done
		jnz	bumpLeft		;   then continue
		mov	ss:[di].EDI_poly1.P_x, ax
		mov	cx, ss:[di].EDI_poly2.P_y ; store y coord too
		mov	ss:[di].EDI_poly1.P_y, cx
		mov	ss:[di].EDI_poly3.P_x, 1  ; set in-progress flag 
bumpLeftClear:
		clr	ss:[di].EDI_poly3.P_x	; clear in progress flag
bumpLeft:
		sub	ax, bx
		tst	dx			; go until no more to do
		jnz	leftLoop
		ret
		
		; it's vertical, so ax=cx.  use cx for length of line
vertical:
		mov	cx, dx
		sub	cx, bx
		inc	cx			; cx = vertical line length
		xchg	cx, dx			; dx = line length, cx = y2
		mov	ss:[di].EDI_poly2.P_x, ax
		tst	ss:[signY]		; see if we need to flip them
		js	vertUp
		mov	ax, bx			; set ax/cx = y1/y2

		; we're going to loop around, calling the rect fill for each
		; tiny piece.
downLoop:
		call	NextPatternRun		; carry set if no draw 
		jnz	bumpDownClear
		
		; OK, we need to draw something

		push	bx
		tst	bx
		jnz	haveBX
		inc	bx
haveBX:
		add	ax, bx			  ; calc y2
		mov	ss:[di].EDI_poly2.P_y, ax ; store it
		sub	ax, bx
		tst	ss:[di].EDI_pIndex	; if zero, at end of run
		pop	ax, bx
		jnz	notYetDown
		call	DrawDashPoly
		jmp	bumpDownClear
notYetDown:
		tst	ss:[di].EDI_poly3.P_x	; if in progress, but no done
		jnz	bumpDown		;   then continue
		mov	ss:[di].EDI_poly1.P_y, ax
		mov	cx, ss:[di].EDI_poly2.P_x ; store y coord too
		mov	ss:[di].EDI_poly1.P_x, cx
		mov	ss:[di].EDI_poly3.P_x, 1  ; set in-progress flag 
bumpDownClear:
		clr	ss:[di].EDI_poly3.P_x	; clear in-progress flag
bumpDown:
		add	ax, bx
		tst	dx
		jnz	downLoop
		ret

vertUp:
		mov	ax, bx			; set ax/cx = y1/y2
		xchg	ax, cx
upLoop:
		call	NextPatternRun		; carry set if no draw 
		jnz	bumpUpClear
		
		; OK, we need to draw something

		push	bx
		tst	bx
		jnz	haveBXUp
		inc	bx
haveBXUp:
		sub	ax, bx
		mov	ss:[di].EDI_poly2.P_y, ax ; store it
		add	ax, bx			; restore ax
		tst	ss:[di].EDI_pIndex	; if zero, at end of run
		pop	bx
		jnz	notYetUp
		call	DrawDashPoly
		jmp	bumpUpClear
notYetUp:
		tst	ss:[di].EDI_poly3.P_x	; if in progress, but no done
		jnz	bumpUp			;   then continue
		mov	ss:[di].EDI_poly1.P_y, ax
		mov	cx, ss:[di].EDI_poly2.P_x ; store y coord too
		mov	ss:[di].EDI_poly1.P_x, cx
		mov	ss:[di].EDI_poly3.P_x, 1  ; set in-progress flag 
bumpUpClear:
		clr	ss:[di].EDI_poly3.P_x	; clear in-progress flag
bumpUp:
		sub	ax, bx
		tst	dx
		jnz	upLoop
		ret
DashFillDDA		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawDashPoly
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill a polygon from the DashFill code

CALLED BY:	INTERNAL
		DashFillDDA
PASS:		ss:di	- ExtDashInfo struct
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	3/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawDashPoly	proc	near
		uses	ax, ds, es, dx, bx, cx, di, bp, si
		.enter

xOffFill	equ	(this word) + 1		; displacement to other points
		mov	ax, 1234h
		mov	bx, ss:[di].EDI_poly1.P_x
		add	bx, ax
		mov	ss:[di].EDI_poly4.P_x, bx
		mov	bx, ss:[di].EDI_poly2.P_x
		add	bx, ax 
		mov	ss:[di].EDI_poly3.P_x, bx
yOffFill	equ	(this word) + 1		; displacement to other points
		mov	ax, 1234h
		mov	bx, ss:[di].EDI_poly1.P_y
		add	bx, ax
		mov	ss:[di].EDI_poly4.P_y, bx
		mov	bx, ss:[di].EDI_poly2.P_y
		add	bx, ax 
		mov	ss:[di].EDI_poly3.P_y, bx
gstateSeg	equ	(this word) + 1
		mov	ax, 1234h		; load up GState segment addr
		mov	ds, ax
winSeg		equ	(this word) + 1
		mov	ax, 1234h		; load up Window segment addr
		mov	es, ax
		mov	bx, ss			; bx:dx -> points
		lea	dx, ss:[di].EDI_poly1
		mov	cx, 4			; 4 points
		clr	al			; always draw the polygon
		call	VidPolygon		; do it
		mov	cs:[winSeg], es		; may have moved
		.leave
		ret
DrawDashPoly	endp

VidEnds	Line




