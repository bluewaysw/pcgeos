COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		KernelGraphics
FILE:		Graphics/graphicsImage.asm

AUTHOR:		Jim DeFrisco

ROUTINES:
	Name		Description
	----		-----------
    GLB GrDrawImage

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	jim	7/92	initial version


DESCRIPTION:
	This file contains the application interface for GrDrawImage

	$Id: graphicsImage.asm,v 1.1 97/04/05 01:12:51 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


GraphicsImage	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrDrawImage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a bitmap, possibly in FatBit mode

CALLED BY:	GLOBAL

PASS:		di	- GState handle
		ax,bx	- document position to draw bitmap
		cl	- Record of type ImageFlags

			ImageFlags	record
			    IF_BORDER:1,		; set for border
			    IF_BITSIZE ImageBitSize:3	; pixel size
			ImageFlags	end

			ImageBitSize enum {IBS_1, IBS_2, IBS_4, IBS_8, IBS_16}

		dx:si	- far pointer to bitmap

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
				

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Pixel size includes border.
		Border is drawn using the current line color.
		Border bit is ignored for pixel size IBS_1
		No GString opcode exists.
		Does not affect the current pen position.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	7/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrDrawImage	proc	far
BMframe		local	BitmapFrame
		
if	FULL_EXECUTE_IN_PLACE
EC <		xchg	bx, dx				>
EC <		call	ECAssertValidFarPointerXIP	>
EC <		xchg	bx, dx				>
endif		
		and	cl, not mask IF_HUGE	; ensure it's not Huge
drawImageCommon	label	near
		call	EnterGraphics
		jnc	drawIt			; we don't do GStrings

		; we don't do graphics strings.

		jmp	ExitGraphicsGseg
drawIt:
		call	TrivialRejectFar	; won't return if no window

		; OK, it's for real.  Transform the draw point and save it
		; away in the bitmap stack frame.  We don't really need the 
		; whole stack frame, but we might was well make use of it, 
		; since we need part of it for calling the video driver
		; anyway (for the 1-bit/pixel case).  Save area color &
		; the map mode, since we screw with it.

		.enter
		push	{word} ds:[GS_areaAttr].CA_mapMode
		push	{word} ds:[GS_areaAttr].CA_colorRGB
		push	{word} ds:[GS_areaAttr].CA_colorRGB.RGB_blue
		push	{word} ds:[GS_areaAttr].CA_flags-1

		; Set area-map-mode to be dither, to match bitmap code
		; for monochrome displays/bitmaps. This does not affect
		; color bitmaps, as we map each pixel directly to a
		; a color that is present in the window's palette. If
		; we are not in fatbits mode, then this value is ignored.

		or	ds:[GS_areaAttr].CA_mapMode, mask CMM_MAP_TYPE
		
		; store the starting position (& error in that position)
		; for the bitmap (assumes document coord for bitmap origin
		; is in (ax, bx))

		call	BitmapSetDrawPoint	; window coords -> (ax, bx)
		jc	exit

		; If it's off the right hand size of the window, then we can
		; bail (there is no negative scaling allowed).  Also, if the
		; y coordinate is below the bottom, we can bail.

		cmp	ax, es:[W_winRect].R_right	; check right side
		jg	exit
		cmp	bx, es:[W_winRect].R_bottom	; check bottom
		jg	exit
		or	cl, mask IF_DRAW_IMAGE		; set bit for image
		mov	BMframe.BF_imageFlags, cl	; save other params
		xchg	bx, cx				; save bx
		and	bl, mask IF_BITSIZE
		clr	bh				; figure expansion
		mov	bl, cs:[pixelTable][bx]		; bl = pixel size
		mov	BMframe.BF_ybump, bx		; save size
		xchg	bx, cx				; restore bx
		movdw	BMframe.BF_origBM, dxsi		
		movdw	BMframe.BF_finalBM, dxsi		
		clr	ax
		mov	BMframe.BF_cbFunc.segment, ax 	; save ptr to callback
		mov	BMframe.BF_finalBMsliceSize, ax	; init # bytes/scanline
		mov	BMframe.BF_getSliceDSize, ax	; init callback flag 
		mov	BMframe.BF_opType,  al 	    	; init function pointer
		mov	BMframe.BF_args.PBA_flags, ax	; init flags

		; here we part ways for initializations that depend on whether
		; the bitmap is HUGE or not.

		test	BMframe.BF_imageFlags, mask IF_HUGE	; if huge...
		jnz	initHuge
		call	ImageNormalBitmap

		; restore area color
exit:
		pop	{word} ds:[GS_areaAttr].CA_flags-1
		pop	{word} ds:[GS_areaAttr].CA_colorRGB.RGB_blue
		pop	{word} ds:[GS_areaAttr].CA_colorRGB
		pop	{word} ds:[GS_areaAttr].CA_mapMode
		.leave
		jmp	ExitGraphics		; 

		; we have a big one.  Deal with it appropriately.
initHuge:
		call	ImageHugeBitmap
		jmp	exit

GrDrawImage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrDrawHugeImage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a huge bitmap, possibly in FatBit mode

CALLED BY:	GLOBAL

