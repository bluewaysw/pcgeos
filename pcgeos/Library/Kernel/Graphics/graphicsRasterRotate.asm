COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		Kernel Library
FILE:		graphicsRasterRotate.asm

AUTHOR:		Jim DeFrisco

ROUTINES:
	Name		Description
	----		-----------
   GBL	RotateBlt	Do blt where rotation in effect
   GBL	RotateBitmap	Rotate a bitmap
   GBL	GetBitmap	Copy a bitmap from a device to a memory buffer

   INT	GetBitSizeBlock	Determine block size needed for GetBitmap

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	jad	7/89	initial version


DESCRIPTION:
	This file contains the rotation parts of the kernel raster graphics
	routines.  These will probably eventually be moved to a library.

	$Id: graphicsRasterRotate.asm,v 1.1 97/04/05 01:13:10 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


GraphicsRotRaster segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RotateBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Rotate the passed bitmap. there is no scaling.

CALLED BY:	INTERNAL
		GrDrawBitmap

PASS:		cx	- GState segment
		ss:bp	- pointer to local stack frame for GrDrawBitmap 
			  (see structure, above)
		ds:si	- pointer to bitmap
		es	- window segment

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:
		use bresenham's algorithm to step along one side of the
		bitmap, and call the video driver putline routine to 
		draw each scan of the bitmap along a "scan" of a rotated
		rectangle.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	07/89		Initial version
	Jim	10/89		Real version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RotateBitmap	proc	far
		uses	cx
BMframe		local	BitmapFrame
		.enter	inherit

		; Everything has been pretty much set up for us, so we just 
		; need to implement the loop to "put" each scan of the bitmap
		; Our loop is going to be executed finalBMheight times
		; If the bitmap is complex, then we need to do a slice at a 
		; time.  

		mov	ax, ds:[si].B_height		; grab height
		mov	BMframe.BF_count, ax		; do this many
		mov	BMframe.BF_finalBM.offset, si
		mov	BMframe.BF_finalBM.segment, ds
		mov	BMframe.BF_args.PBA_data.segment, ds 

		test	ds:[si].B_type, mask BMT_COMPLEX ; is it sliced ?
		jnz	sliceLoop

		; if the bitmap has a mask, we want to add in the size of the
		; mask to the data pointer.

		clr	ax			; assume no mask
		test	ds:[si].B_type, mask BMT_MASK
		jz	haveMaskSize
		mov	ax, BMframe.BF_finalBMwidth ; pass width
		add	ax, 7			; round up to byte boundary
		shr	ax, 1			; divide by 8 for mask size
		shr	ax, 1			;  in bytes
		shr	ax, 1 
haveMaskSize:
		add	ax, size Bitmap
		add	ax, si

		mov	BMframe.BF_args.PBA_data.offset, ax ; set data pointer
		mov	ds, cx				; ds -> GState
		mov	ax, BMframe.BF_rotUpLeft.P_x	; get coords of line
		mov	bx, BMframe.BF_rotUpLeft.P_y
		mov	cx, BMframe.BF_rotUpRight.P_x
		mov	dx, BMframe.BF_rotUpRight.P_y
wholeScanLoop:
		mov	di, DR_VID_PUTLINE
		push	ax,bx,cx,dx
		call 	es:[W_driverStrategy]	; call to video driver
		pop	ax,bx,cx,dx
		call	BumpCoords			; bump line coords
		mov	di, BMframe.BF_finalBMscanSize
		add	BMframe.BF_args.PBA_data.offset, di
		dec	BMframe.BF_count		; one less to do
		jnz	wholeScanLoop

		; all done drawing.  Time to go...
done:
		.leave
		ret

handleEmptySlice:
		mov	cx, BMframe.BF_rotUpRight.P_x
		jmp	doneWithSlice
		
		; OK, we have a complex bitmap.  This makes it a little 
		; trickier but not too much.  Just do a slice at a time and
		; callback to get more.
sliceLoop:

		; if the bitmap has a mask, we want to add in the size of the
		; mask to the data pointer.

		clr	ax			; assume no mask
		test	ds:[si].B_type, mask BMT_MASK
		jz	haveMaskSizeToo
		mov	ax, BMframe.BF_finalBMwidth ; pass width
		add	ax, 7			; round up to byte boundary
		shr	ax, 1			; divide by 8 for mask size
		shr	ax, 1			;  in bytes
		shr	ax, 1 
