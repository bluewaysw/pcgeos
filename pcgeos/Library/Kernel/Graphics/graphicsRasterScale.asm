COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel Library
FILE:		graphicsRasterScale.asm

AUTHOR:		Jim DeFrisco, 7/17/90

ROUTINES:
	Name			Description
	----			-----------
	InitBitmapScale		do some initialization for bitmap scaling
	InitBitmapMasksJumps	Figure out the masks/jumps per output pixel
	ScaleSlice		scale a single slice worth
	PartialScalBigger	scaling by greater than 1.0 times in y

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	7/17/90		Initial revision


DESCRIPTION:
	Routines to scale bitmaps
		

	$Id: graphicsRasterScale.asm,v 1.2 97/09/10 14:19:35 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GraphicsScaleRaster	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitBitmapScale
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initial part of bitmap scaling algorithm

CALLED BY:	GLOBAL

PASS:		es	- segment of window
		ds:si	- pointer to original bitmap structure
		inherits stack frame of GrDrawBitmap

RETURN:		carry	- set if some problem, don't draw
		es	- points to newly allocated bitmap

DESTROYED:	di

PSEUDO CODE/STRATEGY:
		This routine implements part of an interesting algorithm for
		scaling bitmaps that is based on an article that appears in
		the December 1989 issue of Computer Language, entitled
		"BIT-SCALE: A Scaling Bit-Blt".  There are a bunch of 
		changes required, and the paper isn't all that explicit, so
		I'll probably write up something for the spec directory
		on this stuff "soon" (yeah, right...).

		The basic idea is to create a function on the fly to scale
		one scan line of the bitmap.  The function is built out into
		allocated memory by this routine.  The reason for this madness
		is speed (what else ?).  After the function is created, it is
		used by the routine DrawSlice (in the kernel) to scale each
		line of the bitmap.

		On second thought, it is now May, and I need something quick.
		The writing-code-on-the-fly algorithm can wait until later.

		The change in August was to add support for rotated (yech)
		bitmaps.  For now, assume 90 degree rotations

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	01/90		Initial version
	Jim	05/90		Revisited
	Jim	08/90		Re-revisited
	Jim	10/90		Arbitrary rotation

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitBitmapScale	proc	far
		uses	ax,bx,cx,dx,es
BMframe		local	BitmapFrame
		.enter	inherit

		; first off, take fewer scan lines from the source bitmap
		; each time -- since we need two buffers.

		mov	ax, BMframe.BF_origBMscans ; get what we calculated
		shr	ax, 1			   ; do only half
		inc	ax			   ; make sure not zero
		mov	BMframe.BF_origBMscans, ax ; update variable
		mov	cx, BMframe.BF_origBMscanSize ; calc buffer size
		mul	cx
		mov	BMframe.BF_finalBMsliceSize, ax
		mov	BMframe.BF_getSliceDSize, ax
		add	ax, size CBitmap	   ; calc ptr to scale buff
		mov	BMframe.BF_getSliceScalePtr, ax

		; if the bitmap is rotated, handle the whole thing a bit
		; differently

		test	es:[W_curTMatrix].TM_flags, TM_ROTATED
		LONG jz	noRotation
		call	CalcRotatedScaleFactor
		jc	done				; overflow - abort

		; now calculate the size of the buffer we should allocate
calcBufSize:
		mov	ax, BMframe.BF_scaledScanSize	; #bytes per scan
		add	ax, 2				; 2byte/scan for padding
		mov	cx, BMframe.BF_origBMscans	; #scan per slice
		mul	cx				; ax=#bytes/slice(dest)
		tst	dx
		jnz	overflow
		cmp	ax, SLICE_DATA_SIZE
		ja	realBig
calcBufSizeCont:
		add	ax, BMframe.BF_getSliceDSize	; bump up the size
		jc	overflow
		call	CheckTargetSliceSize
		jc	calcBufSize

		add	ax, BMframe.BF_getSliceMaskPtr	; add it pix  masks/jmps
		jc	overflow
		call	CheckTargetSliceSize
		jc	calcBufSize

		add	ax, BMframe.BF_getSliceMaskPtr2	; add mask masks/jmps
		jc	overflow
		call	CheckTargetSliceSize
		jc	calcBufSize

		mov	BMframe.BF_getSliceDSize, ax	; and store it
		sub	ax, BMframe.BF_getSliceMaskPtr2	; calc ptr to mask masks
		add	ax, size CBitmap		; update pointer
		mov	BMframe.BF_getSliceMaskPtr2, ax	; set mask mask pointer
		sub	ax, BMframe.BF_getSliceMaskPtr	; calc mask/jump ptr
		mov	BMframe.BF_getSliceMaskPtr, ax	; set mask/jump ptr

		; if we're scaling bigger in y, then we will be using 
		; PartialScaleBigger.  This routine needs to have an extra
		; buffer of one scaled scan line, so it can save a scaled 
		; last scan line from one slice to the next.
		;
		; Actually, we always need to leave room for this buffer,
		; since ScaleSlice() calls PartialScaleBigger() whenever
		; the scaler is not less than 0. -Don 6/13/95

;;;		mov	ax, BMframe.BF_finalBMheight 	; check it out
;;;		cmp	ax, ds:[si].B_height
;;;		jbe	doneOK				;  no, all done
		mov	ax, BMframe.BF_scaledScanSize	; get size of scan line
		add	ax, 2				; a little padding
		add	BMframe.BF_getSliceDSize, ax	; bump the size we need
		jc	overflow
		add	BMframe.BF_getSliceMaskPtr2, ax	; bump 2nd mask/jmp ptr
		xchg	BMframe.BF_getSliceMaskPtr, ax	; 
		add	BMframe.BF_getSliceMaskPtr, ax	;  ...calc new one
		mov	BMframe.BF_xtraScanLinePtr, ax	; and store ptr to buf
		clc
done:
		.leave
		ret

		; We're tying to allocate a large buffer, though we might
		; just have to do so if the bitmap or scale factor are
		; large enough. But see if we can reduce the scan lines
		; before we give into allocating a big piece of memory.
realBig:
		cmp	cx, 1				;down to 1 scan/slice
		jne	overflowLow			;no, so reduce scanlines
		jmp	calcBufSizeCont

		; We're trying to determine the buffer size, and we've
		; hit overflow (buffer > 64K). Reduce the number of
		; scan lines per slice & try again.
overflow:
		cmp	cx, 1				;down to 1 scan/slice?
		stc
		jz	done				;error if so
overflowLow:
		inc	cx
		shr	cx
		mov	BMframe.BF_origBMscans, cx
		mov	ax, BMframe.BF_origBMscanSize ; calc buffer size
		mul	cx
		mov	BMframe.BF_finalBMsliceSize, ax
		jmp	calcBufSize

		; we know we are scaling.  We know we are not rotated.
		; we have a pointer to the window.  We need to calculate
		; composite x and y scale factors.  Do x first.
noRotation:
		movwwf	dxcx, es:[W_curTMatrix].TM_11

		; check for negative scale factor.  If so, keep a flag, but
		; make the scaling go positive

		tst	dx			; check out negative scale
		jns	checkXComplex
		or	BMframe.BF_opType, mask BMOT_SCALE_NEGX
		negwwf	dxcx			; make it positive
		neg	BMframe.BF_drawPointErrorX
checkXComplex:
		test	ds:[si].B_type, mask BMT_COMPLEX ; complex bitmap ?
		jz	storeXfactor
		mov	dx, DEF_BITMAP_RES 	; set up dividend
		clr	cx
		mov	bx, ds:[si].CB_xres	; get x resolution
EC <		tst	bx						>
EC <		ERROR_Z	GRAPHICS_BITMAP_RESOLUTION_CANT_BE_ZERO		>
		clr	ax
		call	GrUDivWWFixed		; calculate the factor
		movwwf	bxax, es:[W_curTMatrix].TM_11
		test	BMframe.BF_opType, mask BMOT_SCALE_NEGX
		jz	doXMultiply
		negwwf	bxax			; make it positive
doXMultiply:
		call	GrMulWWFixed		; calculate the factor