PASS:		di	- GState handle
		ax,bx	- document position to draw bitmap
		cl	- Record of type ImageFlags

			ImageFlags	record
			    IF_BORDER:1,		; set for border
			    IF_BITSIZE ImageBitSize:3	; pixel size
			ImageFlags	end

			ImageBitSize enum {IBS_1, IBS_2, IBS_4, IBS_8, IBS_16}

		dx	- VM file handle holding Huge bitmap
		si	- VM block handle holding beginning of Huge bitmap

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
				

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Pixel size includes border.
		Border is drawn using the current line color.
		Border bit is ignored for pixel size IBS_1
		No GString opcode exists.
		Does not affect the current pen position.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	7/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrDrawHugeImage	proc	far
		or	cl, mask IF_HUGE	; set HUGE flag
		jmp	drawImageCommon 	; and fall into GrDrawImage
GrDrawHugeImage	endp			


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImageNormalBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do some simple bitmap initialization.

CALLED BY:	INTERNAL
		GrDrawImage
PASS:		inherits BitmapFrame
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	7/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImageNormalBitmap	proc	near
		uses	ax, bx, cx, dx, si, di, ds
BMframe		local	BitmapFrame
		.enter	inherit

		; get the format of the video buffer (bits/pixel)

		mov	cx, ds			; save GState seg
		mov	di, DR_VID_INFO		; get ptr to info table
		call	es:[W_driverStrategy]	; driver knows where
		mov	ds, dx			; set ds:si -> table
		mov	dl, ds:[si].VDI_bmFormat ; bitmap format supp
		and	dl, mask BMT_FORMAT	; only interested in bits/pix
		mov	BMframe.BF_deviceType, dl ; and save it

		; check if we need to allocate a supplementary buffer

		mov	ds, BMframe.BF_finalBM.segment	; get ptr to bitmap
		mov	si, BMframe.BF_finalBM.offset	;  and offset
		mov	dl, ds:[si].B_type	; get color format
EC <		mov	dh, dl			; save it		>
EC <		and	dh, mask BMT_FORMAT				>
EC <		cmp	dh, BMF_4CMYK		; don't do this		>
EC <		ERROR_E	GRAPHICS_CMYK_BITMAPS_NOT_SUPPORTED		>

		; see if we need to do some massaging of the data
		; if there is any compaction, we need to alloc a block

		cmp	ds:[si].B_compact, BMC_UNCOMPACTED ; alloc if compacted
		jnz	allocExtra
		cmp	dl, BMF_MONO		; if mono, ok
		je	noAlloc			; skip if mono (carry clr)
		test	BMframe.BF_imageFlags, mask IF_BITSIZE	; get bitsize
		jnz	noAlloc
		cmp	BMframe.BF_deviceType, dl ; need to translate ?
		jb	allocExtra

		; nothing complicated about this bitmap.  just draw it.
		; fill in the header info, then loop to do each piece.  
		; cx = GState segment
noAlloc:
		mov	dx, cx			; save gstate segment
		mov	BMframe.BF_args.PBA_data.segment, ds
		mov	BMframe.BF_args.PBA_data.offset, si
		mov	cx, ds:[si].B_width	; copy over right pieces
		mov	BMframe.BF_args.PBA_bm.B_width, cx
		and	ah, not mask BMT_COMPLEX	; never passing cmplx..
		mov	ax, {word} ds:[si].B_compact
		mov	{word} BMframe.BF_args.PBA_bm.B_compact, ax
		xchg	al, ah			; al = B_type
		call	CalcLineSize		; ax = line size
		mov	BMframe.BF_args.PBA_size, ax

		; if there is a palette stored with the bitmap, then pass
		; that information to the video driver

		mov	cl, ds:[si].B_type	; grab type information
		test	cl, mask BMT_PALETTE	; see if there is one there
		jz	paletteHandled
		call	InitBitmapPalette
paletteHandled:
		add	BMframe.BF_args.PBA_data.offset, size Bitmap
		mov	cx, ds:[si].B_height	; store  height
		mov	BMframe.BF_args.PBA_bm.B_height, cx
		mov	ds, dx			; restore gState seg
		mov	ax, BMframe.BF_drawPoint.P_x
		mov	bx, BMframe.BF_drawPoint.P_y
		call	ImageHugeSection	; draw this bitmap
		
		; all done drawing the bitmap.  If we allocated some space
		; to store a palette, then release the block
BF_end:
		test	BMframe.BF_args.PBA_flags, mask PBF_ALLOC_PALETTE
		jz	palFreed
		mov	bx, {word} BMframe.BF_palette	; get handle
		call	MemFree			; release block
palFreed:
		.leave				; restore stack
		ret

;-------------------------------------------------------------------------

		; need to alloc some space, use different routine.  This will
		; end up drawing the whole thing.
allocExtra:
		call	DrawSlice		; alloc and draw
		jmp	short BF_end

ImageNormalBitmap	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImageHugeBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do some Huge bitmap initialization.

CALLED BY:	INTERNAL
		GrDrawImage
PASS:		inherits BitmapFrame
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di, si	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	7/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImageHugeBitmap		proc	near
		uses	ds
BMframe		local	BitmapFrame
		.enter	inherit

		; get the format of the video buffer (bits/pixel)

		mov	cx, ds			; save GState seg
		mov	di, DR_VID_INFO		; get ptr to info table
		call	es:[W_driverStrategy]	; driver knows where
		mov	ds, dx			; set ds:si -> table
		mov	dl, ds:[si].VDI_bmFormat ; bitmap format supp
		and	dl, mask BMT_FORMAT
		mov	BMframe.BF_deviceType, dl ; and save it

		; access the bitmap header to see if we need to allocate more
		; room.

		mov	bx, BMframe.BF_origBM.segment	; get file handle
		mov	di, BMframe.BF_origBM.offset	; get block handle
		call	HugeArrayLockDir
		mov	ds, ax				; ds -> dir block
		mov	si, offset EB_bm		; ds:si -> bitmap hdr
		mov	dl, ds:[si].B_type	; get color format
		and	dl, mask BMT_FORMAT