haveMaskSizeToo:
		add	ax, ds:[si].CB_data		; get data offset
		add	ax, si

		mov	BMframe.BF_args.PBA_data.offset, ax  ; set data pointer
		push	ax				; save this
		mov	ax, cx				; ax -> GState
		mov	cx, ds:[si].CB_numScans
		sub	BMframe.BF_count, cx		; fewer to do
		mov	di, cx				; keep loop count in di
		mov	ds, ax				; ds -> GState
		mov	ax, BMframe.BF_rotUpLeft.P_x	; get coords of line
		mov	bx, BMframe.BF_rotUpLeft.P_y
		mov	dx, BMframe.BF_rotUpRight.P_y
		jcxz	handleEmptySlice
		mov	cx, BMframe.BF_rotUpRight.P_x
sliceScanLoop:
		push	di
		mov	di, DR_VID_PUTLINE
		push	ax,bx,cx,dx, ds
		mov	ds, BMframe.BF_gstate		; pass GState seg
		call 	es:[W_driverStrategy]		; call to video driver
		pop	ax,bx,cx,dx, ds
		call	BumpCoords			; advance to next line
		mov	di, BMframe.BF_finalBMscanSize
		add	BMframe.BF_args.PBA_data.offset, di
		pop	di
		dec	di
		jnz	sliceScanLoop

		; done with this slice, check to see if any more to do
doneWithSlice:
		pop	BMframe.BF_args.PBA_data.offset	; restore this pointer
		cmp	BMframe.BF_count, 0	; more to do ?
		jle	done			; no, all done

		; more to do.  Call callback function to get more bitmap
		; first save the current coords for the next slice

		mov	BMframe.BF_rotUpLeft.P_x, ax	; get coords of line
		mov	BMframe.BF_rotUpLeft.P_y, bx
		mov	BMframe.BF_rotUpRight.P_x, cx
		mov	BMframe.BF_rotUpRight.P_y, dx
		mov	di, ds				; save gstate segment
		mov	ds, BMframe.BF_finalBM.segment 	; set up pointer
		mov	si, BMframe.BF_finalBM.offset
getNextSlice:
		call	BMCallBack			; use kernel version
		LONG jc	done
		tst	ds:[si].CB_numScans		; if zero, nothing todo
		jz	getNextSlice
		mov	BMframe.BF_finalBM.segment, ds 	; set up pointer
		mov	BMframe.BF_finalBM.offset, si
		mov	BMframe.BF_args.PBA_data.segment, ds  ; set up pointer
		mov	cx, di				; cx -> GState
		jmp	sliceLoop			; if more to do...
RotateBitmap	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BumpCoords
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bump the endpoints of the line for rotated bitmaps

CALLED BY:	INTERNAL
		RotateBitmap

PASS:		ax,bx	- x,y position of first endpoint
		cx,dx	- x,y position of second endpoint
		BitmapFrame - passed on stack

RETURN:		ax,bx,cx,dx, updated appropriately

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		put pseudo code here

$
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BumpCoords	proc	near
		uses	si,di
BMframe		local	BitmapFrame
		.enter	inherit

		; add in the constant bumps

		add	ax, BMframe.BF_xbump	; add in the x offsets
		add	cx, BMframe.BF_xbump
		add	bx, BMframe.BF_ybump	; add in the y offsets
		add	dx, BMframe.BF_ybump

		; update the curPoint

		movwwf	disi, BMframe.BF_curPoint ; get current value
		addwwf	disi, BMframe.BF_slope
		movwwf	BMframe.BF_curPoint, disi ; update new value

		; see if we're updating x or y

		rndwwf	disi
		tst	BMframe.BF_ybump	; which way are we going ?
		jz	handleYslope		; slope is for updating y

		; update the x position, if necc

		sub	di, ax
		cmp	di, ax			; sub old value from new
		jz	done

		; we're moving diagonally.  This will generally leave a bad
		; set of holes in our image. We do not approve.  Therefore,
		; we re-draw the last scan line to get rid of said holes.

		push	ax,bx,cx,dx,di, ds
		mov	ds, BMframe.BF_gstate		; pass GState seg
		mov	di, DR_VID_PUTLINE
		call 	es:[W_driverStrategy]	; call to video driver
		pop	ax,bx,cx,dx,di, ds
		add	ax, di			; add it in
		add	cx, di			; add it in
done:
		.leave
		ret

		; handle drawing in the x direction
