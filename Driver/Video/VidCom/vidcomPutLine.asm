COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Video Drivers
FILE:		vidcomPutLine.asm

AUTHOR:		Jim DeFrisco

ROUTINES:
	Name			Description
	----			-----------
   GBL	VidPutLine		Draw a bitmap scan line
   INT	PutLineX		Support routine for VidDrawLine
   INT	PutLineY		Support routine for VidDrawLine

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	12/88		Initial revision


DESCRIPTION:
	This file contains the line routine common to all video drivers.
	
	$Id: vidcomPutLine.asm,v 1.1 97/04/18 11:41:56 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VidSegment	PutLine	


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidPutLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put bits along a line

CALLED BY:	GLOBAL

PASS:		ax,bx	- x1,y1
		cx,dx	- x2,y2
		ss:bp 	- pointer to inherited PutBitsArgs structure 

			  PutBitsArgs	struct
			      PBA_bm	Bitmap <> ; header for part to draw
			      PBA_data	fptr	  ; far pointer to bitmap data
			      PBA_size	word	  ; scan line size (#bytes)
			  PutBitsArgs	ends

		ds - graphics state
		es - Window struct

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,si,di,bp

PSEUDO CODE/STRATEGY:
		if (x1 > x2)
		   reverse the buffer content;
		Use regular drawLine routine, but use bitmap low-level
		 routines to draw line instead of rectangle low-level routines;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	04/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VidPutLine	proc	far
		uses	ds
bm		local	PutBitsArgs

		mov	ss:[saveBP], bp		; save so we can use it later

		.enter				; inherited on another stack
						;  so we need to allocate space
		; copy the inherited structure to our own stack.

		push	ds			; save GState seg
		mov	ds, ss:[saveSS]		; get old stack segment
		mov	si, ss:[saveBP]		; ds:si -> old ss:bp
		sub	si, size PutBitsArgs	; ds:si -> passed structure
		mov	di, {word} ds:[si].PBA_bm.B_compact
		mov	{word} bm.PBA_bm.B_compact, di
		mov	di, ds:[si].PBA_data.offset
		mov	bm.PBA_data.offset, di
		mov	di, ds:[si].PBA_data.segment
		mov	bm.PBA_data.segment, di
		mov	di, ds:[si].PBA_size
		mov	bm.PBA_size, di
		mov	ss:[d_bytes], di
		mov	di, ds:[si].PBA_bm.B_width ; copy header
		mov	bm.PBA_bm.B_width, di
		mov	di, ds:[si].PBA_bm.B_height
		mov	bm.PBA_bm.B_height, di
		mov	di, ds:[si].PBA_flags
		mov	bm.PBA_flags, di
		mov	ss:[bmArgs], bp		; save ptr to args
		mov	di, ds:[si].PBA_pal.offset	; copy pointer
		mov	ss:bm.PBA_pal.offset, di
		mov	di, ds:[si].PBA_pal.segment
		mov	ss:bm.PBA_pal.segment, di

		; fix up coords so that ax=left, bx=top, cx=right, dx=bottom

		mov	ss:[lineX1], ax
		mov	ss:[lineY1], bx
		mov	ss:[lineX2], cx
		mov	ss:[lineY2], dx
		cmp	ax, cx
		jle	VPL_noSwitchX
		xchg	ax, cx
VPL_noSwitchX:
		cmp	bx, dx
		jle	VPL_noSwitchY
		xchg	bx, dx
VPL_noSwitchY:
		mov	ss:[putStart], bx
		mov	ss:[d_x1], ax
		mov	di, cx
		sub	di, ax		
		mov	ss:[d_dx], di		; d_dx = ABS(x2-x1)
		add	di, ax
		mov	ss:[d_x2], di
		mov	di, dx
		sub	di, bx	
		mov	ss:[d_dy], di		; d_dy = ABS(y2-y1)

		; check for collision with pointer and save under area

NMEM <		call	CheckCollisions					>

		; setup any dither required, and a mask

		pop	ds			; ds -> GState
		CheckSetDither ss, GS_areaAttr
		CopyMask	<ds:[GS_areaAttr.CA_mask]>,ax, ss

		; need to set up the draw mode too
ifndef IS_MEGA
BIT <		mov	bl, ss:[currentDrawMode]			>
BIT <		clr	bh						>
BIT <		shl	bx, 1			; set to index into tab	>
BIT <		mov	ax, cs:PLByteModeRout[bx]			>
BIT <		mov	ss:[modeRoutine], ax 				>
ifdef	IS_MONO
BIT <		mov	ax, cs:PLByteMixRout[bx]			>
BIT <		mov	ss:[mixRoutine], ax				>
endif
endif

		; do standard setup and clipping checks
		
		mov	si, bm.PBA_data.offset	; restore si-> bm data
		mov	ds, bm.PBA_data.segment	; set up bitmap segment
		push	es			; save window seg
		SetBuffer es, ax		; es -> frame buffer
		mov	ss:[bmSeg], ds		; save pointers
		mov	ss:[bmLOffset], si	;  to line data
		mov	bx, bm.PBA_bm.B_width	; save away width for later
		mov	ss:[bmWidth], bx	
		mov	bl, bm.PBA_bm.B_type	; get format info
		mov	ss:[bmType], bl		; get format info

		; if there is a mask, calculate the size of it

		clr	ax			; assume no mask
		test	bl, mask BMT_MASK	; check for one
		jz	haveMaskSize
		mov	ax, bm.PBA_bm.B_width	; calc mask size
		add	ax, 7			; round up
		shr	ax, 1			; divide by 8 to get bytes 
		shr	ax, 1
		shr	ax, 1
haveMaskSize:
		mov	ss:[bmMaskSize], ax	; save it

		; if there is a palette, store the address
		
		mov	ss:[bmPalette].segment, ss		; init no pal
ifndef IS_CMYK
ifndef IS_CLR24
		mov	ss:[bmPalette].offset, offset defBitmapPalette
else
		mov	ss:[bmPalette].offset, offset currentPalette
endif
else
		mov	ss:[bmPalette].offset, offset currentPalette
endif
		test	bl,  mask BMT_PALETTE	; check for palette
		jz	getScanRoutine		
		mov	ax, bm.PBA_pal.offset	; copy pointer
		mov	ss:[bmPalette].offset, ax
		mov	ax, bm.PBA_pal.segment
		mov	ss:[bmPalette].segment, ax

		; see which routine to call to xfer bitmap: b/w, color or grey
getScanRoutine:

ifdef IS_CLR24
ifndef IS_DIRECT_COLOR
		call	CalcPalette		; convert 8-bit palette to RGB
endif
endif
		and	bl, mask BMT_FORMAT or mask BMT_MASK

		; for the purposes of looking the proper routine up in the 
		; table, we use the BMT_COMPLEX bit to distinguish between
		; FILL and DRAW...

		test	bm.PBA_flags, mask PBF_FILL_MASK
		jz	getRoutine
		or	bl, mask BMT_COMPLEX
getRoutine:
		clr	bh
		shl	bx, 1
		mov	ax, cs:[putlineTable][bx]
		mov	ss:[putlineRout], ax
		pop	ds			; ds -> window

		; for CMYK vidmem, if we're drawing a color bitmap, lock down
		; a few resources for the duration.

CMYK <		call	CMYKColorBitmapInitFar				>

		; let the new line routine handle Bresenham...

		mov	dx, cs
		mov	cx, offset PutLineDDA
		clr	al			; don't skip first pixel
		call	VidLineDDA		; do it

		; cleanup after CMYK stuff

CMYK <		call	CMYKColorBitmapCleanupFar			>

		; all done with line drawing
		; restore EGA to default state and exit
		; for vidmem, release the final HugeArray block

MEM <		ReleaseHugeArray		; release last block	>

EGA <		mov	dh, C_BLACK		; set color to black	>
EGA <		mov	dl, MM_COPY		; and cody draw mode	>
EGA <		call	SetEGAClrModeFar	; just use a handy funtion >

NIKEC <		mov	dh, C_BLACK		; set color to black	>
NIKEC <		mov	dl, MM_COPY		; and cody draw mode	>
NIKEC <		call	SetNikeClrModeFar	; just use a handy funtion >

		; changed 4/7/93 to make AutoTransfer the default
;CASIO <	CasioAutoXferOff					>

NMEM <		cmp	ss:[xorHiddenFlag],0	;check for ptr hidden.	>
NMEM <		jz	noRedrawXOR	;go and redraw it if it was hidden.>
NMEM <		call	ShowXORFar					>
NMEM <noRedrawXOR:							>
NMEM <		tst	ss:[hiddenFlag]					>
NMEM <		jz	VPL_afterRedraw					>
NMEM <		call	CondShowPtrFar					>
NMEM <VPL_afterRedraw:							>

		segmov	es, ds, ax		; reset window segment
		.leave
		ret

VidPutLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PutLineDDA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine for PutLine

CALLED BY:	VidLineDDA
PASS:		ax,bx,cx,dx	- rect coords
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	11/13/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PutLineDDA	proc	far
		mov	bp, dx			; calc #scan lines high
		sub	bp, bx
		inc	bp			; bp = #scans high
		mov	di, cx			; di = x2
		mov	si, ax			; si = x1
		mov	ax, ss:[d_dy]		; see if we are going vertical
		cmp	ax, ss:[d_dx]		; if more horizontal, use that
		ja	doVertical
		call	PutLineSegX
done:
		ret

		; going more vertical.  call other routine
doVertical:
		call	PutLineSegY
		jmp	done
PutLineDDA	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PutLineSegX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put part of a line segment out, colored from a bitmap

CALLED BY:	INTERNAL
		PutLineX, PutLineY

PASS:		(same as are passed to rect routines)
		si	- left coord of rectangle to fill
		bx	- top coord of rectangle to fill
		di	- right coord of rectangle to fill
		bp	- #scan lines to fill 		   (always==1 here)
		ds	- window
		es	- frame buffer

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,si,di,bp

PSEUDO CODE/STRATEGY:
		translate the input parameters (designed to be passed to a
		rectangle routine) into arguments for a PutXXXScan routine
		(used by the PutBits function) to draw a single scan line
		of a bitmap.  These are:

			d_x1	- left side of full bitmap
			d_x2	- right side of full bitmap
			d_dx	- image width (pixels)
			d_bytes	- image width (bytes)
			ax	- rightmost ON point
			bx	- leftmost ON point
			dx	- index to pattern table
			ds:si	- pointer to bitmap data
			es:di	- frame buffer pointer (start of scan line)

		dx and di have to be calculated, the rest are basically
		hanging around somewhere.  We also have to do the region 
		thing here (i.e. do the clipping).

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	06/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PutLineSegX	proc	near
bm		local	PutBitsArgs
		.enter	inherit			; just so we can access args
		ForceRef bm

		tst	bx			; if negative, bail
		LONG js	PLSX_done
MEM <		cmp	bx, ds:[W_winRect].R_bottom ; if below, bail now >
MEM <		LONG ja PLSX_done					>
						; x1,x2,dx are already set up
		mov	ax, di			; ax = right side coord
		mov	di, bx			; di = scan line
		clr	cx
NMEM <		CalcScanLine di, cx		; es:di - start of scan line >
MEM <		CalcScanLine di,cx,es		; es:di - start of scan line >
MEM <		tst	ss:[bm_lastSeg]		; if lock failed...	>
MEM <		LONG jz PLSX_done					>
		mov	cx, bx			; save scan line in cx
		sub     bx, ds:[W_winRect].R_top ; align patt with top of win
		and     bx, 7                   ; select one of 8 scan lines 
		mov     dx, bx                  ; dx = pattern index
		mov	bx, si			; bx = left side of line
		mov	si, ss:[bmLOffset]	; get pointer to bm data

		; make sure that clip info is correct

		cmp	cx, ds:[W_clipRect].R_bottom ; below definition area ?
		jg	PLSX_setClip
		cmp	cx, ds:[W_clipRect].R_top ; above definition area ?
		jge	PLSX_afterClip

		; special case: must reset clipping region
PLSX_setClip:
		push	ax,bx,si,di
		mov	bx, cx
		call	WinValClipLine
		pop	ax,bx,si,di

		; test for type of clipping region
PLSX_afterClip:
		push	bx			; save reg
		mov	bx, cx			; set up scan line number
MEM <		mov	ss:[bmScan], bx					>
		and	bx, 7			; select one of 8 scan lines
ifndef IS_CLR24
BIT <		mov	cl, byte ptr ss:ditherMatrix[bx] ; get pattern too  >
BIT <		mov	ss:linePatt, cl		; store pattern 	  >
endif
		mov	cl, byte ptr ss:maskBuffer[bx] ; get mask for this line
		tst	cl			;  if NULL, just skip it
		pop	bx			; restore reg
		jz	PLSX_done
		mov	ss:lineMask, cl		; save mask for this line

		mov	cl, ds:[W_grFlags]
		test	cl, mask WGF_CLIP_NULL
		jnz	PLSX_done
		test	cl, mask WGF_CLIP_SIMPLE
		jz	PLSX_notSimple

		; simple clipping region -- call transfer routine
		; we still want to limit the fill to the part of the bitmap
		; inside this simple clip area

		cmp	ax, ss:[d_x1]		; if out of bounds here, skip
		jl	PLSX_done
		cmp	bx, ss:[d_x2]		; if out of bounds here, skip
		jg	PLSX_done
		cmp	bx, ds:[W_clipRect].R_left ; take max of these
		jge	checkRightSide
		mov	bx, ds:[W_clipRect].R_left
checkRightSide:
		cmp	ax, ds:[W_clipRect].R_right ; take min of these
		jle	fillLineSeg
		mov	ax, ds:[W_clipRect].R_right

		; ready to go, but don't do it if the left/right are crossed
fillLineSeg:
ifndef	IS_CLR24
MEM <		call	PrepBitmapDithering				>
endif
		cmp	ax, bx			; if less, skip
		jl	PLSX_done
		push	ds			; save window segment
		mov	ds, ss:[bmSeg]		; set up ds -> bitmap 
		mov	cx, ss:[putlineRout]	; call correct transfer routine
		call	PutScanFront
		pop	ds			; restore window segment
PLSX_done:
MEM <		ReleaseHugeArray		; release last block	>
		.leave
		ret

		; special case: not simple region
		; here ax=right part of line, bx=left part
PLSX_notSimple:
		mov	cx, si
		mov	si, ds:[W_maskReg]
		mov	si, ds:[si]
		add	si,ds:[W_clipPtr]	;test for within clip area
PLSX_nsLoop:
		mov	dx, ds:[si]		; get first on/off point
		cmp	dx, EOREGREC		; see if at end of region
		je	PLSX_done
		cmp	ax, dx			; see if there yet
		jl	PLSX_done		;  nope, skip this part of reg
		cmp	bx, ds:[si+2]		; see if to the right
		jg	PLSX_toTheRight
		cmp	ax, ss:[d_x1]		; if out of bounds here, skip
		jl	PLSX_done
		cmp	ax, ss:[d_x2]		; if out of bounds here, skip
		jg	PLSX_done
		push	ax,bx			; save the endpoints

		; so take the max (left, left) and the min(right,right)
		; (wipe that silly look off your face)

		cmp	bx, dx
		jge	leftOK
		mov	bx, dx
leftOK:
		cmp	ax, ds:[si+2]
		jle	rightOK
		mov	ax, ds:[si+2]
rightOK:
		cmp	ax, bx			; if less, skip
		jl	PLSX_skipDraw

ifndef	IS_CLR24
MEM <		call	PrepBitmapDithering				>
endif

		; need to draw part of this segment
		; bx = left ON point, ax = right ON point

		push	si,di,cx,ds
		mov	si, cx
		mov	ds, ss:[bmSeg]		; set up ds -> bitmap 
		mov	cx, ss:[putlineRout]	; call correct transfer routine
		call	PutScanFront
		pop	si,di,cx,ds
PLSX_skipDraw:
		pop	ax, bx
PLSX_toTheRight:
		add	si, 4
		jmp	PLSX_nsLoop

PutLineSegX	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PutLineSegY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put part of a line segment out, colored from a bitmap

CALLED BY:	INTERNAL
		PutLineX, PutLineY

PASS:		(same as are passed to rect routines)
		si	- left coord of rectangle to fill
		bx	- top coord of rectangle to fill
		di	- right coord of rectangle to fill
		bp	- #scan lines to fill
		ds	- window
		es	- frame buffer

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,si,di,bp

PSEUDO CODE/STRATEGY:
		translate the input parameters (designed to be passed to a
		rectangle routine) into arguments for a PutXXXScan routine
		(used by the PutBits function) to draw a single scan line
		of a bitmap.  These are:

			d_x1	- left side of full bitmap
			d_x2	- right side of full bitmap
			d_dx	- image width (pixels)
			d_bytes	- image width (bytes)
			ax	- rightmost ON point
			bx	- leftmost ON point
			dx	- index to pattern table
			bp	- bitmap data segment
			ds:si	- pointer to bitmap data
			es:di	- frame buffer pointer (start of scan line)

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	06/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
outsideWin	label	near
		neg	bx			; get #scans outside window
		sub	bp, bx			; else make the line shorter
		LONG js PLSY_done		; 
		clr	bx			;  and start at the top
		jmp	PLSY_topHandled

PutLineSegY	proc	near
bm		local	PutBitsArgs
		.enter	inherit			; just so we can access args
		ForceRef bm

		push	ss:[d_dy]		; save since we mess with these
		push	ss:[d_dx]

		tst	si			; if negative, bail
		LONG js	PLSY_done
		tst	bx			; if negative, bail
		LONG js	outsideWin
		cmp	bx, ds:[W_winRect].R_bottom ; if below, bail now 
		LONG ja PLSY_done					

PLSY_topHandled	label	near
		mov	ax, bx			; check bottom inside window
		add	ax, bp
		sub	ax, ds:[W_winRect].R_bottom ; if inside, this negative
		js	oktoDraw
		sub	bp, ax			; adjust #lines to draw
oktoDraw:		
		mov	ax, si			; get curX
		sub	ax, bx			; sub curY
		add	ax, ss:[putStart]	; sub orig y value
		mov	ss:[d_x1], ax		; trust me, this is right
		mov	cx, ss:[bmWidth]	; now calc right side
		mov	ss:[d_dx], cx		; set up for PutScan routine
		add	ax, cx			; calc right side
		dec	ax
		mov	ss:[d_x2], ax		; two down
		mov	ax, si			; restore current x position
		mov	si, ss:[bmLOffset]	; get pointer to data

		; Removed this line as the very last line of rotated bitmaps
		; oriented vertically were not being drawn. -Don 10/18/93
		;
;;;		dec	bp			; really one less. really.

		mov	ss:[d_dy], bp		; save # scans to do
		mov	di, bx			; get scan line in di
		clr	cx			; clear out a reg
NMEM <		CalcScanLine di, cx		; es:di - frame buffer >
NMEM <		jmp	PLSY_start		; enter loop		>
MEM <		CalcScanLine di, cx, es		; es:di - frame buffer >
MEM <		tst	ss:[bm_lastSeg]		; if lock failed...	>
MEM <		jnz	PLSY_start					>
MEM <		jmp	PLSY_done					>

PLSY_loop:
		inc	bx			; on to next scan line
MEM <		mov	ss:[bmScan], bx					>
		NextScan di 			; bump pointer
MEM <		tst	ss:[bm_scansNext]	; if zero, we're done	>
MEM <		LONG js	PLSY_done		; 			>
		dec	ss:[d_x1]		; fix-up to fool putscan
		dec	ss:[d_x2]		; fix-up to fool putscan

		; make sure that clip info is correct
PLSY_start:
		cmp	bx, ds:[W_clipRect].R_bottom ; below definition area ?
		jg	PLSY_setClip
		cmp	bx, ds:[W_clipRect].R_top ; above definition area ?
		jge	PLSY_afterClip

		; special case: must reset clipping region
PLSY_setClip:
		push	ax, si, di
		call	WinValClipLine
		pop	ax, si, di

		; test for type of clipping region
PLSY_afterClip:
		push	bx			; save scan line number
		and	bx, 7			; select one of eight scan lines
		mov	cl, byte ptr ss:maskBuffer[bx] ; get mask for this line
		tst	cl			;  if NULL, just skip it
		jz	PLSY_next
		mov	ss:lineMask, cl		; save mask for this line
ifndef IS_CLR24
BIT <		mov	cl, byte ptr ss:ditherMatrix[bx] ; get pattern too  >
BIT <		mov	ss:linePatt, cl		; store pattern 	  >
endif
		mov	dx, bx			; pass to putscan
		mov	cl, ds:[W_grFlags]
		test	cl, mask WGF_CLIP_NULL
		jnz	PLSY_next
		test	cl, mask WGF_CLIP_SIMPLE
		jz	PLSY_notSimple

		; simple clipping region -- call transfer routine

		cmp	ax, ds:[W_clipRect].R_left ; clip to left and right
		jl	PLSY_next
		cmp	ax, ds:[W_clipRect].R_right
		jg	PLSY_next
		cmp	ax, ss:[d_x1]		; if out of bounds here, skip
		jl	PLSY_next
		cmp	ax, ss:[d_x2]		; if out of bounds here, skip
		jg	PLSY_next
		mov	bx, ax			; left/right are the same

ifndef	IS_CLR24
MEM <		call	PrepBitmapDithering				>
endif

		push	ax,si,di,ds
		mov	ds, ss:[bmSeg]		; load up bitmap segment
		mov	cx, ss:[putlineRout]	; load up routine offset
		call	PutScanFront		; call correct transfer routine
		pop	ax,si,di,ds
PLSY_next:
		pop	bx			; restore scan number
		dec	ss:[d_dy]		; dec scan line count
		LONG jns PLSY_loop	
PLSY_done	label	near
		pop	ss:[d_dx]		; restore trashed values
		pop	ss:[d_dy]
MEM <		ReleaseHugeArray				>
		.leave
		ret

		; special case: not simple region
PLSY_notSimple:
		mov	cx, si
		mov	bx, ax
		mov	si, ds:[W_maskReg]
		mov	si, ds:[si]
		add	si, ds:[W_clipPtr]	;test for within clip area
PLSY_nsLoop:
		mov	dx, ds:[si]		; get first on/off point
		cmp	dx, EOREGREC		; see if at end of region
		je	PLSY_next2
		cmp	ax, dx			; see if there yet
		jl	PLSY_next2		;  nope, skip this part of reg
		cmp	ax, ss:[d_x1]		; if out of bounds here, skip
		jl	PLSY_next2
		cmp	ax, ss:[d_x2]		; if out of bounds here, skip
		jg	PLSY_next2
		cmp	ax, ds:[si+2]		; see if to the right
		jle	foundSection
		add	si, 4			; bump tonext section
		jmp	PLSY_nsLoop

		; need to draw part of this segment
		; bx = left ON point, ax = right ON point
foundSection:
ifndef	IS_CLR24
MEM <		call	PrepBitmapDithering				>
endif

		push	bx,di,cx,ds
		mov	si, cx
		mov	ds, ss:[bmSeg]		; load up bitmap segment
		mov	cx, ss:[putlineRout]	; call correct transfer routine
		call	PutScanFront		; call into Bitmap module
		pop	bx,di,cx,ds
		mov	ax, bx
PLSY_next2:
		mov	si, cx
		jmp	PLSY_next

PutLineSegY	endp


ifdef	IS_MEM
ifndef IS_CLR24

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrepBitmapDithering
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	For vidmem, this sets up proper dithering stuff for bitmap
		drawing

CALLED BY:	INTERNAL
		PutLineSegX, PutLineSegY
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	9/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrepBitmapDithering proc	near
		uses	ax, bx
bm		local	PutBitsArgs					
		.enter	inherit
		ForceRef bm

		mov	ax, ss:[bmLeft]		; set up left..
		mov	bx, ss:[bmScan]		;   ..and scan line
		mov	bp, ss:[bmArgs]		
CMYK <		test	bm.PBA_flags, mask PBF_FILL_MASK		>
CMYK <		jz	colorDither					>
		call	CalcDitherIndices	; calc dither 
CMYK <ditherDone:							>

		.leave
		ret

CMYK <colorDither:							>
CMYK <		call	CalcByteDitherIndices				>
CMYK <		jmp	ditherDone					>
PrepBitmapDithering endp

endif
endif

VidEnds		PutLine	