EC <		cmp	dl, BMF_4CMYK		; don't do this		>
EC <		ERROR_E	GRAPHICS_CMYK_BITMAPS_NOT_SUPPORTED		>

		; see if we need to do some massaging of the data
		; if there is any compaction, we need to alloc a block

		cmp	ds:[si].B_compact, BMC_UNCOMPACTED ; alloc if compacted
		jnz	allocExtra
		cmp	dl, BMF_MONO		; if mono, ok
		je	noAlloc			; skip if mono (carry clr)
		test	BMframe.BF_imageFlags, mask IF_BITSIZE	; get bitsize
		jnz	noAlloc
		cmp	BMframe.BF_deviceType, dl ; need to translate ?
		jb	allocExtra

		; nothing complicated about this bitmap.  just draw it.
		; fill in the header info, then loop to do each piece.  
		; cx = GState segment, bx = HugeArrayDir mem block handle
noAlloc:
		mov	dx, cx			; save gstate segment

		; while we have the header locked, check for a palette

		mov	cl, ds:[si].B_type	; grab flag
		test	cl, mask BMT_PALETTE	; is there one ?
		jz	paletteHandled		;  nope, continue
		call	InitBitmapPalette	; do some initialization
paletteHandled:
		mov	ax, ds:[si].B_height	; get total height
		mov	BMframe.BF_origBMheight, ax ; store for later
		mov	BMframe.BF_origBMscansLeft, ax ; store for later
		mov	cx, ds:[si].B_width	; copy over right pieces
		mov	BMframe.BF_args.PBA_bm.B_width, cx
		mov	ax, {word} ds:[si].B_compact
		and	ah, not mask BMT_COMPLEX	; clear this by default
		mov	{word} BMframe.BF_args.PBA_bm.B_compact, ax
		xchg	al, ah			; al = B_type
		call	CalcLineSize		; ax = line size
		mov	BMframe.BF_args.PBA_size, ax
		call	HugeArrayUnlockDir	; unlock HugeArray dir block
		clr	ax			;  start at scan line zero

		; lock down the next set of scan lines, draw the bitmap
		; in the appropriate scale factor.

		call	DrawSimpleHugeImage	; go thru all the blocks...
hBitmapEnd:
		test	BMframe.BF_args.PBA_flags, mask PBF_ALLOC_PALETTE
		jz	palFreed
		mov	bx, {word} BMframe.BF_palette	; get handle
		call	MemFree			; release block
palFreed:
		.leave				; restore stack
		ret

;-------------------------------------------------------------------------

		; need to alloc some space, use different routine.  This will
		; end up drawing the whole thing.
allocExtra:
		push	ds			; save HugeArrayDir blk han
		call	DrawSlice		; alloc and draw
		pop	ds
		call	HugeArrayUnlockDir	; release dir block
		jmp	hBitmapEnd

ImageHugeBitmap		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawSimpleHugeImage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a huge bitmap, no allocation needed.

CALLED BY:	INTERNAL
		ImageHugeBitmap
PASS:		inherits stack frame 
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	7/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawSimpleHugeImage	proc	near
		uses	ax, bx, cx, dx, di, si, ds
BMframe		local	BitmapFrame
		.enter	inherit

		; loop through all the blocks in the HugeArray.  The lower
		; level routine will decide which method to use to draw the
		; pixels.
lockNextBlock:
		push	ax			      	; save curr scan line
		push	dx			      	; save GState segment 
		clr	dx
		mov	bx, BMframe.BF_origBM.segment 	; get file handle
		mov	di, BMframe.BF_origBM.offset  	; get block handle
		call	HugeArrayLock		      	; ds:si -> element
		mov	BMframe.BF_args.PBA_bm.B_height, ax ; store #lines 
		mov	BMframe.BF_args.PBA_data.offset, si
		mov	BMframe.BF_args.PBA_data.segment, ds
		pop	ds			      	; restore GState
		pop	bx			      	; restore current scan
		push	bx			      	; save for vid call
		push	ax				; save height of sect
		mov	ax, bx				; mul by pixel height
		mov	bx, BMframe.BF_ybump
		mul	bx
		mov	bx, ax				; bx = curScan * size
		mov	ax, BMframe.BF_drawPoint.P_x
		add	bx, BMframe.BF_drawPoint.P_y
		call	ImageHugeSection		; do a section...
		pop	ax				; restore section hght
		jc	rejectRest
		mov	dx, ds			      	; save GState segment
		mov	ds, BMframe.BF_args.PBA_data.segment
		call	HugeArrayUnlock
		pop	bx			      	; restore scan, GState
		add	ax, bx				; see if we're done
		cmp	ax, BMframe.BF_origBMscansLeft 	; done with bitmap ?
		jb	lockNextBlock
done:
		.leave
		ret

		; reject the rest of the bitmap
rejectRest:
		mov	dx, ds
		mov	ds, BMframe.BF_args.PBA_data.segment
		call	HugeArrayUnlock
		pop	ax			      	; restore scan
		jmp	done
DrawSimpleHugeImage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImageHugeSection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a single block of a HugeArray bitmap, applying the
		appropriate image flags.

CALLED BY:	INTERNAL
		DrawSimpleHugeImage
PASS:		inherits BitmapFrame
		ax,bx	- position to draw section (device coords)
		ds	- GState