handleYslope:
		sub	di, bx			; sub old value from new
		jz	done

		; we're moving diagonally.  This will generally leave a bad
		; set of holes in our image. We do not approve.  Therefore,
		; we re-draw the last scan line to get rid of said holes.

		push	ax,bx,cx,dx,di, ds
		mov	ds, BMframe.BF_gstate		; pass GState seg
		mov	di, DR_VID_PUTLINE
		call 	es:[W_driverStrategy]	; call to video driver
		pop	ax,bx,cx,dx,di, ds
		add	bx, di			; add it in
		add	dx, di			; add it in
		jmp	done
		
BumpCoords	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcRotatedScaleFactor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate scale factor when rotated

CALLED BY:	INTERNAL
		InitBitmapScale

PASS:		see InitBitmapScale, above

RETURN:		carry	- bitmap is way offscreen.  coordinates overflowed.

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		figure out the scale factor and set the right values in 
		BMframe

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Calc the corners of the rectangle occupied by the bitmap.  Use
		that to figure out the ending size.

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	08/90		Initial version
		Jim	10/90		Updated for arbitrary rotation

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalcRotatedScaleFactor	proc	far
		uses	ax,bx,cx,dx,di
BMframe		local	BitmapFrame
		.enter	inherit

		; Get the upper left document coordinate of the bitmap

		push	ds				; save bitmap seg
		mov	bx, es:[W_curState]		; get gstate handle
		call	MemDerefDS			; ds -> gstate
		call	GetDocPenPos			; get current pen pos
		mov	BMframe.BF_rotUpLeft.P_x, ax	; save away the coords
		mov	BMframe.BF_rotUpLeft.P_y, bx
		pop	ds				; restore bitmap ptr

		; calculate the effective bitmap height and width.  This 
		; is the stated dimension with the bitmap resolution factored
		; in.

		call	CalcBitmapDimensions		; get real height/wid
		mov	BMframe.BF_rotLowLeft.P_x, bx	; save WWF height here
		mov	BMframe.BF_rotLowLeft.P_y, ax

		; calculate the three corners of interest, and save them

		push	ds, si				; save bitmap segment
		segmov	ds, es, si
		mov	si, W_curTMatrix		; ds:si -> matrix

		; calculate upper right

		add	dx, BMframe.BF_rotUpLeft.P_x	; calculate up-right
		mov	bx, BMframe.BF_rotUpLeft.P_y
		clr	ax
		call	TransCoordFixed			; calculate dev coord
		jc	exitError
		rndwwf	dxcx				; round up
		rndwwf	bxax				; round up
		mov	BMframe.BF_rotUpRight.P_x, dx	; save calc'd corner
		mov	BMframe.BF_rotUpRight.P_y, bx

		; calculate lower left

		mov	dx, BMframe.BF_rotUpLeft.P_x	; calculate low-left
		clr	cx
		mov	bx, BMframe.BF_rotLowLeft.P_x	; calculate low-left
		add	bx, BMframe.BF_rotUpLeft.P_y
		mov	ax, BMframe.BF_rotLowLeft.P_y	; get fraction part
		call	TransCoordFixed			; calculate dev coord
		jc	exitError
		rndwwf	dxcx				; round up
		rndwwf	bxax				; round up
		mov	BMframe.BF_rotLowLeft.P_x, dx	; save calc'd corner
		mov	BMframe.BF_rotLowLeft.P_y, bx	; save calc'd corner

		; calculate upper left

		mov	dx, BMframe.BF_rotUpLeft.P_x	; calculate up-right
		clr	cx
		mov	bx, BMframe.BF_rotUpLeft.P_y
		clr	ax
		call	TransCoordFixed			; calculate dev coord
		jnc	continueCalc
exitError:
		pop	ds, si				; restore bitmap segment
		jmp	done				; carry already set

continueCalc:
		rndwwf	dxcx				; round up
		rndwwf	bxax				; round up
		mov	BMframe.BF_rotUpLeft.P_x, dx	; save calc'd corner
		mov	BMframe.BF_rotUpLeft.P_y, bx	; save calc'd corner

		pop	ds, si				; restore bitmap seg

		; now we can figure out whether to flip the bitmap in x or not.
		; the delta's below are absolute differences, the coordinates 
		; are for the upper-left and upper-right coordinates.
		; 	if (delta_x > delta_y)
		;	    if (x1 > x2)
		;		flip bitmap;
		;	else if (y1 > y2)
		;		flip bitmap;

		mov	cx, BMframe.BF_rotUpLeft.P_x
		mov	ax, cx				; calc delta_x
		sub	ax, BMframe.BF_rotUpRight.P_x
		jns	haveAbsDeltaX
		neg	ax