storeXfactor:
		mov	bx, dx			; we want to save it
		mov	ax, cx
		mov	dx, ds:[si].B_width	; calculate new width
		clr	cx
		call	GrMulWWFixed		; calc new width
		add	cx, BMframe.BF_drawPointErrorX
		adc	dx, 0
		mov	BMframe.BF_finalBMwidth, dx ; set new width
		mov	dx, 1
		clr	cx
		call	GrUDivWWFixed		; get 1/scale factor
		movwwf	BMframe.BF_xScale, dxcx	; store factor

		; calc #bytes needed per target scan line. start calc for
		; data space size (need 2 bytes/pixel for masks/jumps).  We
		; use the same bitmap format as the original, since we change
		; the format AFTER we do any scaling.  This is so we can get
		; the highest quality dither if we need to use a cheaper color
		; format (we don't want to scale dither patterns)

		mov	cx, BMframe.BF_finalBMwidth ; pass width
		mov	al, BMframe.BF_origBMtype ; calc scaled size
		call	CalcLineSize
		mov	BMframe.BF_scaledScanSize, ax

		mov	dx, BMframe.BF_finalBMwidth ; pass width
		add	dx, 7			; pad to next byte (for mono)
		and	dl, 0xf8		; 
		shl	dx, 1			; pixels *2
						; store size of the buffer
						; here for now.
		tst	dx
		jnz	storeMaskBufferSize
		mov	dx, 2			; always reserve room for one
						; entry in the jump table
storeMaskBufferSize:
		mov	BMframe.BF_getSliceMaskPtr, dx ; init size
		
		; if there is a mask, we need a second set of masks and 
		; jumps.  Unless the bitmap format is 1 bit/pixel.  Then 
		; we can use the same for both.  

		mov	cl, ds:[si].B_type
		test	cl, mask BMT_MASK	; check for a mask
		jz	calcYfactor
		mov	BMframe.BF_getSliceMaskPtr2, dx ; init size

		; we also need to calculate the size of each scan line, only
		; including the mask part.  

		mov	cx, BMframe.BF_origBMwidth ; pass width
		add	cx, 7			; round up to byte boundary
		shr	cx, 1			; divide by 8 for mask size
		shr	cx, 1			;  in bytes
		shr	cx, 1 
		mov	BMframe.BF_origBMmaskSize, cx ; save this 

		; Now do y.  
calcYfactor: 
		movwwf	dxcx, es:[W_curTMatrix].TM_22

		; check for negative scale factor.  If so, keep a flag, but
		; make the scaling go positive

		tst	dx			; check out negative scale
		jns	checkYComplex
		or	BMframe.BF_opType, mask BMOT_SCALE_NEGY
		negwwf	dxcx			; make it positive
		neg	BMframe.BF_drawPointErrorY
checkYComplex:
		test	ds:[si].B_type, mask BMT_COMPLEX ; complex bitmap ?
		jz	storeYfactor
		mov	dx, DEF_BITMAP_RES 	; set up dividend
		clr	cx
		mov	bx, ds:[si].CB_yres	; get y resolution
EC <		tst	bx						>
EC <		ERROR_Z	GRAPHICS_BITMAP_RESOLUTION_CANT_BE_ZERO		>
		clr	ax
		call	GrUDivWWFixed		; calculate the factor
		movwwf	bxax, es:[W_curTMatrix].TM_22
		test	BMframe.BF_opType, mask BMOT_SCALE_NEGY
		jz	doYMultiply
		negwwf	bxax			; make it positive
doYMultiply:
		call	GrMulWWFixed		; calculate the factor
storeYfactor:
		mov	ax, cx			; we want to save it
		mov	bx, dx
		mov	dx, ds:[si].B_height	; calculate new height
		clr	cx
		call	GrMulWWFixed		; calc new height
		add	cx, BMframe.BF_drawPointErrorY
		adc	dx, 0
		mov	BMframe.BF_finalBMheight, dx ; set new height
		mov	dx, 1
		clr	cx
		call	GrUDivWWFixed		; calc 1/scale factor
		movwwf	BMframe.BF_yScale, dxcx	; store factor
		jmp	calcBufSize
InitBitmapScale	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckTargetSliceSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Checks to see if the current byte size is under the
		target size, and requests a recalc if not

Pass:		ax - current byte size
		BMframe inherited

SYNOPSIS:	Checks to see if the current buffer size is under the
		target size, and requests a recalculation if not.

CALLED BY:	InitBitmapScale

PASS:		BitmapFrame inherited
		ax	- current size of slice

RETURN:		carry	- set if need to recalculate

DESTROYED:	cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		jon	3/23/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckTargetSliceSize	proc	near
BMframe		local	BitmapFrame
		.enter	inherit

		cmp	ax, SLICE_DATA_SIZE*2
		jbe	ok

		;  If we've already cut down to 1 scan line/slice,
		;  there's not much more we can do

		mov	cx, BMframe.BF_origBMscans
		cmp	cx, 1
		je	ok

		;  OK, we've going to halve the number of scans per slice
		;  and try again...

		inc	cx
		shr	cx
		mov	BMframe.BF_origBMscans, cx
		mov	ax, BMframe.BF_origBMscanSize ; calc buffer size
		mul	cx
		mov	BMframe.BF_finalBMsliceSize, ax
		stc					;request recalc
		jmp	done
ok:
		clc
done:
		.leave
		ret
CheckTargetSliceSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitBitmapMasksJumps
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure out all the masks and pixel jumps

CALLED BY:	INTERNAL
		DrawSlice

PASS:		inherits stack frame from GrDrawBitmap
		es	- pointer to bitmap structure

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		do the pixel jumps and calculate the masks/jumps require
		to scale one scan line

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	05/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitBitmapMasksJumps proc	far
		uses	bx,cx,di
BMframe		local	BitmapFrame
		.enter	inherit

		; since we're here, fix up the drawing position and size
		; if we've got a negative scale factor

		test	BMframe.BF_opType, mask BMOT_SCALE_NEGX ; check x dir
		jz	buildMasksJumps
		mov	ax, BMframe.BF_finalBMwidth	; fixup drawing position
		sub	BMframe.BF_drawPoint.P_x, ax	; adjust drawing pos

		; based on what type of bitmap we're coming from, do the masks
		; and jump calculation differently
buildMasksJumps:
		clr	bx
		mov	bl, BMframe.BF_origBMtype	; get color info
		and	bl, mask BMT_FORMAT
		shl	bx, 1				; word index
		mov	di, BMframe.BF_getSliceMaskPtr	; get pointer for rout
		call	cs:BuildMasksTable[bx]		; go through table

		; store the final bitmap width & height

		mov	es:[B_width], cx
		mov	cx, BMframe.BF_finalBMheight	; store new height too
		mov	es:[B_height], cx

		; now we've done the masks for the data part, check to see
		; if we need to do masks for any pixel mask stored with the
		; bitmap

		mov	bl, es:[B_type]			; get type info
		test	bl, mask BMT_MASK		; is there a mask ?
		jz	done
		mov	di, BMframe.BF_getSliceMaskPtr2	; get pointer
		tst	di				; if 0, something wrong
		jz	done
		call	BuildMonoMasks			; build masks for mask
done:
		.leave
		ret
InitBitmapMasksJumps endp

		; this table has the four routines we need to call
BuildMasksTable	label	nptr
		nptr	BuildMonoMasks			; build em
		nptr	Build4BitMasks			; build em
		nptr	Build8BitMasks			; build em
		nptr	Build8BitMasks			; use same as 8-bit


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScaleSlice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scale a slice of a complex bitmap

CALLED BY:	INTERNAL
		ScaleSliceCompex

PASS:		ss:bp	points into stack near DrawBitmap stack frame
		es	- segment of locked complex bitmap structure.  We
			  are going to scale the data in the first half
			  of this buffer into the second part of the buffer.

RETURN:		scaled scan line scaled into supplied buffer

DESTROYED:	ax,bx,cx,dx,di

PSEUDO CODE/STRATEGY:
		We need to scale a few lines of the source bitmap into
		the destination size.  The bitmap buffer that we allocated
		has a data portion that is divided into two sections.  The
		original bitmap data is read into the first half of this 
		data space and both decompaction & format changes happen
		*** in place *** in that part of the buffer.   The
		scaling uses the second part of the buffer, since the data
		can take up more room.  The # scan lines that are read in
		is calculated to not overflow the buffer.

		Our plan is basically to move a mask over the input scan
		line, moving the appropriate pixels to the destination
		bitmap scan line.  The mask is bumped by the xScale amount
		calculated in InitBitmapScale.  We count down destination
		pixels in x and destination scans in y.  Continue until we
		run out of source scan lines.

		If the number of source scan lines is smaller than the 
		expanded number of destination lines, we may do the scale
		in pieces.  That is, we'll re-vector the callback to 
		return here, and keep coming back here until we're done
		drawing.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	05/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScaleSlice	proc	far
		uses	si, ds				; save a few
BMframe		local	BitmapFrame
		.enter	inherit

		; we have different routines to scale lines of different
		; color formats.  Fetch the proper routine address now.
		; When done with this initialization, we'll have:
		;	ds:si	- pointing to first source scan line
		;	es:di	- pointing to scaled scan line buffer
		;	bx	- offset to routine to scale a scan line

		mov	bl, BMframe.BF_origBMtype	; get type
		and	bx, mask BMT_FORMAT		; isolate the format
		shl	bx, 1				; shift to get routine
		mov	bx, cs:[ScaleBitmapScan][bx]	; get routine address
		segmov	ds, es, si			; set ds:si -> source
		mov	si, es:[CB_data]		; get offset to data
		mov	di, si				; calc dest buffer
		mov	di, BMframe.BF_getSliceScalePtr	; es:di -> destination
		mov	es:[CB_data], di		; where we'll want it
		mov	BMframe.BF_finalBMdata, di	; where we'll want it
		mov	es:[CB_numScans], 0		; init row count

		; check out if we have to adjust the source bitmap pointer.
		; If the previous operation left the curScan variable past the
		; first scan of this slice, then we have to update the scan line
		; pointer appropriately.  It's possible that the next scan line
		; to scale is not in this slice.  In that case, just return 
		; without scaling/drawing anything

		mov	ax, BMframe.BF_origBMscanSize	; get size of each scan
		mov	dx, BMframe.BF_curScan.WWF_int	; get current scan #
		mov	cx, BMframe.BF_origBMcurScan	; adjust to top of this
		cmp	dx, cx				; if overboard, quit
		jae	done
		sub	cx, BMframe.BF_origBMscans	;  slice
		jmp	startScanCheck
adjScanLoop:
		add	si, ax				; bump pointer
		inc	cx
startScanCheck:
		cmp	dx, cx				; everything OK?
		ja	adjScanLoop			;  no, adjust pointer

		; check out if we're getting bigger or smaller in y.  Use
		; a different strategy for each case.

		tst	BMframe.BF_yScale.WWF_int	; check high byte
		jnz	scaleDown			; handle growing case
		
		; OK, we're getting bigger.  The deal here is each source
		; scan line will be expanded into one or more destination
		; scan lines.  This means two things.  First, we can't 
		; expand the entire slice -- it might overflow.  Second,
		; we can make use of the fact that two adjacent scan lines
		; might be the same.

		mov	BMframe.BF_partScaleFunc, bx	; set vars
		mov	BMframe.BF_partScaleDPtr, si	; 
		mov	cx, BMframe.BF_origBMscans	; get #orig scans we fit
		mov	BMframe.BF_partScaleScans, cx	; init partial scale cnt
		call	PartialScaleBigger		; do as much as we can
done:
EC <		call	ECMemVerifyHeap			; make sure its ok>
		.leave
		ret

		; OK, we're getting smaller.  This is pretty straighforward.
		; Just scale the whole slice and draw it at once.  The one
		; complication is that we might end up with a few scan lines
		; left over from the source bitmap that we'll have to skip
		; for the first destination scan of the next slice.  
scaleDown:
		mov	BMframe.BF_partScaleScans, 0	; init flag
		and	BMframe.BF_opType, not mask BMOT_PARTIAL; init flag
smallerLoop:
		call	ScaleOneScan			; scale a scan line
		inc	es:[CB_numScans]		; one more row to do
		cmp	ax, BMframe.BF_origBMcurScan	; done yet ?
		jc	smallerLoop			;  no, continue
		jmp	done
ScaleSlice	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PartialScaleBigger
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scale part of a slice bigger.

CALLED BY:	INTERNAL
		ScaleSlice, BMGetSlice

PASS:		bp	- stack frame with BF_vars
		es	- pointer to bitmap scaling buffer

RETURN:		ds:si	- pointing at scaled bitmap

DESTROYED:	ax,bx,cx,dx,di

PSEUDO CODE/STRATEGY:
		This routine handles the y loop of scaling a slice if there
		is a scale factor in y > 1.0

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	05/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PartialScaleBigger proc	far
BMframe		local	BitmapFrame
		.enter	inherit

		segmov	ds, es, si
		mov	si, BMframe.BF_partScaleDPtr	; get source offset 
		mov	di, BMframe.BF_getSliceScalePtr	; set up destination
		clr	cx				; cx = numRows
		mov	bx, BMframe.BF_partScaleFunc	; scale the next line
		mov	ax, ds:[CB_numScans]		; update vars
		add	ax, ds:[CB_startScan]		; ax=new start row
		mov	ds:[CB_startScan], ax
		tst	ax				; get overall height
		jns	testHeight			;  so far
		neg	ax
testHeight:
		mov	dx, ds:[B_height]
		inc	dx
		sub	dx, ax				; dx = scan lines left
		LONG jbe doneSlice			; if none, just exit

		; we have to scale the very first one, since there is nothing to
		; copy from.  If we're in the middle of the bitmap somewhere,
		; we might be able to use the last scaled scan line (which we
		; have saved in the buffer pointed to by BF_xtraScanLinePtr).

		mov	ax, BMframe.BF_lastScan		; see if it's changed
		cmp	ax, BMframe.BF_curScan.WWF_int	;  ?
		jne	scaleScan			;  yes, scale a new one

		; OK, the scan line hasn't changed, which means that we might
		; want to copy the last one.  Unless this is the first scan line
		; overall.  Then we scale.

		test	BMframe.BF_stateFlags, \
			mask BMSF_DONE_FIRST_SOURCE_SCANLINE
		jz	scaleScan

		; not the first scan, so get a pointer to the last scan of the
		; previous slice, so we can copy it.
copyOldLine:
		push	si, cx
		mov	si, BMframe.BF_xtraScanLinePtr	; get ptr to last line
		mov	cx, BMframe.BF_scaledScanSize	; amount to copy
		shr	cx, 1
		jnc	initWords
		movsb
initWords:
		rep	movsw				; copy the data
		pop	si, cx

		; OK, we have the last one.  So bump the current scan number
		; and join the normal scaling loop.  We need to use this 
		; instead of BumpScanLine, since we don't want to bump over
		; the first source scan line in this slice.  This does NOT
		; apply, however, if PartialScaleBigger is called a second
		; or subsequent time with the same slice.

		mov	ax, BMframe.BF_partScaleScans	; see if just starting
		cmp	ax, BMframe.BF_origBMscans	; all left still?
		jne	calcNewScan			;  no, treat normally

		inc	cx
		mov	ax, BMframe.BF_yScale.WWF_frac
		add	BMframe.BF_curScan.WWF_frac, ax ; get fraction
		mov	ax, BMframe.BF_curScan.WWF_int 	; get fraction
		mov	BMframe.BF_lastScan, ax		; and store it
						; NOTE: when scaling bigger, 
						; yScale.int is always == 0
;;;		adc	ax, BMframe.BF_yScale.WWF_int   ; get integer
		adc	ax, 0				; get integer
		mov	BMframe.BF_curScan.WWF_int, ax	; bump scan number
		cmp	cx, BMframe.BF_origBMscans	; filled to brim ?
		jae	sliceFilled			;  yes, filled to brim
		cmp	ax, BMframe.BF_lastScan		; scan line changed ?
		je	copyOldLine			;  no, keep copying

		; we have to scale the first one, since there is nothing to
		; copy from.
scaleScan:
		tst	BMframe.BF_partScaleScans	; if no more source then
		jz	doneSlice			; ...we must be done
		ornf	BMframe.BF_stateFlags, \
			mask BMSF_DONE_FIRST_SOURCE_SCANLINE
		call	ScaleOneScan			; scale single scan line
		inc	cx				; one more row filled
		dec	BMframe.BF_partScaleScans	; 1 less to go in slice
bumpScanLine:
		cmp	cx, BMframe.BF_origBMscans	; filled to brim ?
		jae	sliceFilled			;  yes, filled to brim

		; the new line is a copy of the last one, so just copy it 
		; instead of scaling again.

		mov	ax, BMframe.BF_lastScan		; see if it's changed
		cmp	ax, BMframe.BF_curScan.WWF_int	;  ?
		jne	scaleScan			;  yes, scale a new one
		push	si, cx				;  no, just copy prev
		mov	si, di				; get pointer to dest
		mov	cx, BMframe.BF_scaledScanSize	; back up ptr to start
		sub	si, cx
		shr	cx, 1				; calc # words
		jnc	copyWords
		movsb
copyWords:
		rep	movsw				; copy scan line
		pop	si, cx				; restore data pointer
calcNewScan:
		call	BumpCurScan			; on to next scan	
		inc	cx				; one more row filled
		dec	dx				; only continue if more
		jnz	bumpScanLine			; ...scan lines needed

		; done with this entire slice.  reset the partial scale flag
doneSlice:
		and	BMframe.BF_opType, not mask BMOT_PARTIAL ; reset flag
		jmp	done

		; the destination part of the slice is filled (time to draw)
		; but first figure out if there are any more source scans left
		; to do
sliceFilled:
		or	BMframe.BF_opType, mask BMOT_PARTIAL	; set flag
done:
		mov	BMframe.BF_partScaleDPtr, si	; update data ptr
		mov	es:[CB_numScans], cx		; set number of rows

		; now that we're done with the slice, copy the last scan line
		; over to a separate buffer, so that we can use it during the
		; next pass if neccesary

		; but if none is scaled, there is none to copy
		; -- kho, 6/1/98

		jcxz	quit
		
		push	si
		mov	si, di				; set up destination
		mov	cx, BMframe.BF_scaledScanSize
		sub	si, cx
		mov	di, BMframe.BF_xtraScanLinePtr	; get pointer to buffer
		shr	cx, 1				; do it by words
		jnc	saveWords
		movsb
saveWords:
		rep	movsw				; copy the data
		pop	si
quit:
		.leave
		ret
PartialScaleBigger endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScaleOneScan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scale a single scan line, handles masks

CALLED BY:	INTERNAL
		PartialScaleBigger, ScaleSlice

PASS:		bx	- routine to call
		ds:si	- pointer to data to scale
		bp	- BitmapFrame structure

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		put pseudo code here

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScaleOneScan	proc	near
BMframe		local	BitmapFrame
		.enter	inherit
		tst	BMframe.BF_origBMmaskSize	; see if scaling mask
		jnz	scaleMask			;  no, scale the data
		mov	ax, BMframe.BF_getSliceMaskPtr	; get ptr to masks/jmps
		call	bx				; scale data only
done:
		call	BumpCurScan
		.leave
		ret

scaleMask:
		mov	ax, BMframe.BF_getSliceMaskPtr2	; get ptr to masks/jmps
		call	ScaleMonoScan			; scale masks
		mov	ax, BMframe.BF_getSliceMaskPtr	; data masks/jmps
		add	si, BMframe.BF_origBMmaskSize	; bump to data
		call	bx
		sub	si, BMframe.BF_origBMmaskSize	; restore pointer
		jmp	done
ScaleOneScan	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScaleMonoScan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scale a scan line of a monochrome bitmap

CALLED BY:	INTERNAL

PASS:		ds:si	- pointer to data to scale
		es:di	- pointer to buffer to scale into
		ax	- pointer to masks/jumps buffer
		bp	- frame pointer for GrDrawBitmap

RETURN:		es:di	- pointer to start of next destination scan line

DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		skip along each pixel, doing that scaling thing.
		we keep accumulating destination pixels until we have
		a word of them, then store it.  Then handle the last
		partial word.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	05/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScaleMonoPixel	macro	targetreg
		and	al, ds:[bx]		;; isolate bit
		add	al, 0xff		;; sets carry if bit set
		rcl	targetreg, 1		;; set bit in destination
		inc	bx			;; move on to jump amount
		mov	al, ds:[bx]		;; get jump amount
		add	si, ax			;; bump the source pointer
		mov	al, ds:[si]		;; get the next byte to scale
		inc	bx			;; bump pointer to mask
endm

ScaleMonoScan	proc	near
		uses	bx,cx,dx,si
		.enter	

		; do some initialization: mask, count, 

		mov	bx, ax				; get pointer to jumps
		mov	cx, es:[B_width]		; width of bitmap
		shr	cx, 1				; calc #words
		shr	cx, 1
		shr	cx, 1
		shr	cx, 1
		mov	al, ds:[si]			; get first byte
		clr	ah				; needs to be clr later
		tst	cx				; any whole bytes ?
		jnz	scalePixel			;  no just do final part
		jmp	scaleLastWord

		; loop through each destination byte.  Jumping through
		; the source along the way
scalePixel:
		ScaleMonoPixel dx			; and a 0..
		ScaleMonoPixel dx			; ..and a 1..
		ScaleMonoPixel dx			; ..and a 2..
		ScaleMonoPixel dx			; ..and a 3..
		ScaleMonoPixel dx			; ..and a 4..
		ScaleMonoPixel dx			; ..and a 5..
		ScaleMonoPixel dx			; ..and a 6..
		ScaleMonoPixel dx			; ..and a 7..
		ScaleMonoPixel dx			; ..and a 8..
		ScaleMonoPixel dx			; ..and a 9..
		ScaleMonoPixel dx			; ..and a a..
		ScaleMonoPixel dx			; ..and a b..
		ScaleMonoPixel dx			; ..and a c..
		ScaleMonoPixel dx			; ..and a d..
		ScaleMonoPixel dx			; ..and a e..
		ScaleMonoPixel dx			; ..and a f..
		xchg	ax, dx				; so we can stosw
		xchg	al, ah				; little-endian
		stosw					; send out scaled word
		mov	ax, dx				; restore ax
		dec	cx				; can't use loop
		jz	scaleLastWord			;  cause it's too far
		jmp	scalePixel			;  cause it's too far

		; down to the last destination byte.
scaleLastWord:
		mov	cx, es:[B_width]		; do this many at most
		and	cx, 0xf				; do last word
		jz	done				; if no partial word...
		cmp	cl, 8				; do a whole word?
		jae	doWord
scaleLastByte:
		mov	dh, 8				; calc #not doing
		sub	dh, cl				; and save
lastByteLoop:
		ScaleMonoPixel dl			; scale another
		loop	lastByteLoop			;   else count down
		mov	cl, dh				; restore not-done cnt
		shl	dl, cl				; shift in zeroes
storeLast:
		mov	al, dl
		stosb					; store last byte
done:
		.leave					;
		ret

		; do last partial word
doWord:
		ScaleMonoPixel dl			; have to do at least 8 
		ScaleMonoPixel dl			
		ScaleMonoPixel dl			
		ScaleMonoPixel dl			
		ScaleMonoPixel dl			
		ScaleMonoPixel dl			
		ScaleMonoPixel dl			
		ScaleMonoPixel dl			
		sub	cl, 8				; done ?
		jz	storeLast			;  yes, store final b
		xchg	al, dl				; so we can stosw
		stosb					; send out scaled word
		mov	al, dl				; restore ax
		jmp	scaleLastByte			;  no, act like last b
		
ScaleMonoScan	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Scale4BitScan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scale a scan line of a 4Bit bitmap

CALLED BY:	INTERNAL

PASS:		ds:si	- pointer to data to scale
		es:di	- pointer to buffer to scale into
		ax	- pointer to masks/jumps buffer
		bp	- frame pointer for GrDrawBitmap

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		skip along each pixel, doing that scaling thing.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	05/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Scale4BitPixel	macro	targetreg
		local	addNewPixel
		push	cx
		mov	cl, 4
		shl	targetreg, cl		;; make room for new pixel
		mov	ah, ds:[bx]		;; get mask for this pixel
		inc	bx			;; bump mask/jump pointer
		and	al, ah			;; isolate bits
		tst	ah			;; do we need to shift result ?
		jns	addNewPixel		;;  no, just add it in
		ror	al, cl			;;  yes, get in the low nibble
addNewPixel:
		or	dl, al			;; add in new pixel
		mov	al, ds:[bx]		;; get jump amount
		inc	bx			;; on to next mask
		clr	ah
		add	si, ax			;; bump source pointer
		mov	al, ds:[si]		;; get next source byte
		pop	cx
endm

Scale4BitScan	proc	near
		uses	bx,cx,dx,si
		.enter	

		; do some initialization: mask, count, 

		mov	bx, ax				; get pointer to jumps
		mov	cx, es:[B_width]		; width of bitmap
		shr	cx, 1				; calc #words wide
		shr	cx, 1
		mov	al, ds:[si]			; get first byte
		tst	cx				; any whole bytes ?
		jnz	scalePixel			;  no just do final part
		jmp	scaleLastWord

		; loop through each destination byte.  Jumping through
		; the source along the way
scalePixel:
		Scale4BitPixel dx			; and a 0..
		Scale4BitPixel dx			; ..and a 1..
		Scale4BitPixel dx			; ..and a 2..
		Scale4BitPixel dx			; ..and a 3..
		xchg	ax, dx				; so we can stosw
		xchg	al, ah				; little-endian
		stosw					; send out scaled word
		mov	ax, dx				; restore ax
		loop	scalePixel

		; down to the last destination byte.
scaleLastWord:
		mov	cx, es:[B_width]		; do this many at most
		and	cx, 0x3				; do last word
		jz	done				; if no partial word...
		cmp	cl, 2				; do a whole word?
		jae	doWord
scaleLastByte:
		mov	dh, 2				; calc #not doing
		sub	dh, cl				; and save
lastByteLoop:
		Scale4BitPixel dl			; scale another
		loop	lastByteLoop			;   else count down
		mov	cl, dh				; restore not-done cnt
		shl	cl
		shl	cl
		shl	dl, cl				; shift in zeroes
storeLast:
		mov	al, dl
		stosb					; store last byte
done:
		.leave					;
		ret

		; do last partial word
doWord:
		Scale4BitPixel dl			
		Scale4BitPixel dl			
		sub	cl, 2				; done ?
		jz	storeLast			;  yes, store final b
		xchg	al, dl				; so we can stosw
		stosb					; send out scaled word
		mov	al, dl				; restore ax
		jmp	scaleLastByte			;  no, act like last b
Scale4BitScan	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Scale8BitScan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scale a scan line of a 8Bit bitmap

CALLED BY:	INTERNAL

PASS:		ds:si	- pointer to data to scale
		es:di	- pointer to buffer to scale into
		ax	- pointer to masks/jumps buffer
		bp	- frame pointer for GrDrawBitmap

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		skip along each pixel, doing that scaling thing.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	05/90		Initial version
		Don	01/00		Fixed "uneven scaling" bug

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Scale8BitScan	proc	near
		uses	bx,cx,dx,si
		.enter	

		; do some initialization

		mov	bx, ax				; get pointer to jumps
		mov	cx, es:[B_width]		; width of bitmap
		tst	cx				; any data?
		jz	done				; nope, so we're done

		; loop through the scale jump buffer, copying a
		; pixel (byte) each time.
scalePixel:
		movsb					; copy pixel
		dec	si				; don't change source
		add	si, ds:[bx]			; bump to next pixel
		add	bx, 2				; & next scale entry
		loop	scalePixel
done:
		.leave
		ret
Scale8BitScan	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScaleRGBScan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scale a scan line of a RGB bitmap

CALLED BY:	INTERNAL

PASS:		ds:si	- pointer to data to scale
		es:di	- pointer to buffer to scale into
		ax	- pointer to masks/jumps buffer
		bp	- frame pointer for GrDrawBitmap

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		skip along each pixel, doing that scaling thing.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	05/90		Initial version
		tom	9/97		Fix for 24-bit graphics
		Don	01/00		Fixed "uneven scaling" bug

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScaleRGBScan	proc	near
		uses	ax,bx,cx,dx,si
		.enter

		; do some initializaton

		mov	bx, ax			; get pointer to jumps
		mov	cx, es:[B_width]	; width of bitmap
		tst	cx			; any data?
		jz	done			; nope, so we're done

		; loop through the scale jump buffer, copying a
		; pixel (3 bytes) each time. We cannot do a simple
		; add "si, ds;[bx] because the scale jump array is
		; the same as the one used for 8-bit bitmaps, so
		; we need to multiply the pixel count by 3 (which
		; is the same as adding the value once, doubling it,
		; and adding that).
scalePixel:
		movsb				; copy 1/3 of pixel
		movsw				; copy rest of pixel
		sub	si, 3			; don't change source pointer
		mov	ax, ds:[bx]		; bump to next pixel
		add	si, ax
		shl	ax, 1
		add	si, ax
		add	bx, 2			; ...and next scale entry
		loop	scalePixel
done:
		.leave
		ret
ScaleRGBScan	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BuildMonoMasks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out a string 

CALLED BY:	INTERNAL
		InitBitmapMasksJumps

PASS:		es	- segment of locked window
		di	- pointer to buffer where masks/jumps go
		inherits stack frame from DrawBitmap

RETURN:		cx	- actual width of destination bitmap

DESTROYED:	dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version
		Don	7/14/94		Fixed missing last pixel

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BuildMonoMasks	proc	near
		uses	ax,bx,di,si
BMframe		local	BitmapFrame
		.enter	inherit

		; frolic throught the pixels...

		clr	cx
		mov	BMframe.BF_lastPix, cx	 	; init values
		mov	dx, cx				; fraction
		mov	si, cx				; integer
setLoop:
		mov	bx, BMframe.BF_lastPix 		; get lo byte
		and	bx, 7				; get shift amount
		add	dx, BMframe.BF_xScale.WWF_frac
		adc	si, BMframe.BF_xScale.WWF_int	; bump scan number
		cmp	si, BMframe.BF_origBMwidth	; overflow ?
		jae	overflow
continue:
		mov	al, cs:MonoMaskTable[bx]	; get mask
		clr	ah				; no jump if equal
		cmp	si, BMframe.BF_lastPix	 	; did it change ?
		je	storeMask			;  no, all ready
		mov	bx, si				; save new count
		shr	bx, 1				; cur>>3
		shr	bx, 1
		shr	bx, 1
		xchg	si, BMframe.BF_lastPix	 	;  store it get old 1
		shr	si, 1				; byte index of last
		shr	si, 1
		shr	si, 1
		neg	si				; calc new>>3 - old>3
		add	bx, si				; byte difference
		mov	ah, bl				; al = jmp
		mov	si, BMframe.BF_lastPix	 	; restore current pos
storeMask:
		inc	cx				; one more to draw
		stosw					; store a work
		cmp	cx, BMframe.BF_finalBMwidth
		jb	setLoop

		.leave
		ret

		; In the process of scaling the bitmap, we've gone beyond 
		; the end of a scanline of data. We need to use some data
		; to complete the bitmap, so we use the last pixel.
overflow:
		mov	si, BMframe.BF_lastPix
		jmp	continue
BuildMonoMasks	endp

MonoMaskTable	label	byte
		byte	0x80,0x40,0x20,0x10,0x08,0x04,0x02,0x01


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Build4BitMasks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build the masks/jumps for a 4bit/pixel display

CALLED BY:	INTERNAL
		InitBitmapMasksJumps

PASS:		es	- segment of locked window
		di	- pointer to buffer where masks/jumps go
		inherits stack frame from DrawBitmap

RETURN:		cx	- actual width of destination bitmap

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		supports scale factors up to 512:1 (compressing)

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	05/90		Initial version
		Don	7/14/94		Fixed missing last pixel

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Build4BitMasks	proc	near
		uses	ax,bx,di,si
BMframe		local	BitmapFrame
		.enter	inherit

		; frolic throught the pixels...

		clr	cx
		mov	BMframe.BF_lastPix, cx	 	; init values
		mov	dx, cx				; fraction
		mov	si, cx				; integer
setLoop:
		mov	bx, BMframe.BF_lastPix 		; get lo byte
		and	bx, 1				; get shift amount
		add	dx, BMframe.BF_xScale.WWF_frac
		adc	si, BMframe.BF_xScale.WWF_int	; bump scan number
		cmp	si, BMframe.BF_origBMwidth	; overflow ?
		jae	overflow
continue:
		mov	al, cs:VGAMaskTable[bx]		; get mask
		clr	ah
		cmp	si, BMframe.BF_lastPix	 	; did it change ?
		je	storeMask			;  no, all ready
		mov	bx, si				; save new count
		shr	bx, 1
		xchg	si, BMframe.BF_lastPix	 	;  store it get old 1
		shr	si, 1				; byte index of last
		neg	si				; calc new>>1 - old>>1
		add	bx, si				; byte difference
		mov	ah, bl				; al = jmp
		mov	si, BMframe.BF_lastPix	 	; restore current pos
storeMask:
		inc	cx				; one more to draw
		stosw					; store a work
		cmp	cx, BMframe.BF_finalBMwidth
		jb	setLoop

		.leave
		ret

		; In the process of scaling the bitmap, we've gone beyond 
		; the end of a scanline of data. We need to use some data
		; to complete the bitmap, so we use the last pixel.
overflow:
		mov	si, BMframe.BF_lastPix
		jmp	continue
Build4BitMasks	endp

VGAMaskTable	label	byte
		byte	0xf0,0x0f


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Build8BitMasks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build the masks/jumps for an 8bit/pixel display

CALLED BY:	INTERNAL
		InitBitmapMasksJumps

PASS:		es	- segment of locked window
		di	- pointer to buffer where masks/jumps go
		inherits stack frame from DrawBitmap

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		There are no masks stored with 8bit/pixel format, since 
		the pixels are whole bytes
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	05/90		Initial version
		Don	7/14/94		Fixed missing last pixel

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Build8BitMasks	proc	near
		uses	ax,bx,di,si
BMframe		local	BitmapFrame
		.enter	inherit

		; frolic throught the pixels...

		clr	cx
		mov	BMframe.BF_lastPix, cx	 	; init values
		mov	dx, cx				; fraction
		mov	si, cx				; integer
setLoop:
		add	dx, BMframe.BF_xScale.WWF_frac
		adc	si, BMframe.BF_xScale.WWF_int	; bump scan number
		cmp	si, BMframe.BF_origBMwidth	; overflow ?
		jae	overflow
continue:
		clr	ax				; assume jump is 0
		cmp	si, BMframe.BF_lastPix	 	; did it change ?
		je	storeMask			;  no, all ready
		mov	ax, si				; save new count
		xchg	si, BMframe.BF_lastPix	 	;  store it get old 1
		neg	si				; calc new>>1 - old>>1
		add	ax, si				; byte difference
		mov	si, BMframe.BF_lastPix	 	; restore current pos
storeMask:
		inc	cx				; one more to draw
		stosw					; store a work
		cmp	cx, BMframe.BF_finalBMwidth
		jb	setLoop

		.leave
		ret

		; In the process of scaling the bitmap, we've gone beyond 
		; the end of a scanline of data. We need to use some data
		; to complete the bitmap, so we use the last pixel.
overflow:
		mov	si, BMframe.BF_lastPix
		jmp	continue
Build8BitMasks	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BumpCurScan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bump current source scan/pixel we want to look at

CALLED BY:	Different scaling routines

PASS:		si	- pointer into scan buffer

RETURN:		ax	= new scan number 	  (BumpCurScan)
		si	= new pointer to next scan line to scale

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BumpCurScan	proc	near
BMframe		local	BitmapFrame
		uses	dx
		.enter	inherit
		mov	ax, BMframe.BF_curScan.WWF_int 	; get fraction
		mov	BMframe.BF_lastScan, ax		; and store it
		mov	dx, BMframe.BF_yScale.WWF_frac
		add	BMframe.BF_curScan.WWF_frac, dx ; get fraction
		adc	ax, BMframe.BF_yScale.WWF_int   ; get integer
		mov	BMframe.BF_curScan.WWF_int, ax	; bump scan number
		sub	ax, BMframe.BF_lastScan		;  get last scan line
		jz	haveScanPointer
		mov	dx, BMframe.BF_origBMscanSize	; get #bytes/scan line
addLoop:
		add	si, dx				; bump another
		dec	ax
		jnz	addLoop
haveScanPointer:
		mov	ax, BMframe.BF_curScan.WWF_int	; get new scan line
		.leave
		ret
BumpCurScan	endp


		; routines to call to scale a single scan line

ScaleBitmapScan nptr	ScaleMonoScan		; BMF_MONO
	  	nptr	Scale4BitScan		; BMF_4BIT
	  	nptr	Scale8BitScan		; BMF_8BIT
	  	nptr	ScaleRGBScan		; BMF_24BIT


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BMComplexReject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do a trivial reject test on a rotated bitmap

CALLED BY:	GLOBAL
		BMTrivialReject (in kernel)

PASS:		bunch of stuff (see BMTrivialReject in kernel)

RETURN:		carry	-set if rejected

DESTROYED:	ax,bx

PSEUDO CODE/STRATEGY:
		do a bounds check on the corners of the bitmap

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	05/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BMComplexReject	proc	far
		uses	cx, dx
leftSide	local	word
topSide		local	word
rightSide	local	word
bottomSide	local	word
minX		local	word
minY		local	word
		.enter
		mov	ax, cx				; restore passed parms
		mov	bx, dx
		mov	cx, ds:[si].B_width		; load up size
		mov	dx, ds:[si].B_height
		test	ds:[si].B_type, mask BMT_COMPLEX ; is it complex ?
		jnz	checkBitmapRes			; check bitmap res
haveBitmapSize:
		mov	leftSide, ax			; save passed coords
		mov	topSide, bx
		add	cx, ax
		add	dx, bx
		mov	rightSide, cx
		mov	bottomSide, dx
		mov	cx, 7fffh			; init max x
		mov	minX, cx			; init min x
		mov	minY, cx			; init min y
		inc	cx				; cx = 8000h
		mov	bx, dx				; do lower left 1st
		mov	dx, cx				; init max y
		call	BMCheckCorner			; check lower left
		mov	ax, rightSide			;
		mov	bx, bottomSide
		call	BMCheckCorner			; check lower right
		mov	ax, rightSide			;
		mov	bx, topSide
		call	BMCheckCorner			; check upper right
		mov	ax, leftSide			;
		mov	bx, topSide
		call	BMCheckCorner			; check upper left
		xchg	minX, ax			; save upper left trans
		xchg	minY, bx			;   get min x and y

		; check extent of bitmap

		cmp	ax, es:[W_maskRect.R_right]
		jg	BMTR_rej2			; reject: after right
		cmp	cx, es:[W_maskRect.R_left]
		jl	BMTR_rej2			; reject: before left
		cmp	bx, es:[W_maskRect.R_bottom]
		jg	BMTR_rej2			; reject: below bottom
		cmp	dx, es:[W_maskRect.R_top]
		jl	BMTR_rej2			; reject: above top
		clc					; signal ok
BMTR_finTR:
		mov	ax, minX			; get trans coord
		mov	bx, minY
		.leave	
		ret
BMTR_rej2:
		stc					; signal reject
		jc	BMTR_finTR

		; bitmap is complex, might have its own resolution
checkBitmapRes:
		xchg	cx, dx			; get xres in dx
		cmp	ds:[si].CB_xres, DEF_BITMAP_RES ; if default, save
		je	saveXsize
		push	ax,bx
		mov	dx, DEF_BITMAP_RES 	; set up dividend
		clr	cx
		mov	bx, ds:[si].CB_xres	; get x resolution
		clr	ax
		call	GrUDivWWFixed		; calculate the factor
		mov	bx, ds:[si].B_width
		clr	ax
		call	GrMulWWFixed		; dx = real width
		shl	ch, 1			; round up
		adc	dx, 0
		mov	cx, ds:[si].B_height	; reload height
		pop	ax,bx
saveXsize:	
		xchg	cx, dx
		cmp	ds:[si].CB_yres, DEF_BITMAP_RES ; if default, save
		LONG je	haveBitmapSize
		push	ax,bx
		push	cx			; save width
		mov	dx, DEF_BITMAP_RES 	; set up dividend
		clr	cx
		mov	bx, ds:[si].CB_yres	; get y resolution
		clr	ax
		call	GrUDivWWFixed		; calculate the factor
		mov	bx, ds:[si].B_height
		clr	ax
		call	GrMulWWFixed		; dx = real height
		shl	ch, 1			; round up
		adc	dx, 0
		pop	cx
		pop	ax,bx
		jmp	haveBitmapSize
BMComplexReject	endp

		; utility routine used by BMTrivialReject...
BMCheckCorner	proc	near
leftSide	local	word
topSide		local	word
rightSide	local	word
bottomSide	local	word
minX		local	word
minY		local	word
		.enter	inherit

		ForceRef leftSide
		ForceRef topSide
		ForceRef rightSide
		ForceRef bottomSide

		call	GrTransCoordFar			; translate coordinate
		cmp	cx, ax				; check for new maxx
		jg	BMCC_10
		mov	cx, ax
BMCC_10:
		cmp	minX, ax			; check for new minx
		jl	BMCC_checky
		mov	minX, ax
BMCC_checky:
		cmp	dx, bx				; check for new maxy
		jg	BMCC_20
		mov	dx, bx
BMCC_20:
		cmp	minY, bx			; check for new miny
		jl	BMCC_done
		mov	minY, bx
BMCC_done:
		.leave
		ret
BMCheckCorner	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MirrorBitmapBits
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mirror the bits in a bitmap in the x direction

CALLED BY:	EXTERNAL
		BMGetSlice

PASS:		ds:si	- points to bitmap to flip bits for
		BitmapFrame passed on the stack

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		swap the bytes, then swap the bits, make sure they are left
		aligned

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MirrorBitmapBits proc	far
		uses	bx,cx,di
		.enter	

		; get the format of the bitmap, to form the correct routine
		; table index

		mov	bl, ds:[si].B_type	; format info is here
		mov	bh, bl			; save a copy
		mov	di, size Bitmap		; assume simple bitmap
		mov	cx, ds:[si].B_height	; assume simple
		test	bl, mask BMT_COMPLEX	; check assumption
		jz	checkForMask
		mov	di, ds:[si].CB_data	; complex, fetch data pointer
		mov	cx, ds:[si].CB_numScans	; complex, get height of slice
		tst	cx			; if negative, swap
		jns	checkForMask		;  ok, continue
		neg	cx
checkForMask:
		tst	cx			; if cx is zero, nothin to do
		jz	done
		add	di, si			; compute segment offset to data
		and	bl, mask BMT_FORMAT	; isolate the format info
		shl	bl, 1			; *2 for table index
		test	bh, mask BMT_MASK	; diff loop if mask
		mov	bh, 0			; need a word table index
		mov	bx, cs:mirrorScanTable[bx] ; load up routine address
		jnz	maskLoop
scanLoop:
		call	bx			; do next scan line
		loop	scanLoop
done:
		.leave
		ret

		; if there's a mask, need an extra part to the loop
maskLoop:
		call	FlipMono		; flip the mask bits
		call	bx			; flip the data bits
		loop	maskLoop
		jmp	done
MirrorBitmapBits endp


mirrorScanTable	label	nptr
		nptr	offset FlipMono		; mono, no mask
		nptr	offset Flip4Bit		; 4bit, no mask
		nptr	offset Flip8Bit		; 8bit, no mask
		nptr	offset FlipRGB		; 24bit, no mask


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FlipMono
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mirror one scan line of a monochrome bitmap

CALLED BY:	INTERNAL
		MirrorBitmapBits

PASS:		ds:si	- points at bitmap
		di	- offset into structure of scan line to mirror

RETURN:		di	- offset to next scan line

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		swap all the bytes, then all the bits in the bytes, then
		shift the line down if needed

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FlipMono	proc	near
		uses	ax,bx,cx,dx,si
		.enter	

		; get the width of the scan line in bytes

		mov	cx, ds:[si].B_width	; get width
		mov	ax, cx			; save low bits for later
		add	cx, 7			; round up
		shr	cx, 1			; divide by 8 to get #bytes
		shr	cx, 1
		shr	cx, 1			; cx = #bytes/scan/plane

		; save some stuff for the end of the routine

		push	cx, di			; save data pointer, size

		; get a pointer to the end of the scan line

		mov	si, di			; save initial data pointer
		add	di, cx			; points past end
		dec	di			; points at last byte
		mov	bx, offset flipMonoBitsTable ; get pointer to table
		and	al, 0x7			; # of bits in last byte
		mov	cl, 8
		sub	cl, al	
		and	cl, 0x7			; cl = # of bits to shift left

		; now xchg all the bytes and the bits in the bytes
flipLoop:
		mov	al, ds:[si]		; get left byte
		xlat	cs:flipMonoBitsTable
		xchg	al, ds:[di]		; write it out
		dec	di			; one less on that end
		cmp	si, di			; see if done
		jg	checkShift		;  yes, shift down
		xlat	cs:flipMonoBitsTable
		xchg	al, ds:[si]		; write it out
		inc	si			; one less on that end
		cmp	si, di			; see if done
		jle	flipLoop		;  nope, continue

		; we're all done with flipping, now make sure the scanline 
		; is left aligned.  cl has the shift amount
checkShift:
		pop	dx, di			; restore scan size, init ptr
		tst	cl			; if this is zero, we can leave
		jz	calcNewScanPointer

		; we need to do some shifting.  We will need to be shifting
		; two adjacent bytes into one, saving what is left over.

		call	LeftAdjustScanLine	; shift it down

		; We're done with this scan line.  Calc the pointer to the next
calcNewScanPointer:
		add	di, dx			; calc final data pointer
		.leave
		ret
FlipMono	endp

flipMonoBitsTable label	byte
		byte	0x00, 0x80, 0x40, 0xc0, 0x20, 0xa0, 0x60, 0xe0
		byte	0x10, 0x90, 0x50, 0xd0, 0x30, 0xb0, 0x70, 0xf0
		byte	0x08, 0x88, 0x48, 0xc8, 0x28, 0xa8, 0x68, 0xe8
		byte	0x18, 0x98, 0x58, 0xd8, 0x38, 0xb8, 0x78, 0xf8
		byte	0x04, 0x84, 0x44, 0xc4, 0x24, 0xa4, 0x64, 0xe4
		byte	0x14, 0x94, 0x54, 0xd4, 0x34, 0xb4, 0x74, 0xf4
		byte	0x0c, 0x8c, 0x4c, 0xcc, 0x2c, 0xac, 0x6c, 0xec
		byte	0x1c, 0x9c, 0x5c, 0xdc, 0x3c, 0xbc, 0x7c, 0xfc
		byte	0x02, 0x82, 0x42, 0xc2, 0x22, 0xa2, 0x62, 0xe2
		byte	0x12, 0x92, 0x52, 0xd2, 0x32, 0xb2, 0x72, 0xf2
		byte	0x0a, 0x8a, 0x4a, 0xca, 0x2a, 0xaa, 0x6a, 0xea
		byte	0x1a, 0x9a, 0x5a, 0xda, 0x3a, 0xba, 0x7a, 0xfa
		byte	0x06, 0x86, 0x46, 0xc6, 0x26, 0xa6, 0x66, 0xe6
		byte	0x16, 0x96, 0x56, 0xd6, 0x36, 0xb6, 0x76, 0xf6
		byte	0x0e, 0x8e, 0x4e, 0xce, 0x2e, 0xae, 0x6e, 0xee
		byte	0x1e, 0x9e, 0x5e, 0xde, 0x3e, 0xbe, 0x7e, 0xfe
		byte	0x01, 0x81, 0x41, 0xc1, 0x21, 0xa1, 0x61, 0xe1
		byte	0x11, 0x91, 0x51, 0xd1, 0x31, 0xb1, 0x71, 0xf1
		byte	0x09, 0x89, 0x49, 0xc9, 0x29, 0xa9, 0x69, 0xe9
		byte	0x19, 0x99, 0x59, 0xd9, 0x39, 0xb9, 0x79, 0xf9
		byte	0x05, 0x85, 0x45, 0xc5, 0x25, 0xa5, 0x65, 0xe5
		byte	0x15, 0x95, 0x55, 0xd5, 0x35, 0xb5, 0x75, 0xf5
		byte	0x0d, 0x8d, 0x4d, 0xcd, 0x2d, 0xad, 0x6d, 0xed
		byte	0x1d, 0x9d, 0x5d, 0xdd, 0x3d, 0xbd, 0x7d, 0xfd
		byte	0x03, 0x83, 0x43, 0xc3, 0x23, 0xa3, 0x63, 0xe3
		byte	0x13, 0x93, 0x53, 0xd3, 0x33, 0xb3, 0x73, 0xf3
		byte	0x0b, 0x8b, 0x4b, 0xcb, 0x2b, 0xab, 0x6b, 0xeb
		byte	0x1b, 0x9b, 0x5b, 0xdb, 0x3b, 0xbb, 0x7b, 0xfb
		byte	0x07, 0x87, 0x47, 0xc7, 0x27, 0xa7, 0x67, 0xe7
		byte	0x17, 0x97, 0x57, 0xd7, 0x37, 0xb7, 0x77, 0xf7
		byte	0x0f, 0x8f, 0x4f, 0xcf, 0x2f, 0xaf, 0x6f, 0xef
		byte	0x1f, 0x9f, 0x5f, 0xdf, 0x3f, 0xbf, 0x7f, 0xff


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Flip4Bit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mirror one scan line of a 4bit color bitmap

CALLED BY:	INTERNAL
		MirrorBitmapBits

PASS:		ds:si	- points at bitmap
		di	- offset into structure of scan line to mirror

RETURN:		di	- offset to next scan line

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		swap all the bytes, then all the bits in the bytes, then
		shift the line down if needed

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Flip4Bit	proc	near
		uses	ax,bx,cx,dx,si
		.enter	

		; get the width of the scan line in bytes

		mov	cx, ds:[si].B_width	; get width
		mov	ax, cx			; save low bits for later
		inc	cx			; round up
		shr	cx, 1			; divide by 2 to get #bytes

		; save some stuff for the end of the routine

		push	cx, di			; save data pointer, size

		; get a pointer to the end of the scan line

		mov	si, di			; save initial data pointer
		add	di, cx			; points past end
		dec	di			; points at last byte
		mov	ch, al			; get low bits of width
		and	ch, 0x1			; calc shift amount
		mov	cl, 4			; we need to rotate by 4 bits

		; now xchg all the bytes and the bits in the bytes
flipLoop:
		mov	al, ds:[si]		; get left byte
		ror	al, cl			; rotate 4 bits
		xchg	al, ds:[di]		; write it out
		dec	di			; one less on that end
		cmp	si, di			; see if done
		jg	checkShift		;  yes, shift down
		ror	al, cl			; rotate 4 bits
		xchg	al, ds:[si]		; write it out
		inc	si			; one less on that end
		cmp	si, di			; see if done
		jle	flipLoop		;  nope, continue

		; we're all done with flipping, now make sure the scanline 
		; is left aligned.  cl has the shift amount
checkShift:
		pop	dx, di			; restore scan size, init ptr
		tst	ch			; if this is zero, we can leave
		jz	calcNewScanPointer

		; we need to do some shifting.  We will need to be shifting
		; two adjacent bytes into one, saving what is left over.
		; Note that cl already holds 4, the bit shift amount

		call	LeftAdjustScanLine	; shift it left

		; We're done with this scan line.  Calc the pointer to the next
calcNewScanPointer:
		add	di, dx			; calc final data pointer
		.leave
		ret
Flip4Bit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LeftAdjustScanLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Shift a scan line down if neccesary

CALLED BY:	INTERNAL
		FlipMono, Flip4Bit...

PASS:		dx	- #bytes in the scan line
		cl	- amount to shift
		ds:di	- points to beginning of scan line

RETURN:		nothing

DESTROYED:	ax,bl,si

PSEUDO CODE/STRATEGY:
		just shift it on down

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LeftAdjustScanLine proc	near
		uses	dx, di, es
		.enter
		dec	dx			; do the last one specially
		mov	si, di			; ds:si -> beginning of line
		segmov	es, ds, bx		; es:di -> scan line
		xchg	dx, cx			; get size, shift amount set
		lodsb				; get first two bytes
		mov	bl, al			; save 2nd byte
		tst	cx			; if only one byte, handle it
		jz	doLastByte
shiftLoop:
		xchg	dx, cx			; get cl = shift amount
		mov	ah, bl			; get old bits
		lodsb				; get next byte
		mov	bl, al			; save if for next time
		shl	ax, cl			; ah = new byte
		mov	al, ah			; get ready to save
		stosb				; save the byte
		xchg	dx, cx			; cx = #bytes to do
		loop	shiftLoop
doLastByte:
		xchg	dx, cx			; cl = shift count
		clr	al
		mov	ah, bl			; set up the last one
		shl	ax, cl
		mov	al, ah			; get ready to store
		stosb
		.leave
		ret
LeftAdjustScanLine endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Flip8Bit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mirror one scan line of an 8bit color bitmap

CALLED BY:	INTERNAL
		MirrorBitmapBits

PASS:		ds:si	- points at bitmap
		di	- offset into structure of scan line to mirror
		BitmapFrame structure on stack

RETURN:		di	- offset to next scan line

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		swap all the bytes

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Flip8Bit	proc	near
		uses	ax,bx,cx,dx,si
		.enter	

		; get the width of the scan line in bytes

		mov	cx, ds:[si].B_width	; get width

		; get a pointer to the end of the scan line

		mov	si, di			; save initial data pointer
		add	di, cx			; points past end
		push	di			; save final pointer
		dec	di			; points at last byte

		; now xchg all the bytes and the bits in the bytes
flipLoop:
		mov	al, ds:[si]		; get left byte
		xchg	al, ds:[di]		; write it out
		dec	di			; one less on that end
		cmp	si, di			; see if done
		jg	doneFlipping		;  yes, all done
		xchg	al, ds:[si]		; write it out
		inc	si			; one less on that end
		cmp	si, di			; see if done
		jle	flipLoop		;  nope, continue

doneFlipping:
		pop	di
		.leave
		ret
Flip8Bit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FlipRGB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mirror one scan line of a 24bit color bitmap

CALLED BY:	INTERNAL
		MirrorBitmapBits

PASS:		ds:si	- points at bitmap
		di	- offset into structure of scan line to mirror
		BitmapFrame structure on stack

RETURN:		di	- offset to next scan line

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		swap all the bytes

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FlipRGB		proc	near
		uses ax,bx,cx,dx,si
		.enter	

		; get the width of the scan lines in bytes

		mov 	cx, ds:[si].B_width	; get width

		; get a pointer to the end of the scan line

		mov 	si, di			; save initial data
						; pointer

		add 	di, cx			; point past end

		add 	di,cx			; 3 bytes = 1 pixel
		add 	di,cx
		push 	di			; save final pointer
		sub 	di, 3			; points at last byte

	
		; now xchg all teh bytes and the bits in the bytes

	flipLoop:

		mov	ax, ds:[si]		; get left byte
		xchg	ax, ds:[di]		; write it out
		mov	bl, ds:[si+2]		; get left byte
		xchg	bl, ds:[di+2]		; write it out

		sub	di, 3			; one less on that end
		cmp	si, di			; see if done
		jg	doneFlipping		; yes, all done

		xchg	ax, ds:[si]		; write it out
		xchg	bl, ds:[si+2]

		add	si, 3			; one less on that end
		cmp	si, di			; see if done
		jle	flipLoop		; nope, continue

	doneFlipping:
		
		pop	di
		.leave
		ret

;		; the original proc appears below ...
;		; the RGB format is just 3 8-bit/pixel planes
;
;		call	Flip8Bit		; just do it in three calls
;		call	Flip8Bit		
;		call	Flip8Bit
;
;		.leave
;		ret

FlipRGB		endp

GraphicsScaleRaster 	ends