RETURN:		carry	- set if we're done (rest of bitmap can be rejected)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	7/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImageHugeSectionFar	proc	far
		call	ImageHugeSection
		ret
ImageHugeSectionFar	endp

ImageHugeSection	proc	near
BMframe		local	BitmapFrame
		.enter	inherit

		; if it's a 1-to-1 mapping, use the video driver.  Else step
		; through the whole block, drawing rectangles.

		test	BMframe.BF_imageFlags, mask IF_BITSIZE
		jnz	doRectangles

		; it's one-to-one, just use video driver

		mov	BMframe.BF_args.PBA_flags, 0
		mov	di, DR_VID_PUTBITS
		call	es:[W_driverStrategy]
		clc
done:
		.leave
		ret

		; it's more than 1-to-1.  Draw rectangles.
doRectangles:
		mov	BMframe.BF_rotUpLeft.P_x, ax ; save current draw point
		mov	BMframe.BF_rotUpLeft.P_y, bx
nextScan:
		call	DrawImageScan		; draw one scan line 
		jc	doneRects		; check past window...
		mov	ax, BMframe.BF_ybump	; advance draw position
		add	BMframe.BF_rotUpLeft.P_y, ax
		mov	ax, BMframe.BF_args.PBA_size
		add	BMframe.BF_args.PBA_data.offset, ax
		dec	BMframe.BF_args.PBA_bm.B_height ; one less scan to do.
		jnz	nextScan
		clc
doneRects:
		jmp	done
ImageHugeSection	endp


pixelTable	label	byte
		byte	1		; IBS_1
		byte	2		; IBS_2
		byte	4		; IBS_4
		byte	8		; IBS_8
		byte	16		; IBS_16



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawImageScan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw one scan line of a bitmap, in fatbits mode

CALLED BY:	INTERNAL
		ImageHugeSection, others
PASS:		inherits BitmapFrame
RETURN:		carry	- set if scan line is below the window
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	7/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BF_curPointX equ <BF_curPoint.WWF_frac>
BF_curPointY equ <BF_curPoint.WWF_int>

DrawImageScan	proc	near
BMframe		local	BitmapFrame
		.enter	inherit

		; check for scan line past the end of the window
	
		mov	bx, BMframe.BF_rotUpLeft.P_y
		mov	BMframe.BF_curPointY, bx
		cmp	bx, es:[W_winRect].R_bottom
		jle	drawScan
		stc	
		jmp	done

		; draw all the rectangles in all their radiant beauty.
drawScan:
		add	bx, BMframe.BF_ybump			; see if above
		cmp	bx, es:[W_winRect].R_top		;  window
		jl	doneOK
		clr	BMframe.BF_count			; on pix zero
		movdw	BMframe.BF_curPoint, BMframe.BF_rotUpLeft, ax
newColor:
		mov	si, ds
		xchg	si, BMframe.BF_args.PBA_data.segment 	; save GState
		mov	ds, si
		mov	si, BMframe.BF_args.PBA_data.offset	; ds:si -> data

		mov	bl, BMframe.BF_args.PBA_bm.B_type	; get type
		and	bl, mask BMT_FORMAT
		clr	bh					; table index
		shl	bx, 1					; word table
		call	cs:[getPixelTable][bx]			; get next clr
								; cx = #pixs
		pushf
		add	BMframe.BF_count, cx
		mov	ax, ds
		xchg	ax, BMframe.BF_args.PBA_data.segment 	; save GState
		mov	ds, ax
		mov	ax, BMframe.BF_ybump			; pixel size
		mul	cx					; ax = #pixels
		mov	cx, ax
		mov	ax, BMframe.BF_curPointX		; start coord
		add	cx, ax
		mov	BMframe.BF_curPointX, cx		; start coord
		popf						; restore carry
		jc	rectDrawn				;  if set, skip
		mov	bx, BMframe.BF_curPointY
		mov	dx, bx
		add	dx, BMframe.BF_ybump
		test	BMframe.BF_imageFlags, mask IF_BORDER	; if border...
		jz	drawRect
		dec	cx
		dec	dx
drawRect:
		mov	si, offset GS_areaAttr
		call	CallVidRect
rectDrawn:
		mov	cx, BMframe.BF_count			; get pixel #
		cmp	cx, BMframe.BF_args.PBA_bm.B_width	; done ?
		jae	doneRect
		mov	cx, BMframe.BF_curPointX		; past window ?
		cmp	cx, es:[W_winRect].R_right		;  if so, done
		jle	newColor
		
		; do things different if there is a border to contend with.
doneRect:
		test	BMframe.BF_imageFlags, mask IF_BORDER	; if border...
		jnz	handleBorder
doneOK:
		clc
done:
		.leave
		ret

		; there's a border around each pixel.  Draw it.
		; Draw "underline" first, then each individual one.
handleBorder:
		mov	cx, BMframe.BF_count			; do this many
		mov	ax, BMframe.BF_ybump			; get size
		mul	cx
		mov	cx, ax
		mov	ax, BMframe.BF_rotUpLeft.P_x
		add	cx, ax
		mov	bx, BMframe.BF_rotUpLeft.P_y
		add	bx, BMframe.BF_ybump
		dec	bx
		mov	dx, bx
		mov	si, offset GS_lineAttr
		call	CallVidRect

		; now do all of the vertical lines

		mov	cx, BMframe.BF_count			; this manyu
		mov	ax, BMframe.BF_rotUpLeft.P_x
		add	ax, BMframe.BF_ybump
		dec	ax
		mov	bx, BMframe.BF_rotUpLeft.P_y
		mov	dx, bx
		add	dx, BMframe.BF_ybump
		dec	dx