haveAbsDeltaX:
		mov	dx, BMframe.BF_rotUpLeft.P_y
		mov	bx, dx				; calc delta_y
		sub	bx, BMframe.BF_rotUpRight.P_y
		jns	haveAbsDeltaY
		neg	bx
haveAbsDeltaY:
		cmp	ax, bx				; delta_X > delta_Y ?
		jl	checkYorder
		cmp	cx, BMframe.BF_rotUpRight.P_x	; x1 > x2 ?
		jg	flipBits
		jmp	doneFlipCalc
checkYorder:
		cmp	dx, BMframe.BF_rotUpRight.P_y	; y1 > y2 ?
		jl	doneFlipCalc
flipBits:
		or	BMframe.BF_opType, mask BMOT_SCALE_NEGX

		; The way that Bresenham's algorithm works, it selects a 
		; direction to draw along (either horiz or vert) and, for
		; each pass in the loop, increments in that direction and
		; (perhaps) in the other direction.  Therefore, we can get
		; the number of pixels wide the resulting bitmap is by
		; taking the greater of delta_x and delta_y.
doneFlipCalc:
		inc	ax				; size = right-left+1
		inc	bx				; size = bottom-top+1
		mov	cx, ax				; assume it's delta_x
		cmp	ax, bx
		jge	haveWidth			; if x is greater...
		mov	cx, bx

		; have final width of bitmap.  do some calcs based on this
haveWidth:
		mov	BMframe.BF_finalBMwidth, cx	; final width
		mov	dx, cx				; save width
		mov	al, BMframe.BF_origBMtype 	; calc scaled size
		call	CalcLineSize
		mov	BMframe.BF_scaledScanSize, ax

		; calculate some buffer sizes

		mov	cx, dx				; save width
		mov	al, ds:[si].B_type
		call	CalcLineSize
		mov	cl, ds:[si].B_type
		mov	BMframe.BF_finalBMscanSize, ax ; store scan size
		inc	dx			; one more for padding
		shl	dx, 1			; pixels *2
						; store size of the buffer
						; here for now.
		mov	BMframe.BF_getSliceMaskPtr, dx ; init size
		mov	BMframe.BF_getSliceMaskPtr2, 0 ; init size
		mov	BMframe.BF_origBMmaskSize, 0 ; init size
		
		; if there is a mask, we need a second set of masks and 
		; jumps.  Unless the bitmap format is 1 bit/pixel.  Then 
		; we can use the same for both.  

		test	cl, mask BMT_MASK	; check for a mask
		jz	calcXScaleFactor
		mov	BMframe.BF_getSliceMaskPtr2, dx ; init size

		; we also need to calculate the size of each scan line, only
		; including the mask part.  

		mov	cx, BMframe.BF_origBMwidth ; pass width
		mov	dx, cx			; save for later
		add	cx, 7			; round up to byte boundary
		shr	cx, 1			; divide by 8 for mask size
		shr	cx, 1			;  in bytes
		shr	cx, 1 
		mov	BMframe.BF_origBMmaskSize, cx ; save this 

		; Now calculate the actual scale factor for the width
calcXScaleFactor: 
		mov	dx, BMframe.BF_origBMwidth ; pass width
		clr	cx
		mov	bx, BMframe.BF_finalBMwidth
		clr	ax
		call	GrUDivWWFixed		; calc scale factor
		movwwf	BMframe.BF_xScale, dxcx	; store factor
		
		; Now do y.  It's the same story -- we need to calculate
		; the final bitmap height and the scale factor to get there.

		mov	cx, BMframe.BF_rotUpLeft.P_x
		mov	ax, cx				; calc delta_x
		sub	ax, BMframe.BF_rotLowLeft.P_x
		jns	haveDeltaX
		neg	ax
haveDeltaX:
		mov	dx, BMframe.BF_rotUpLeft.P_y
		mov	bx, dx				; calc delta_y
		sub	bx, BMframe.BF_rotLowLeft.P_y
		jns	haveDeltaY
		neg	bx
haveDeltaY:
		cmp	ax, bx				; see which direction
		jge	xDirection

		; going in the y direction.  xbump is zero, figure out if y
		; bump is 1 or -1

		mov	BMframe.BF_finalBMheight, bx	; final width
		mov	BMframe.BF_xbump, 0		; init the bump factors
		mov	BMframe.BF_curPoint.high, cx	; init curPoint to x
		mov	BMframe.BF_curPoint.low, 0
		mov	BMframe.BF_ybump, 1		; init the bump factors
		cmp	dx, BMframe.BF_rotLowLeft.P_y	; are we increasing
		jl	calcXSlope
		mov	BMframe.BF_ybump, -1		; init the bump factors
calcXSlope:
		sub	cx, BMframe.BF_rotLowLeft.P_x	; figure slope
		neg	cx
		mov	dx, cx
		clr	cx
		clr	ax
		call	GrSDivWWFixed
		movwwf	BMframe.BF_slope, dxcx		; save slope
		jmp	bumpsDone
xDirection:
		mov	BMframe.BF_finalBMheight, ax	; final width
		mov	BMframe.BF_ybump, 0		; init the bump factors
		mov	BMframe.BF_curPoint.high, dx	; init curPoint to y
		mov	BMframe.BF_curPoint.low, 0
		mov	BMframe.BF_xbump, 1		; init the bump factors
		cmp	cx, BMframe.BF_rotLowLeft.P_x	; are we increasing
		jl	calcYSlope
		mov	BMframe.BF_xbump, -1		; init the bump factors
calcYSlope:
		sub	dx, BMframe.BF_rotLowLeft.P_y	; figure slope
		neg	dx
		clr	cx
		mov	bx, ax
		clr	ax
		call	GrSDivWWFixed
		movwwf	BMframe.BF_slope, dxcx		; save slope

		; now figure out the scale factor
bumpsDone:
		mov	bx, BMframe.BF_finalBMheight	; figure scale factor
		clr	ax
		mov	dx, BMframe.BF_origBMheight
		clr	cx
		call	GrUDivWWFixed			; get scale factor
		movwwf	BMframe.BF_yScale, dxcx	; store factor
		clc
done:
		.leave
		ret
CalcRotatedScaleFactor	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcBitmapDimensions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calc the real height/width of the bitmap, with the resolution
		taken into account

CALLED BY:	INTERNAL
		CalcRotatedScaleFactor

PASS:		ds:si	- points to bitmap
			- BitmapFrame is also passed on the stack

RETURN:		dx.cx	- "real" bitmap width 	(document units)
		bx.ax	- "real" bitmap height 	(document units)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		just mutliply the given width/height by the resolution

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalcBitmapDimensions proc near
		.enter	

		; calculate the effect of the bitmap resolution, assuming no
		; effect

		mov	dx, ds:[si].B_width		; get stated width
		clr	cx
		test	ds:[si].B_type, mask BMT_COMPLEX ; complex bitmap ?
		jz	getHeight
		cmp	ds:[si].CB_xres, DEF_BITMAP_RES	; get y resolution
		jne	calcWidth
getHeight:
		mov	bx, ds:[si].B_height		; get stated height
		clr	ax
		test	ds:[si].B_type, mask BMT_COMPLEX ; complex bitmap ?
		jz	done
		cmp	ds:[si].CB_yres, DEF_BITMAP_RES	; get y resolution
		jne	calcHeight
done:
		.leave
		ret

		; calculate true width
calcWidth:
		mov	dx, DEF_BITMAP_RES		; cx is already clear
		clr	cx
		mov	bx, ds:[si].CB_xres		; get x resolution
		clr	ax
		call	GrUDivWWFixed			; dx.cx =  x res factor
		mov	bx, ds:[si].B_width		; get stated width
		clr	ax
		call	GrMulWWFixed			; dx.cx = true width
		jmp	getHeight

		; calculate true height
calcHeight:
		pushwwf	dxcx				; save calculated width
		mov	dx, DEF_BITMAP_RES		; cx is already clear
		clr	cx
		mov	bx, ds:[si].CB_yres		; get y resolution
		clr	ax
		call	GrUDivWWFixed			; dx.cx =  y res factor
		mov	bx, ds:[si].B_height		; get stated height
		clr	ax
		call	GrMulWWFixed			; dx.cx = true height
		movwwf	bxax, dxcx			; set bx.ax = height
		popwwf	dxcx				; restore width
		jmp	done

CalcBitmapDimensions endp
GraphicsRotRaster ends