vertLoop:
		push	cx
		mov	cx, ax
		mov	si, offset GS_lineAttr
		push	ax,bx,cx,dx
		call	CallVidRect
		pop	ax,bx,cx,dx
		add	ax, BMframe.BF_ybump
		pop	cx
		loop	vertLoop
		jmp	doneOK
DrawImageScan	endp

getPixelTable	label	nptr.near
		word	offset GetMonoPixelRun
		word	offset Get4BitPixelRun
		word	offset Get8BitPixelRun
		word	offset Get24BitPixelRun


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallVidRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Front end for calling video driver

CALLED BY:	INTERNAL
		DrawImageScan
PASS:		ax...dx	- rectangle coords
		es	- Window structure
		ds	- GState structure
RETURN:		nothing
DESTROYED:	ax...dx

PSEUDO CODE/STRATEGY:
		do some clip checking and call the video driver

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	8/ 3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CallVidRect	proc	near

		; If the coords are equal, then don't mess with them (that is,
		; don't adjust right/bottom).  This means that nothing should
		; disappear by getting scaled too small.  This kind of violates
		; the imaging conventions, but was deemed appropriate by a
		; panel of impartial jurors.

		cmp	ax, cx			; check min/max in x
		je	adjustY
		dec	cx			; adjust for imaging convention
adjustY:
		cmp	bx, dx			; check min/max in y
		je	checkCoords
		dec	dx			; adjust for imaging convention

		; check for trivial reject for clipping and clip to wMask
		; bounds at the same time
		; LEFT
checkCoords:
		mov	di, es:[W_maskRect].R_left
		cmp	cx, di
		jl	done				;  reject: before left
		cmp	ax, di				; clip to left
		jg	checkRight
		mov	ax, di

		; RIGHT
checkRight:
		mov	di, es:[W_maskRect].R_right
		cmp	ax, di
		jg	done				;  reject: past right
		cmp	cx, di				; past to right
		jl	checkTop
		mov	cx, di

		; TOP
checkTop:
		mov	di, es:[W_maskRect].R_top
		cmp	dx, di
		jl	done				;  reject: above top
		cmp	bx, di				; clip to top
		jg	checkBottom
		mov	bx, di

		; BOTTOM
checkBottom:
		mov	di, es:[W_maskRect].R_bottom
		cmp	bx, di
		jg	done				;  reject: below bottom
		cmp	dx, di				; clip to bottom
		jl	drawRect
		mov	dx, di

		; all clear file away
drawRect:
		mov	di, DR_VID_RECT
		push	bp, si				; save frame pointer
		call	es:[W_driverStrategy]		; make call to driver
		pop	bp, si				; restore frame pointer
done:
		ret

CallVidRect	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetMonoPixelRun
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a run of pixels from a monochrome bitmap

CALLED BY:	INTERNAL
		DrawImageScan
PASS:		inherits BitmapFrame
		ds:si	- points to beginning of scan line
RETURN:		cx	- number of pixels in the run

		carry	- if set, run is masked (not to be drawn) pixels
			  if clear, run is normal pixels, and color is setup

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	7/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetMonoPixelRun	proc	near
		uses	ax, bx, dx
BMframe		local	BitmapFrame
		.enter	inherit

		; get a mask for the current pixel, then search for all like
		; pixels...

		mov	ax, BMframe.BF_args.PBA_bm.B_width ; calc max count
		mov	bx, BMframe.BF_count		; get current index
		sub	ax, bx				; ax = max count
		mov	dx, ax				; keep max count here
		mov	cx, bx				; get copy of index
		and	bx, 0x7				; isolate low three...
		mov	al, cs:[monoMaskTable][bx]	; al = bit mask
		mov	bx, cx
		mov	cl, 3
		shr	bx, cl

		; see if there is a mask with this bitmap.  If so, check to 
		; make sure we are treading on solid pixels.  

		test	BMframe.BF_args.PBA_bm.B_type, mask BMT_MASK
		jz	testPixel
		call	CheckMaskedPixels		; carry set if masked
		jc	done

		; test the pixel and branch on set/reset
testPixel:
		push	ax, bx, si
		mov	cl, GSTATE_LOCKED or LEAVE_GSTATE
		test	ds:[si][bx], al			; see if black/white
		mov	si, GS_areaAttr.CA_colorIndex	; offset to color info
		mov	ah, CF_INDEX
		mov	al, C_WHITE
		jnz	setPixelBlack			; find black pixels

		; OK, where doin' white ones.  Set the color and search
		; for more white pixels

		push	ds
		mov	ds, BMframe.BF_args.PBA_data.segment
		call	SetColor			; set current color
		pop	ds
		pop	ax, bx, si			; restore bit masks
		clr	cx				; init count

		; search for white pixels.  Do it one at a time until we hit 
		; the end of this byte.

		mov	ah, ds:[bx][si]			; get left byte
leftWhiteLoop:
		test	ah, al				; test for white
		jnz	haveCount			; done.
		inc	cx				; one more pixel
		cmp	cx, dx				; see if done with scan
		jae	haveCount
		shr	al, 1				; onto next pixel
		jnc	leftWhiteLoop

		; fallen out of loop.  Check bytes.
midWhiteLoop:
		inc	bx				; onto next byte
		mov	ah, ds:[bx][si]			; grab next data byte
		tst	ah				; if zero, OK
		jnz	doneMidWhite
		add	cx, 8				; eight pixels/byte
		cmp	cx, dx				; see if overboard
		je	haveCount			; exactly done
		jb	midWhiteLoop			; more to go...
		sub	cx, 8
doneMidWhite:
		mov	al, 0x80			; start on first pixel
rightWhiteLoop:
		test	ah, al				; same as left loop
		jnz	haveCount
		inc	cx
		cmp	cx, dx
		jae	haveCount
		shr	al, 1
		jnc	rightWhiteLoop
EC <		ERROR	GRAPHICS_BAD_IMAGE_DATA				>

haveCount:
		clc					; signal colored pixels
done:
		.leave
		ret

		; looking for black pixels.  First set the color.
setPixelBlack:
		mov	al, C_BLACK
		push	ds
		mov	ds, BMframe.BF_args.PBA_data.segment
		call	SetColor			; set current color
		pop	ds
		pop	ax, bx, si			; restore bit masks
		clr	cx				; init count

		; search for white pixels.  Do it one at a time until we hit 
		; the end of this byte.

		mov	ah, ds:[bx][si]			; get left byte
leftBlackLoop:
		test	ah, al				; test for white
		jz	haveCount			; done.
		inc	cx				; one more pixel
		cmp	cx, dx				; see if done with scan
		jae	haveCount
		shr	al, 1				; onto next pixel
		jnc	leftBlackLoop

		; fallen out of loop.  Check bytes.
midBlackLoop:
		inc	bx				; onto next byte
		mov	ah, ds:[bx][si]			; grab next data byte
		cmp	ah, 0xff			; if ones, OK
		jne	doneMidBlack
		add	cx, 8				; eight pixels/byte
		cmp	cx, dx				; see if overboard
		je	haveCount			; exactly done
		jb	midBlackLoop			; more to go...
		sub	cx, 8
doneMidBlack:
		mov	al, 0x80			; start on first pixel
rightBlackLoop:
		test	ah, al				; same as left loop
		jz	haveCount
		inc	cx
		cmp	cx, dx
		jae	haveCount
		shr	al, 1
EC <		ERROR_C	GRAPHICS_BAD_IMAGE_DATA				>
		jmp	rightBlackLoop
GetMonoPixelRun	endp

monoMaskTable	label	byte
		byte	0x80, 0x40, 0x20, 0x10, 0x08, 0x04, 0x02, 0x01


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckMaskedPixels
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for mask bits where we are looking for data bits. 

CALLED BY:	INTERNAL
		Get{Mono,4Bit,8Bit,24Bit}PixelRun
PASS:		inherits BitmapFrame
		dx	- #pixels left to do in this scan line
		ds:si	- pointer to start of data
RETURN:		carry	- set if we are on a masked out pixel, and
			  cx = #consecutive pixels masked
			- clear if we are not on a masked out pixel, and
			  dx = #consecutive pixels not masked, up to passed
			       maximum.
		si	- pointer to start of pixel (not mask) data.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Do a search similar to the GetMonoPixelRun search.  If the 
		run of mask bits is made up of 0s, then set the carry and 
		count the number of zeroes.  If it's made up of 1s, then
		clear the carry and return the minimum of either: (a) the 
		number of consecutive 1s or (b) the value passed in dx.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	7/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckMaskedPixels proc	near
		uses	ax, bx
BMframe		local	BitmapFrame
		.enter	inherit

		; get a mask for the current pixel, then search for all like
		; pixels...

		mov	ax, BMframe.BF_args.PBA_bm.B_width ; calc mask size
		add	ax, 7				; round up
		mov	cl, 3				; divide by 8
		shr	ax, cl

		; See if we're supposed to ignore the mask

		test	BMframe.BF_imageFlags, mask IF_IGNORE_MASK
		LONG jnz	advancePtr

		push	ax				; save size of mask
		mov	bx, BMframe.BF_count		; get current index
		mov	cx, bx				; get copy of index
		and	bx, 0x7				; isolate low three...
		mov	al, cs:[monoMaskTable][bx]	; al = bit mask
		mov	bx, cx
		mov	cl, 3
		shr	bx, cl

		; test the mask bit and branch on set/reset

		clr	cx				; init count
		mov	ah, ds:[bx][si]			; get left byte
		test	ah, al				; see if set/reset
		jnz	maskBitSet			; find set bits

		; OK, where not drawing for a while.  Find out how long.

leftClearLoop:
		test	ah, al				; test for clear
		jnz	haveClearCount			; done.
		inc	cx				; one more pixel
		cmp	cx, dx				; see if done with scan
		jae	haveClearCount
		shr	al, 1				; onto next pixel
		jnc	leftClearLoop

		; fallen out of loop.  Check bytes.
midClearLoop:
		inc	bx				; onto next byte
		mov	ah, ds:[bx][si]			; grab next data byte
		tst	ah				; if zero, OK
		jnz	doneMidClear
		add	cx, 8				; eight pixels/byte
		cmp	cx, dx				; see if overboard
		je	haveClearCount			; exactly done
		jb	midClearLoop			; more to go...
		sub	cx, 8
doneMidClear:
		mov	al, 0x80			; start on first pixel
rightClearLoop:
		test	ah, al				; same as left loop
		jnz	haveClearCount
		inc	cx
		cmp	cx, dx
		jae	haveClearCount
		shr	al, 1
		jnc	rightClearLoop
haveClearCount:
		pop	ax				; bump source pointer
		add	si, ax
		stc
done:
		.leave
		ret

		; looking for set mask bits
maskBitSet:
		test	ah, al				; test for white
		jz	haveSetCount			; done.
		inc	cx				; one more pixel
		cmp	cx, dx				; see if done with scan
		jae	haveSetCount
		shr	al, 1				; onto next pixel
		jnc	maskBitSet

		; fallen out of loop.  Check bytes.
midSetLoop:
		inc	bx				; onto next byte
		mov	ah, ds:[bx][si]			; grab next data byte
		cmp	ah, 0xff			; if ones, OK
		jne	doneMidSet
		add	cx, 8				; eight pixels/byte
		cmp	cx, dx				; see if overboard
		je	haveSetCount			; exactly done
		jb	midSetLoop			; more to go...
		sub	cx, 8
doneMidSet:
		mov	al, 0x80			; start on first pixel
rightSetLoop:
		test	ah, al				; same as left loop
		jz	haveSetCount
		inc	cx
		cmp	cx, dx
		jae	haveSetCount
		shr	al, 1
		jnc	rightSetLoop
haveSetCount:
		mov	dx, cx
		pop	ax				; bump over mask
advancePtr:
		add	si, ax
		clc
		jmp	done
CheckMaskedPixels endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Get4BitPixelRun
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a run of pixels from a 4Bit/pixel bitmap

CALLED BY:	INTERNAL
		DrawImageScan
PASS:		inherits BitmapFrame
		ds:si	- points to beginning of scan line
RETURN:		cx	- number of pixels in the run
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	7/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Get4BitPixelRun	proc	near
		uses	ax, bx, di, dx
BMframe		local	BitmapFrame
		.enter	inherit

		; get a mask for the current pixel, then search for all like
		; pixels...

		mov	ax, BMframe.BF_args.PBA_bm.B_width ; calc max count
		mov	bx, BMframe.BF_count		; get current index
		sub	ax, bx				; ax = max count
		mov	di, ax				; keep max count here
		mov	cx, bx				; get copy of index
		and	bx, 0x1				; isolate low three...
		mov	al, cs:[fourBitMaskTable][bx]	; al = bit mask
		mov	bx, cx
		shr	bx, 1				; byte index

		; see if there is a mask with this bitmap.  If so, check to 
		; make sure we are treading on solid pixels.  

		test	BMframe.BF_args.PBA_bm.B_type, mask BMT_MASK
		jz	testPixel
		mov	dx, di
		call	CheckMaskedPixels		; carry set if masked
		mov	di, dx
		jc	done

		; test the pixel and set the current area color
testPixel:
		push	bx, si

		; get the color at the current pixel location

		mov	ah, ds:[si][bx]			; get 2 pixels
		and	ah, al				; ah has pixel isolated
		tst	al				; need to shift ?
		jns	haveColorIndex
		shr	ah, 1				; move to low nibble
		shr	ah, 1
		shr	ah, 1
		shr	ah, 1
haveColorIndex:
		xchg	al, ah				; al = pixel value
		push	ax				; save pixel value
		test	BMframe.BF_args.PBA_bm.B_type, mask BMT_PALETTE
		jnz	paletteLookup
		mov	ah, CF_INDEX
haveColor:
		mov	cl, GSTATE_LOCKED or LEAVE_GSTATE
		mov	si, GS_areaAttr.CA_colorIndex	; offset to color info
		push	ds
		mov	ds, BMframe.BF_args.PBA_data.segment
		call	SetColor			; set current color
		pop	ds
		pop	ax				; al = pixel value
							;      to search for
							; ah = first mask
		pop	bx, si				; restore bit masks
		clr	cx				; init count

		; search for same color pixels.  
	
		mov	dh, ds:[bx][si]			; get first byte
		mov	dl, ah				; starting mask
		mov	ah, al
		shl	ah, 1				; put copy of pixel in
		shl	ah, 1				;  high nibble
		shl	ah, 1
		shl	ah, 1
		tst	dl
		mov	dl, dh				; need second copy
		js	testLeft			; skip left one
secondPixel:
		and	dl, 0xf				; test right pixel
		cmp	dl, al
		jne	haveCount
		inc	cx
		cmp	cx, di
		jae	haveCount
		inc	bx				; bump index into scan
		mov	dh, ds:[bx][si]			; load next pixel
		mov	dl, dh				; make a copy
testLeft:
		and	dh, 0xf0			; isolate left pixel
		cmp	dh, ah				; same ?
		jne	haveCount
		inc	cx				; bump count
		cmp	cx, di				; done ?
		jb	secondPixel
haveCount:
		clc
done:
		.leave
		ret

		; see what type of palette and do the lookup
paletteLookup:
		push	ds, si
		lds	si, BMframe.BF_args.PBA_pal	; ds:si -> palette
		test	BMframe.BF_args.PBA_flags, mask PBF_PAL_TYPE
		jz	rgbLookup

		; just a simple index.

		mov	bx, ax
		and	bx, 0xf				; isolate pixel
		mov	bl, ds:[si][bx]			; do lookup for new
		mov	al, bl				;  index
		mov	ah, CF_INDEX
retColor:
		pop	ds, si
		jmp	haveColor

		; do an RGB lookup
rgbLookup:
		and	ax, 0xf				; isolate pixel
		mov	bx, ax
		shl	bx, 1
		add	bx, ax				; 3* for rgb
		mov	ax, {word} ds:[si][bx].RGB_red	; get red/green
		mov	bh, ds:[si][bx].RGB_blue
		mov	bl, ah				; all setup right
		mov	ah, CF_RGB
		jmp	retColor

Get4BitPixelRun	endp

fourBitMaskTable	label	byte
		byte	0xf0, 0x0f

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Get8BitPixelRun
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a run of pixels from a byte/pixel bitmap

CALLED BY:	INTERNAL
		DrawImageScan
PASS:		inherits BitmapFrame
		ds:si	- points to beginning of scan line
RETURN:		cx	- number of pixels in the run
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	7/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Get8BitPixelRun	proc	near
		uses	ax, bx, dx, di, es
BMframe		local	BitmapFrame
		.enter	inherit

		; calculate index into scan line.

		mov	ax, BMframe.BF_args.PBA_bm.B_width ; calc max count
		mov	bx, BMframe.BF_count		; get current index
		sub	ax, bx				; ax = max count
		mov	dx, ax				; keep max count here

		; see if there is a mask with this bitmap.  If so, check to 
		; make sure we are treading on solid pixels.  

		test	BMframe.BF_args.PBA_bm.B_type, mask BMT_MASK
		jz	testPixel
		call	CheckMaskedPixels		; carry set if masked
		jc	done

		; test the pixel and branch on set/reset
testPixel:
		push	bx, si
		mov	al, ds:[si][bx]			; get pixel color
		push	ax				; save pixel value
		test	BMframe.BF_args.PBA_bm.B_type, mask BMT_PALETTE
		jnz	paletteLookup
		mov	ah, CF_INDEX
haveColor:
		mov	cl, GSTATE_LOCKED or LEAVE_GSTATE
		mov	si, GS_areaAttr.CA_colorIndex	; offset to color info
		push	ds
		mov	ds, BMframe.BF_args.PBA_data.segment
		call	SetColor			; set current color
		pop	ds
		pop	ax
		pop	bx, si				; restore bit masks

		; search for like pixels.

		push	es, di
		segmov	es, ds, cx
		mov	di, si
		add	di, bx				; es:di -> pixels
		mov	cx, dx				; cx = max count
		repe	scasb				; search while equal...

		; scasb leaves di one beyond first mismatch, but if we
		; hit the end of the scanline first, then di is one
		; beyond the last *match*

		jz	computeLength
		dec	di
computeLength:
		mov	cx, di
		sub	cx, si
		sub	cx, bx				; cx = # matches
		pop	es, di
		clc
done:
		.leave
		ret

		; see what type of palette and do the lookup
paletteLookup:
		push	ds, si
		lds	si, BMframe.BF_args.PBA_pal	; ds:si -> palette
		test	BMframe.BF_args.PBA_flags, mask PBF_PAL_TYPE
		jz	rgbLookup

		; just a simple index.

		mov	bx, ax
		clr	bh				; isolate pixel
		mov	bl, ds:[si][bx]			; do lookup for new
		mov	al, bl				;  index
		mov	ah, CF_INDEX
retColor:
		pop	ds, si
		jmp	haveColor

		; do an RGB lookup
rgbLookup:
		clr	ah				; isolate pixel
		mov	bx, ax
		shl	bx, 1
		add	bx, ax				; 3* for rgb
		mov	ax, {word} ds:[si][bx].RGB_red	; get red/green
		mov	bh, ds:[si][bx].RGB_blue
		mov	bl, ah				; all setup right
		mov	ah, CF_RGB
		jmp	retColor

Get8BitPixelRun	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Get24BitPixelRun
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a run of pixels from a monochrome bitmap

CALLED BY:	INTERNAL
		DrawImageScan
PASS:		inherits BitmapFrame
		ds:si	- points to beginning of scan line
RETURN:		cx	- number of pixels in the run
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	7/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Get24BitPixelRun proc	near
		uses	ax, bx
BMframe		local	BitmapFrame
		.enter	inherit

		; calculate index into scan line.

		mov	ax, BMframe.BF_args.PBA_bm.B_width ; calc max count
		mov	bx, BMframe.BF_count		; get current index
		sub	ax, bx				; ax = max count
		mov	dx, ax				; keep max count here

		; see if there is a mask with this bitmap.  If so, check to 
		; make sure we are treading on solid pixels.  

		test	BMframe.BF_args.PBA_bm.B_type, mask BMT_MASK
		jz	testPixel
		call	CheckMaskedPixels		; carry set if masked
		jc	done

		; test the pixel and branch on set/reset
testPixel:
		push	bx, si, di
		mov	di, BMframe.BF_args.PBA_bm.B_width ; size of scan line
		mov	al, ds:[si][bx]			; get pixel color
		add	bx, di
		mov	cl, ds:[si][bx]
		add	bx, di
		mov	ch, ds:[si][bx]
		sub	bx, di				; restore pointer
		sub	bx, di
		mov	ah, CF_RGB
		mov	bx, cx				; green/blue in bx
		mov	cl, GSTATE_LOCKED or LEAVE_GSTATE
		mov	si, GS_areaAttr.CA_colorIndex	; offset to color info
		push	ds
		mov	ds, BMframe.BF_args.PBA_data.segment
		call	SetColor			; set current color
		pop	ds
		pop	bx, si, di			; restore bit masks

		; for now, just return that there was one pixel in the run,
		; always.  It is much faster than searching for pixels, and
		; with 24-bit/pixel bitmaps (which are likely photographs),
		; the runs will probably be very small, with small variations
		; in the color happening between each pixel.

		mov	cx, 1				; signal just one pixel
		clc
done:
		.leave
		ret

Get24BitPixelRun endp

GraphicsImage	ends
