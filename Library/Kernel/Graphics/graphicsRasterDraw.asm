COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel Library
FILE:		graphicsRasterDraw.asm

AUTHOR:		Jim DeFrisco, 5/23/90

ROUTINES:
	Name			Description
	----			-----------
    INT DrawSlice		Bitmap needs some translation.	alloc a
				buffer and do it.
    INT InitBitmapOperations	Figure out which parts of the pipeline we
				need to use
    INT BMGetSlice		Get the next set of scan lines of info from
				the bitmap, put it in a previously
				allocated buffer.  do any translation necc.
    INT GetSliceComplex		Scaling required, plus decompaction and/or
				format changes
    INT UncompactPackBits	Uncompact a block of data that is compacted
				in the Macintosh PackBits format.
    INT InitFormatConversion	Might want to do some initialization for
				format conversion before any slices are
				loaded up
    INT InitVGAtoMono		Do some initialization for 4-bit to
				monochrome conversion
    INT MapRGBTo16GreyDither	Map an RGB triplet to one of our grey-scale
				patterns
    INT MapRGBToGreyDither	Map an RGB triplet to one of our grey-scale
				patterns
    INT InitSVGAtoMono		Do some initialization for 8-bit to
				monochrome conversion
    INT InitSVGAtoVGA		Do some initialization for 8-bit to 4-bit
				conversion
    INT InitRGBtoMono		Do some initialization for 24-bit to
				monochrome conversion
    INT InitRGBtoVGA		Do some initialization for 24-bit to 4-bit
				conversion
    INT InitRGBtoSVGA		Do some initialization for 24-bit to 8-bit
				conversion
    GLB ChangeBitmapFormat	Change to a simpler format
    INT VGAtoMono		Convert bitmap pixels from 4-bit to
				monochrome
    INT SVGAtoMono		Convert bitmap pixels from 8-bit to
				monochrome
    INT SVGAtoVGA		Convert bitmap pixels from 8-bit to 4-bit
				color
    INT RGBtoMono		Convert bitmap pixels from 24-bit to
				monochrome
    INT RGBtoVGA		Convert bitmap pixels from 24-bit to 4-bit
				color
    INT RGBtoSVGA		Convert bitmap pixels from 24-bit to 8-bit
				color

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	5/23/90		Initial revision


DESCRIPTION:
	Routines to draw/scale bitmaps
		

	$Id: graphicsRasterDraw.asm,v 1.1 97/04/05 01:13:36 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GraphicsDrawBitmapCommon	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawSlice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bitmap needs some translation.  alloc a buffer and do it.

CALLED BY:	INTERNAL
		GrDrawBitmap

PASS:		cx	- GState segment
		ds:si	- bitmap pointer (to header, could be HugeArray based)
		es	- Window segment
		inherits stack frame from GrDrawBitmap

RETURN:		nothing

DESTROYED:	ax,bx,dx

PSEUDO CODE/STRATEGY:
		allocate a buffer for 1 scan-line;
		if (!rotated)
		    get-next-line;
		    call video driver (putbits);
		else while (not-at-end-of-bitmap)
		    get-next-line;
		    calculate next pair of points (DDA);
		    call video driver (putline);

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		just returns right now if there is an allocation error

		Note for HugeArrays:  We try to treat these the same as a 
		complex bitmap, each "slice" being what is held in a single
		VM block of the HugeArray.

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	06/89		Initial version
		Don	03/26/00	Detect drawing past bottom of mask rect
					  and immediately stop drawing bitmap
		dhunter	5/22/2000	Skip all scanline d/s/fc for slices
					  above top of mask rect, and for huge
					  bitmaps, jump immediately to first
					  partially visible slice

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

		; amount DrawSlice should allocate to do complex bitmaps
		; (allows for 1280x24bits/pixel, plus a plane of mask)
MAX_BITMAP_WIDTH	equ 1280
SLICE_DATA_SIZE		equ <(MAX_BITMAP_WIDTH*3)+(MAX_BITMAP_WIDTH/8)>
SLICE_ALLOC_UNIT	equ <SLICE_DATA_SIZE+size CBitmap> ; ~4K
DECOMPACT_BUFFER	equ SLICE_ALLOC_UNIT	; offset to decompact buffer
FORMAT_SCRATCH_SIZE	equ 300			; xtra bytes for format convert


DrawSlice	proc	far
BMframe		local	BitmapFrame
		.enter	inherit

if	FULL_EXECUTE_IN_PLACE

EC <		push	bx						>
EC <		mov	bx, ds						>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		pop	bx						>

endif

		; we need to save the current area color, since it may change 
		; if we do some format conversion (which always wants it to
		; be black)

		push	ds				; save bitmap pointer
		mov	ds, cx				; ds -> GState
		mov	al, ds:[GS_areaAttr].CA_colorIndex ; get current index
		pop	ds				; restore bitmap ptr
		push	ax				; save index

		; now save GState and Window segments

		mov	BMframe.BF_gstate, cx		; save sptrs
		mov	BMframe.BF_window, es

		; first figure out how big everything will be

		call	InitBitmapOperations		; sets BF_opType bits
		jnc	allocBlock
		mov	cx, BMframe.BF_gstate		; save sptrs
		mov	es, BMframe.BF_window
		pop	ax				; restore index
		jmp	exit

		; then alloc a block, based on findings
allocBlock:
		mov	ax, BMframe.BF_getSliceDSize	; get data size
		add	ax, size CBitmap		; some for header
EC <		push	ax				; offset to sentinel >
EC <		add	ax, size word			; room for sentinel  >

		; Alloc the block swappable so the kernel won't complain, even
		; though it is never unlocked, and so it can never be swapped.

		mov	cx, (HAF_STANDARD_NO_ERR_LOCK shl 8) or mask HF_SWAPABLE
		call	MemAllocFar			; allocate some memory
		mov	es, ax				; es:di -> new buffer
EC <		pop	di				; offset to sentinel >
EC <		mov	es:[di], SENTINEL		; init sentinel      >
		clr	di
		mov	BMframe.BF_finalBMhan, bx	; save the mem handle
		mov	BMframe.BF_finalBM.segment, ax	; save address
		mov	BMframe.BF_args.PBA_data.segment, ax ; save here too
		mov	BMframe.BF_finalBM.offset, di	; save offset
		mov	BMframe.BF_origBMcurScan, di	

		; At this point, we're going to init some data pointers and 
		; copy the header over to the just-allocated block.  For Huge
		; Arrays, this yields slightly different results...

		mov	cx, size CBitmap
		mov	BMframe.BF_finalBMdata, cx	;past hdr to data
		mov	BMframe.BF_args.PBA_data.offset, cx ; save here too
		mov	cx, size Bitmap
		mov	bx, cx

		; copy over bitmap header to allocated block.  

		mov	ax, ds:[si].B_height		; assume src is simple
		test	ds:[si].B_type, mask BMT_COMPLEX ; see if simple
		jz	copyHeader			;  yes, need to set res

		; bitmap is complex, so we have the header size.  Get the
		; size of the first slice to initialize an internal counter

		mov	cx, size CBitmap
		mov	bx, ds:[si].CB_data		; init data ptr
		mov	ax, ds:[si].CB_numScans		; #rows in first slice
copyHeader:
		add	bx, si				; set pointer to data
		mov	BMframe.BF_origBMdata, bx	; init data pointer
		mov	BMframe.BF_origBMscansLeft, ax ; store height
		mov	ax, cx				; save hdr size
		shr	cx, 1
		rep	movsw
		sub	si, ax				; back to beginning
		clr	di				;  for new block too
		mov	al, ds:[si].B_type
		mov     ah, al
		and     ah, mask BMT_MASK		; only want mask bit
							;   from here
		and     al, mask BMT_FORMAT              ; isolate color info
		test	BMframe.BF_opType, mask BMOT_FILL_MASK
		jnz	storeType

if	(DISPLAY_CMYK_BITMAPS eq TRUE)
		cmp	al, BMF_4CMYK
		je	storeType
endif

		cmp     al, BMframe.BF_deviceType       ; stuff the color info
		jbe     storeType                       ;  make sure its ok
		mov     al, BMframe.BF_deviceType       ;  no, use device color
storeType:
		or      al, ah                          ; set other bits

		; the palette bit has already been set up in InitBitmapPalette
		; so we want to preserve that here.

		and	BMframe.BF_args.PBA_bm.B_type, mask BMT_PALETTE
		or	BMframe.BF_args.PBA_bm.B_type, al ; store type info
		or	al, mask BMT_COMPLEX		; set complex bit
		mov	es:[B_type], al		; save type
		mov	es:[CB_data], size CBitmap	; stuff data pointer
		mov	es:[CB_palette], di		; no cptr for now 
		mov	es:[CB_devInfo], di		; not a device
		mov	es:[CB_numScans], di		; init these too
		mov	es:[CB_startScan], di		; init these too
		mov	es:[CB_xres], DEF_BITMAP_RES	; use def resolution
		mov	es:[CB_yres], DEF_BITMAP_RES	; use def resolution

		; before we continue, calculate the size of the final bitmap
		; scan lines, now that we have the final format decided on...

                mov     cx, BMframe.BF_finalBMwidth ; pass width
		mov	BMframe.BF_args.PBA_bm.B_width, cx ; store width
		call    CalcLineSize
		mov     BMframe.BF_finalBMscanSize, ax ; store scan size
		mov	BMframe.BF_args.PBA_size, ax	; store here too...
		mov	BMframe.BF_args.PBA_bm.B_compact, BMC_UNCOMPACTED

		; Test if complex, non-rotated bitmap starts outside of the 
		; mask rectangle. We check this by computing the y-pos of 
		; the scanline in the source bitmap that should fall at or 
		; across the top of the mask rectangle (bottom if 
		; BMOT_SCALE_NEGY). If there is such a scanline, then save
		; its position for later, and set the skipping flag.

		test	ds:[si].B_type, mask BMT_COMPLEX ; simple ?
		jz	noSkip				; don't waste my time!
		test	BMframe.BF_opType, mask BMOT_ROTATE ; rotated?
		jnz	noSkip				; get outta here!
		push	es				; save bitmap seg
		mov	es, BMframe.BF_window		; es <- window segment
		mov	ax, es:[W_maskRect].R_top	; ax <- mask top
		mov	bx, BMframe.BF_drawPoint.P_y	; bx <- drawPoint.y
		test	BMframe.BF_opType, mask BMOT_SCALE_NEGY
		jz	posScale
		mov_tr	ax, bx				; ax <- drawPoint.y
		mov	bx, es:[W_maskRect].R_bottom	; bx <- mask bottom
posScale:
		pop	es
		sub	ax, bx				; ax <- y offset of border
		jng	noSkip				; bitmap starts inside mask
		test	BMframe.BF_opType, mask BMOT_SCALE
		jz	skipScaled			; scaling is more tricky
		mov_tr	bx, ax
		clr	ax				; bx.ax <- y offset
		movwwf	dxcx, BMframe.BF_yScale		; dx.cx <- y scale
		call	GrRegMul32			; dx <- the scanline!
		mov_tr	ax, dx				; ax <- the scanline!
skipScaled:
		mov	BMframe.BF_origBMfirstScan, ax	; save it
		ornf	BMframe.BF_stateFlags, mask BMSF_SKIPPING_SCANLINES_OUTSIDE_MASK
noSkip:

		; before we leave this section, we want to check for HugeArray
		; type bitmaps, and set the BF_origBMscansLeft field to 
		; the number of scans in the block containing BF_origBMfirstScan
		; and BF_origBMcurScan to the first scan in that block.

		; If we're skipping, then we can optimize HugeArray access
		; by jumping immediately to the block of interest without
		; locking all of those preceeding blocks.  That's the beauty
		; of the HugeArray!

		test	BMframe.BF_origBMtype, mask BMT_HUGE
		jz	checkScale
		mov	ax, BMframe.BF_origBMfirstScan	; looking for first visible scan
		cmp	ax, ds:[si].B_height		; ensure we don't exceed height
		jb	scanValid			; we're in like Flint
		mov	es, BMframe.BF_window		; oops, too tall! Setup to leave,
		pop	ax
		jmp	doneFree			; and get the heck outta Dodge!
scanValid:
		push	di, ds, si
		clr	dx				; dxax = scan #
		mov	bx, BMframe.BF_origBM.segment	; get VM file handle
		mov	di, BMframe.BF_origBM.offset	;  and block handle
		call	HugeArrayLock			; ax=#after, cx=#before (incl.)
		dec	cx				; cx=#before (non-incl.)
		add	ax, cx				; ax=total # scans in blk
		mov	BMframe.BF_origBMscansLeft, ax	; store # in block
		mov	ax, BMframe.BF_origBMfirstScan	; ax=lock'd scan #
		sub	ax, cx				; ax=first scan # in block
		mov	BMframe.BF_origBMcurScan, ax	; save as curScan
		call	HugeArrayUnlock
		pop	di, ds, si

		; now all we have left to do is to fill in the mask/jump
		; buffer.  Each entry is a word (one per pixel in width)
		; the words lower byte contains the byte jump count to
		; where the next pixel is.  The upper byte contains the mask
		; to use
checkScale:
		test	BMframe.BF_opType, mask BMOT_SCALE ; only iff scaled
		jz	checkFormatConvert
		call	InitBitmapMasksJumps		; do the dirty deed

		; we might want to do some preparation for format conversion.
		; then again, we might not.  let's let the people decide...
checkFormatConvert:
		test	BMframe.BF_opType, mask BMOT_FORMAT ; check for change
		jz	popWindow			;  no, check scaling
		call	InitFormatConversion		; do some init
		mov	cx, BMframe.BF_gstate		; save sptrs
		mov	es, BMframe.BF_window
		push	ds				; save bitmap segment
		mov	ds, cx				; ds -> GState
		mov	ds:[GS_areaAttr].CA_colorIndex, C_BLACK ; assumes black
		pop	ds
		jmp	getDrawPoint

popWindow:
		mov	cx, BMframe.BF_gstate		; save sptrs
		mov	es, BMframe.BF_window

		; figure out how much of the buffer we can use, what operations
		; will be required, etc.  First, set up the coordinates
getDrawPoint:
		mov	ax, BMframe.BF_drawPoint.P_x ; retrieve coords
		mov	bx, BMframe.BF_drawPoint.P_y 

		; re-save the GState segment, for use later

		push	cx

		; get the next slice and call the driver.  

		call	BMGetSlice		; get the next slice
		jc	done			;  has no scans, just quit

		; check for rotation.  deal with that separately

		test	BMframe.BF_opType, mask BMOT_ROTATE ; rotated ?
		LONG_EC	jnz	rotated

		; no rotation.  just call the video driver.
		; first check if we are drawing the bitmap or filling a mask
		
		test	BMframe.BF_opType, mask BMOT_FILL_MASK
		jz	loadGState
		or	BMframe.BF_args.PBA_flags, mask PBF_FILL_MASK
loadGState:
		mov	ds, cx			; restore gState seg
		mov	bx, BMframe.BF_drawPoint.P_y ; starting position

		; need to allow for the first slice to be empty

		tst	BMframe.BF_args.PBA_bm.B_height
		jnz	doNextSlice
		push	ds
		jmp	afterCall
doNextSlice:
		mov	ax, BMframe.BF_drawPoint.P_x ; pass coordinates
		push	ds	
		test	BMframe.BF_imageFlags, mask IF_DRAW_IMAGE
		jnz	drawImage
		mov	di, DR_VID_PUTBITS	; use putbits
		call	es:[W_driverStrategy]	; make call to driver

		; Verify that we've not written beyond the buffer's bounds
afterCall:
EC <		mov	di, BMframe.BF_finalBM.segment			>
EC <		mov	ds, di						>
EC <		mov	di, BMframe.BF_getSliceDSize			>
EC <		add	di, size CBitmap				>
EC <		cmp	ds:[di], SENTINEL				>
EC <		ERROR_NE GRAPHICS_SENTINEL_FOR_BITMAP_BUFFER_CORRUPTED	>
EC <		push	di						>
		call	BMCallBack		; get next slice
EC <		pop	di						>
EC <		pushf							>
EC <		push	ds						>
EC <		mov	bx, BMframe.BF_finalBM.segment			>
EC <		mov	ds, bx						>
EC <		cmp	ds:[di], SENTINEL				>
EC <		ERROR_NE GRAPHICS_SENTINEL_FOR_BITMAP_BUFFER_CORRUPTED	>
EC <		pop	ds						>
EC <		popf							>
		mov	bx, ds:[si].CB_startScan	; find start scan line 
		pop	ds
		jc	done
		add	bx, BMframe.BF_drawPoint.P_y

		; See if we can stop drawing because we've exceeded
		; the bounds of the mask rectanngle. Make sure to
		; handle the negative Y scale factor case.

		test	BMframe.BF_opType, mask BMOT_SCALE_NEGY
		jnz	checkEndNegY		; negative scale - do end check
		cmp	bx, es:[W_maskRect].R_bottom
		jle	doNextSlice		; not far enough - keep going!
done:
		pop	ds			; restore GState segment
		pop	ax			; restore old color
		mov	ds:[GS_areaAttr].CA_colorIndex, al
doneFree:
		mov	bx, BMframe.BF_finalBMhan ; get handle to memory
		call	MemFree			;  so we can nuke it
		clc				; signal no error
exit:
		.leave				; restore stack frame
		ret

		; check end condition if we are scaling negatively in Y
checkEndNegY:
		cmp	bx, es:[W_maskRect].R_top
		jl	done			; if above the top, we're done
		jmp	doNextSlice		; ...otherwise, keep going!

		; special case: rotated slice.  set up some initial info
		; then keep rotating slices
rotated:
		call	RotateBitmap		; do the rotation there
		jmp	done

		; we were called from GrDrawImage. Draw it differently.
drawImage:
		push	dx
		sub	bx, BMframe.BF_drawPoint.P_y
		mov	ax, BMframe.BF_ybump
		mul	bx
		pop	dx
		mov	bx, ax
		mov	ax, BMframe.BF_drawPoint.P_x
		add	bx, BMframe.BF_drawPoint.P_y
		call	ImageHugeSectionFar
		jnc	afterCall		; if not done, continue
		pop	ds			; else restore stack and exit
		jmp	done
DrawSlice	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitBitmapOperations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure out which parts of the pipeline we need to use

CALLED BY:	INTERNAL
		DrawSlice

PASS:		es	- segment of locked window
		ds:si	- bitmap pointer
			  BitmapFrame stack frame passed

RETURN:		carry	- set if some problem.  Don't draw bitmap
		BMframe.BF_opType initialized

DESTROYED:	ax,bx,dx,cx

PSEUDO CODE/STRATEGY:
		test the type of bitmap, the current transformation matrix,
		to determine what we're dealing with.  We also want to figure
		out how best to use the buffer space we've allocated.  The
		table below describes how the buffer space will be used
		under different circumstances:

		DECOMPACT  FORMAT CHG  SCALE	Comment
		---------  ----------  -----	-------
		       no   	   no	  no	No buffer allocated 
		       no	   no	 yes	Divide buffer into two pieces,
						The first part is where the
						scans from the original bitmap
						are scaled (directly from the 
						original).  The second part of
						the buffer holds the masks and
						jumps for each destination
						pixel (see scaling routines)
		       no	  yes	  no	Use full buffer, change format
						in place.  a scratch buffer of
						300 bytes is appended to assist
						in the format conversion.
		       no	  yes	 yes	Divide buffer into three, 1st
						to copy bytes, 2nd to scale 
						into and change fmt,, 3rd to 
						hold masks/jumps. this one has 
						the format buffer too.
		      yes	   no	  no	Decompact into full buffer.
						(Eventually we may want to 
						 move this into the driver)
		      yes	   no	 yes	Three pieces, decompact into
						1st, scale into 2nd, 3rd for
						masks/jumps
		      yes	  yes	  no	Full buffer, decompact into
						it then change format in place
						has 300 byte format conversion
						buffer to help out
		      yes	  yes	 yes	Three pieces: decompact into
						1st, scale into 2nd, change 
						fmt in place, 3rd for masks/
						jumps. adds a format conversion
						buffer (300 bytes) at the end
						of the block

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	05/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitBitmapOperations proc	near
		uses	es
BMframe		local	BitmapFrame
		.enter	inherit

		; init some vars, calc size of original bitmap scan lines

		mov	cx, ds:[si].B_height	; get height for later
		mov	BMframe.BF_origBMheight, cx ; store height
		mov	BMframe.BF_finalBMheight, cx ; store height
		mov	cx, ds:[si].B_width	; calc #bytes/row
		mov	BMframe.BF_origBMwidth, cx  ; store width
		mov	BMframe.BF_finalBMwidth, cx  ; just in case....
		mov	al, ds:[si].B_compact
		mov	BMframe.BF_origBMcompact, al
		mov	al, ds:[si].B_type 	; get format, mask bit
		mov	BMframe.BF_origBMtype, al ; save format
		clr	BMframe.BF_args.PBA_bm.B_type
		call	CalcLineSize		; calc ax = line size
		mov	BMframe.BF_origBMscanSize, ax ; save for later
		clr	dx
		mov	cx, ax			; get scan line size
		mov	bx, ax			; save another copy
		mov	ax, SLICE_DATA_SIZE	; div out to get max #
		div	cx
		inc	ax			; make sure at least one.
		cmp	ax, ds:[si].B_height	; make sure not too big
		jbe	storeSliceSize
		mov	ax, ds:[si].B_height	; don't assume larger
storeSliceSize:
		mov	BMframe.BF_origBMscans, ax ; set scans per slice 
		mov	cx, bx			; pass scan line size
		mul	cx			; determine #bytes to decompact
		mov	BMframe.BF_finalBMsliceSize, ax
		mov	BMframe.BF_getSliceDSize, ax
		clr	dx				; dl will hold flags
		mov	BMframe.BF_scaledScanSize, dx ; init some other vars
		mov	BMframe.BF_xtraScanLinePtr, dx 
		mov	BMframe.BF_getSliceMaskPtr, dx
		mov	BMframe.BF_getSliceMaskPtr2, dx
		mov	BMframe.BF_getSliceScalePtr, dx
		mov	BMframe.BF_origBMmaskSize, dx
		mov	BMframe.BF_curScan.WWF_int, dx
		mov	BMframe.BF_curScan.WWF_frac, dx
		mov	BMframe.BF_lastScan, dx
		mov	BMframe.BF_origBMfirstScan, dx

		; init the flags, then determine if we're rotated.  If we are
		; then assume we're scaled now too.

if	(DISPLAY_CMYK_BITMAPS eq TRUE)
		cmp	dh, BMF_4CMYK
		je	checkDecompaction
endif
		test	BMframe.BF_imageFlags, mask IF_DRAW_IMAGE 
		jnz	checkDecompaction
		test	es:[W_curTMatrix].TM_flags, TM_ROTATED	
		jz	checkScale
		or	dl, mask BMOT_ROTATE		; we're rotated
		jmp	setScaled			; for now, assume scaled
							;  too
checkScale:
		test	es:[W_curTMatrix].TM_flags, TM_SCALED
		jnz	setScaled			; no, but check again

		; no explicit scale factor, but look at the bitmap resolution

		test	ds:[si].B_type, mask BMT_COMPLEX ; if not complex, must
		jz	checkDecompaction		;  be 72 dpi
		cmp	ds:[si].CB_xres, DEF_BITMAP_RES	; 72 dpi in x ?
		jne	setScaled			;  no, scale it
		cmp	ds:[si].CB_yres, DEF_BITMAP_RES	; 72 dpi in y ?
		je	checkDecompaction		;  no, scale it
setScaled:
		or	dl, mask BMOT_SCALE		; we're scaled
		call	InitBitmapScale			; while we're here.
		jc	done

		; check to see if we need to decompact anything
checkDecompaction:
		mov	dh, ds:[si].B_compact		; check compaction type
		cmp	dh, BMC_PACKBITS		; we can do this here
		je	markCompacted
		cmp	dh, BMC_LZG
		jne	checkFormatChange		;  only two supported
markCompacted:
		or	dl, mask BMOT_DECOMPACT		;  for now

		; check to see if we need to change the color format
		; if we're just filling the mask, no change needed.
checkFormatChange:
		test	BMframe.BF_opType, mask BMOT_FILL_MASK
		jnz	storeFlags			; if FILLING, skip pal
		mov	BMframe.BF_formatPtr, 0		; save it
		mov	dh, ds:[si].B_type		; check against bitmap
		and	dh, mask BMT_FORMAT

if	(DISPLAY_CMYK_BITMAPS eq TRUE)
		cmp	dh, BMF_4CMYK
		je	checkPalette
endif

		mov	al, BMframe.BF_deviceType	; get dev color
		cmp	dh, al				; can driver handle it?
		jbe	checkPalette			;  yes, continue
		or	dl, mask BMOT_FORMAT		;  no, change req
		and	al, mask BMT_FORMAT		; isolate bits
		and	BMframe.BF_args.PBA_bm.B_type, not mask BMT_FORMAT
		or	BMframe.BF_args.PBA_bm.B_type, al ; set new type
		mov	bx, BMframe.BF_getSliceDSize	
		add	BMframe.BF_getSliceDSize, FORMAT_SCRATCH_SIZE
		add	bx, size CBitmap		; form pointer
		mov	BMframe.BF_formatPtr, bx	; save it

		; since we're setting the flag, set up a combo byte to be
		; used later for a table index

		cmp	dh, BMF_24BIT			; do special check here
		jne	addFormats			;  nope, continue
		cmp	al, BMF_MONO			; is this the one were
		jne	addFormats			;  looking for?  no.
		add	dh, 3				; bump past others
addFormats:
		add	dh, al				; get the combo
		shl	dh, 1				; make it a word index
		mov	BMframe.BF_formatCombo.low, dh	; save table index
	    	clr	BMframe.BF_formatCombo.high

		; all done, store the flags
storeFlags:
		or	BMframe.BF_opType, dl		; save flags
		clc					; signal no error
done:
		pushf					;save error flag

		;
		;  The scaling code is dying when a big enough buffer
		;  is being allocated, so I'm putting a hack in here
		;  to error if it's too big. I tried 0x8000 at first,
		;  but still got death, so I'm trying 0x4000 now...
		;

		cmp	BMframe.BF_getSliceDSize, 0xc000
		ja	overflow
		popf					;no overflow, return
							;usual flag
exit:
		.leave
		ret

overflow:
		;
		;  Slice size is too big. Bail.
		;
		popf
		stc
		jmp	exit

		; we're not doing a format change, but we might have a
		; palette to deal with.  Check it out and do the right thing.
checkPalette:
		mov	cl, ds:[si].B_type
		test	cl, mask BMT_PALETTE 		; check for bm palette
		clr	BMframe.BF_args.PBA_pal.segment	; init w/no palette
		jz	storeFlags
		or	BMframe.BF_args.PBA_bm.B_type, mask BMT_PALETTE
		call	InitBitmapPalette		; do some intialization
		jmp	storeFlags
InitBitmapOperations endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BMGetSlice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the next set of scan lines of info from the bitmap, put it
		in a previously allocated buffer.  do any translation necc.

CALLED BY:	INTERNAL
		BMCallBack, DrawSlice

PASS:		ds:si	- bitmap pointer
		ss:bp	- pointer to local stack frame for
			  GrDrawBitmap (see above)

RETURN:		carry	- clear if everything ok
			- set if no more scans to get
		ds:si	- pointer to bitmap (may change)

DESTROYED:	ax,bx,dx,di

PSEUDO CODE/STRATEGY:
		get the next scan line of data out of the original bitmap slice
		and put it in the allocated buffer.  Operations may include
		decompaction, stretching, and format conversion.  This 
		routine is NOT called if there is any rotation.

		If the bitmap is to be stretched, decompacted, or requires
		a format conversion (color format), then TWO bitmaps will
		be passed here.  One is pointed to by BMframe.origBM and 
		contains a pointer to the original bitmap passed to 
		GrDrawBitmap.  The other is a block allocated by the bitmap
		drawing code (in DrawSlice), and is the workspace for 
		decompacting/scaling/format conversion (d/s/fc).

		If the bitmap is simple (i.e. uses the Bitmap structure and
		not the CBitmap (Complex Bitmap) structure) and requires
		no d/s/fc, then this routine will NEVER be called.

		CASE 1.
		------
		If the bitmap is complex, but does not require any d/s/fc,
		then this routine will get called from the video driver
		to get the next slice of the complex bitmap.  In this case,
		there is only ONE bitmap to deal with (no additional 
		workspace buffer).

		CASE 2.
		------
		If the bitmap requires any d/s/fc, then TWO bitmaps are
		dealt with -- regardless of whether the original bitmap is
		simple or complex.

			CASE 2A.
			-------
			The original bitmap is simple.  In this case, there
			is no application callback to call.  We just need
			to keep track of where we are in the original bitmap
			(what scan line, keep data pointer) and copy the
			next piece over to our own bitmap buffer so we 
			can d/s/fc it.

			CASE 2B.
			-------
			The original bitmap is complex. This is the worst 
			case of all.  We have to keep track of where we are
			in each slice, like we did in CASE 2A for the simple
			bitmaps, then when we finish the slice we call back
			to the caller to get the next original bitmap slice.

			In both of these cases, we need to keep getting
			data from the original bitmap to fill our allocated
			(final) bitmap.  The algorithm goes something like
			this:
				done=false;
				numScansWanted=#original scans that will fit
						in our allocated buffer;
				while (numScansWanted>0 && !done)
				    if (numScansWanted > what's left in current
					original slice)
					copy them;
					numScansWanted=0;
					CheckToGetNextSlice;
				    else 
					copy what's left in original slice;
					numScansWanted -= #scans left in o.s.
					CheckToGetNextSlice;

			The routine CheckToGetNextSlice checks to see if 
			there is another slice to get.  If not, it bails.
			If so, it does the callback to get the pointers to
			the next slice;
		CASE 3.
		------
		There is one additional case.  If the bitmap is being scaled,
		and the scale factor is greater than 1.0 in y, then it
		is possible that one or more of the scan lines of the bitmap
		will need to be drawn twice.  The video driver supports 
		drawing slices repeatedly, and the bitmap scaling code uses
		this feature.  In all other cases, this routine is called
		when the current slice has been drawn, and the next slice
		is needed.  In the case just described, however, each
		repeated scan line is drawn alone, so this routine will get
		called multiple times for each slice.  In this case, a 
		special flag (partScaleFlag) is maintained by the bitmap 
		scaling code, and is checked for and handled here as a 
		special case.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	06/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BMGetSlice	proc	far
		uses	cx, es
BMframe		local	BitmapFrame
		.enter	inherit

		; first get a pointer to the bitmap.  If we run out
		; of this slice, use the callback routine to get the next
		; piece.

		mov	es, BMframe.BF_finalBM.segment	; set up ptr to tmp bm
		mov	di, BMframe.BF_finalBM.offset

		; CHECK FOR CASE 3
		; before we check to see if we need to get more of the bitmap
		; check to see if we're scaling.  It could be we're not done
		; drawing the scans that are in the first half of the data
		; space of the bitmap we've allocated.  See ScaleSlice to 
		; get further confused (and the notes in the above function 
		; header)

		test	BMframe.BF_opType, mask BMOT_PARTIAL
		jz	checkForCase1			;  yes
		call	PartialScaleBigger		; do as much as we can

		test	BMframe.BF_opType, mask BMOT_FORMAT
		jz	noPartFormatConvert		; no change, chk scale
		call	ChangeBitmapFormat		; just do it
noPartFormatConvert:
		jmp	haveSlice			;  and draw it

		; CHECK FOR CASE 1
		; next check for a single bitmap.  In this case we just
		; need to do the callback to get the next slice from the 
		; caller of GrDrawBitmap. (if we're not done).
		; NOTE: There's another complication now: ds is not valid at
		;       this point if the original bitmap is HUGE.  In that
		;       case, skip the test for a simple bitmap.
checkForCase1:
		test	BMframe.BF_origBMtype, mask BMT_HUGE ; don't test if
		jnz	case2
		mov	cx, ds				; compare segments
		mov	dx, es
		cmp	cx, dx				; see if the same
		je	singleBitmap			;  yes, deal w/CASE 1

		; MUST BE CASE 2
		; Make sure the data pointer is in the right place, and 
		; update the startRow
case2:
		mov	ax, size CBitmap		; reset pointer
		mov	es:[di].CB_data, ax
		mov	BMframe.BF_finalBMdata, ax
		mov	BMframe.BF_args.PBA_data.offset, ax
		mov	ax, es:[di].CB_numScans		; get how big slice is
		add	es:[di].CB_startScan, ax	; update the start

		; finally, time to get more data.  What we came here to do,
		; remember ?

		call	GetSliceComplex			; call specialized func
		jc	exit				; if done, stop

		; have final scan built out...so return to draw it
haveSlice:
		mov	ds, BMframe.BF_finalBM.segment	; get new segment
		clr	si				; looking at start

		; Last thing to do.  If there is a negative scale factor in x
		; or y, then we need to flip the bits.
doneMoreToDraw:
		test	BMframe.BF_opType, mask BMOT_SCALE_NEGY
		jz	noScaleNegY
		neg	ds:[si].CB_numScans		; draw backwards
noScaleNegY:
		test	BMframe.BF_opType, mask BMOT_SCALE_NEGX
		jz	noScaleNegX
		call	MirrorBitmapBits		; mirror them in x
noScaleNegX:
		mov	ax, ds:[si].CB_numScans		; stuff last few values
		mov	BMframe.BF_args.PBA_bm.B_height, ax
		mov	ax, ds:[si].CB_data
		mov	BMframe.BF_args.PBA_data.offset, ax
		mov	BMframe.BF_args.PBA_data.segment, ds
		clc					; everything ok
exit:
		.leave
		ret

		; all done with bitmap, restore stack and leave
doneFinishedDrawing:
		stc					; signal all done
		jc	exit

;---------------------------------------------------------------------------

		; it is just a single one, callback to the caller
singleBitmap:
		mov	dx, ds:[si].CB_startScan	; see if there's more
		add	dx, ds:[si].CB_numScans
		cmp	dx, ds:[si].B_height		; done yet ?
		jae	doneFinishedDrawing		;  yes, just return

if FULL_EXECUTE_IN_PLACE
	;
	; Make call to callback function to get next scanline, but
	; if we're XIP'ed this can be a bit arduous.  Hang with us..
	;				-- todd 03/21/94
		mov	ss:[TPD_dataAX], ax
		mov	ss:[TPD_dataBX], bx
		movdw	bxax, BMframe.BF_cbFunc
	;
	; Double check that pointer is not direct pointer to XIP segment,
	; since we are in a movable resource...
EC<		xchg	ax, si						>
EC<		call	ECAssertValidFarPointerXIP			>
EC<		xchg	si, ax						>

		call	ProcCallFixedOrMovable
else
	;
	; Just make the call.
		call	BMframe.BF_cbFunc		; do callback

endif
		jc	exit				; if callback returned
							;   carry, we're done
		mov	BMframe.BF_finalBM.segment, ds	; reset internal vars
		mov	BMframe.BF_finalBM.offset, si
		mov	BMframe.BF_origBM.segment, ds	
		mov	BMframe.BF_origBM.offset, si
		jmp	doneMoreToDraw			; more to do

BMGetSlice	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSliceComplex
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scaling required, plus decompaction and/or format changes

CALLED BY:	INTERNAL
		BMGetSlice

PASS:		ds:si	- bitmap pointer (except for HugeArray ones)
		es:di	- final bitmap pointer (one to send to video driver)
		inherits stack frame of GrDrawBitmap

RETURN:		carry	- clear if everything ok
			- set if no more scans to get
		ds:si	- pointer to bitmap (may change)

DESTROYED:	ax,bx,dx,di

PSEUDO CODE/STRATEGY:
		We have to split the buffer into three pieces.  The first
		to copy the data in and perform the decompaction/format
		change.  The second to scale the scan lines into and the
		thrird to hold the precalculated masks/jumps for scaling 
		each scan line.


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	05/90		Initial version
		dhunter	5/22/2000	Skip all scanline d/s/fc for slices
					  above top of mask rect

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetSliceComplex	proc	near
BMframe		local	BitmapFrame
		.enter	inherit
		; START OF WHILE LOOP TO GET DATA 
		; (See description in header for BMGetSlice)
		; OK, we've established that the first row of the next slice
		; will not overflow on the destination bitmap end.  Assume
		; it won't overflow the source bitmap end (it shouldn't).  
		; We'll take care of that later anyway.  Now we head into
		; that cute while loop described in the function header.

		mov	cx, BMframe.BF_origBMscans	; cx=numScansWanted
		mov	es:[di].CB_numScans, cx		; assume no scale
		mov	bx, BMframe.BF_finalBMdata	; bx=dest data offset
topOfWhileLoop:
		test	BMframe.BF_stateFlags, mask BMSF_SKIPPING_SCANLINES_OUTSIDE_MASK
		LONG jnz skipping
allDoneSkipping:
		mov	dx, BMframe.BF_origBMscansLeft	; enuf left in slice?
		tst	dx				; need to do callback?
		jz	doCallback			;  yes, do it
		cmp	cx, dx				;  no, check size
		ja	notEnufInOrigSlice		;  no, start the loop
		sub	BMframe.BF_origBMscansLeft, cx	;  yes, fewer to do..
		mov	ax, cx				; ax=amt we'll copy
		jmp	copyDecompactData		;   & do the copy

		; there isn't enough in the current original bitmap slice
		; to fill our working buffer.  Copy what is left there and
		; do the callback to get the next piece.
notEnufInOrigSlice:
		mov	ax, dx				; ax=amt we'll copy
		mov	BMframe.BF_origBMscansLeft, 0	; none left there

		; copy what we can.  if we need more, head back to the top
copyDecompactData:
		mov	dx, ax				; save #scans to copy
		sub	cx, ax				; cx = num left after
		push	cx				; save that amount
		add	BMframe.BF_origBMcurScan, ax	; update current scan
		cmp	ax, BMframe.BF_origBMscans	; copying biggest amt?
		LONG jne figureCopyAmount		;  no, figure #bytes
		mov	cx, BMframe.BF_finalBMsliceSize ; yes, copy the max

		; very soon we will need to set up ds:si as a source pointer
		; to the data portion of the original bitmap.  For most bitmaps
		; this will be the same segment in which the header is located.
		; However, this is not the case for HugeArray types, so we need
		; to do some "special stuff".
haveCopySize:
		mov	di, bx				; copy to data area
		test	BMframe.BF_origBMtype, mask BMT_HUGE ; HugeArray ?
		LONG jnz getHugePointer
		push	ds, si				; save bitmap hdr seg
		mov	si, BMframe.BF_origBMdata	; get last data ptr
haveSrcPointer:
		test	BMframe.BF_opType, mask BMOT_DECOMPACT
		LONG jnz unpackBits			; jmp to uncompact
		shr	cx, 1				; move words instead
		jnc	bigMove				; nc=even #bytes
		movsb					; odd, move odd one
bigMove:
		rep	movsw				; copy line of data
dataCopied:
		test	BMframe.BF_origBMtype, mask BMT_HUGE
		LONG jnz unlockHugeBlock
		mov	BMframe.BF_origBMdata, si	; update data ptr
		pop	ds, si
restorePointers:
		mov	bx, di				; save destination off
		mov	di, BMframe.BF_finalBM.offset	; restore header ptr

		pop	cx				; restore #scans left
		tst	cx				; if more, keep going
		jnz	topOfWhileLoop			;  yep...
		
		; END OF WHILE LOOP
		; now stretch/compress if any scale factor.  This includes
		; the effects of different bitmap resolutions.
scaleBitmap:
		test	BMframe.BF_opType, mask BMOT_SCALE
		jz	formatConversion		;   no, skip the call
		call	ScaleSlice			;   yes, call scaler

		; now we have our buffer full of decompacted/scaled data.  
		; Continue with the final construction pipeline. do any format
		; conversion needed.
formatConversion:
		test	BMframe.BF_opType, mask BMOT_FORMAT
		jz	doneMoreToDo			; no change, chk scale
		call	ChangeBitmapFormat		; just do it
doneMoreToDo:
		clc
done:
		.leave
		ret

doneFinishedDrawing:
		stc
		jmp	done

;---------------------------------------------------------------------------

		; we've run out of bitmap, call the caller to get some more.
		; Unless the original bitmap was simple, of course.  Then
		; we know we're done.
		; We'll also come here if the bitmap is in a HugeArray, in 
		; which case we want to lock down the next block.
doCallback:
		test	BMframe.BF_origBMtype, mask BMT_HUGE
		jnz	nextHugeBlock
		test	ds:[si].B_type, mask BMT_COMPLEX ; simple ?
		jz	checkPartialSlice		;  yes, really done?
		mov	ax, BMframe.BF_origBMcurScan	; see where we are
		cmp	ax, ds:[si].B_height		; all done ?
		jae	checkPartialSlice		;  yes, handle it
		push	bx,es,cx

if FULL_EXECUTE_IN_PLACE
	;
	; As we are in a movable segment, we need to do a PCFOM on
	; XIP machines, and likewise verify the callback is not
	; to a routine in the XIP segment (since it may be banked
	; out...)
	;			-- todd 03/21/94
		mov	ss:[TPD_dataAX], ax
		mov	ss:[TPD_dataBX], bx
		movdw	bxax, BMframe.BF_cbFunc
EC<		xchg	si, ax					>
EC<		call	ECAssertValidFarPointerXIP		>
EC<		xchg	si, ax					>
		call	ProcCallFixedOrMovable
else
		call	BMframe.BF_cbFunc		; do callback
endif

		pop	bx,es,cx
		jc	done				; if no more, no more.
		mov	BMframe.BF_origBM.offset, si	; store new bitmap addr
		mov	BMframe.BF_origBM.segment, ds
		mov	ax, ds:[si].CB_data		; get data offset
		add	ax, si
		mov	BMframe.BF_origBMdata, ax	; adjust total
		mov	ax, ds:[si].CB_numScans		; get #rows in this one
		mov	BMframe.BF_origBMscansLeft, ax	; and re-init count
		jmp	topOfWhileLoop			; and start over again

		; last slice of bitmap has fewer scans...so update the
		; proper variables and draw it (if it's not empty)
checkPartialSlice:
		cmp	cx, BMframe.BF_origBMscans	; copied any yet ?
		LONG je	doneFinishedDrawing		;  no, all done
		sub	cx, BMframe.BF_origBMscans	; calc #copied so far
		neg	cx				; cx = #left to draw
		mov	es:[CB_numScans], cx
		mov	BMframe.BF_origBMscans, cx	; set number left
		jmp	scaleBitmap			; continue with next

		; not copying maximum load this time around. Figure out how
		; much there is to copy
figureCopyAmount:
		push	dx				; need this for HugeArr
		mov	cx, BMframe.BF_origBMscanSize	; get #bytes/scan
		mul	cx
		mov	cx, ax				; cx = #bytes to copy
		pop	dx
		jmp	haveCopySize
		
		; it's a HugeBitmap.  Find the right scan line.
		; dx = # we're doing this time around
getHugePointer:
		push	bx, di, cx
		mov	bx, BMframe.BF_origBM.segment	; VM file handle
		mov	di, BMframe.BF_origBM.offset	; block handle
		mov	ax, BMframe.BF_origBMcurScan	; dx.ax = desired scan
		sub	ax, dx				; dx = # doing this rnd
		clr	dx		
EC <		call	ECCheckHugeArrayFar				>
		call	HugeArrayLock
		pop	bx, di, cx
		jmp	haveSrcPointer

		; callback to get next HugeArray block.
		; check to see if we're really done
nextHugeBlock:
		push	bx, di, cx
		mov	bx, BMframe.BF_origBM.segment	; VM file handle
		mov	di, BMframe.BF_origBM.offset	; block handle
		mov	ax, BMframe.BF_origBMcurScan	; dx.ax = desired scan
		cmp	ax, BMframe.BF_origBMheight	; see if we're done
		jae	popCheckPartialSlice
		clr	dx		
EC <		call	ECCheckHugeArrayFar				>
		call	HugeArrayLock
		mov	BMframe.BF_origBMscansLeft, ax	; store # in this block
		call	HugeArrayUnlock			; that's all we need
		pop	bx, di, cx
		jmp	topOfWhileLoop

		; special case: decompact it
unpackBits:
		cmp	BMframe.BF_origBMcompact, BMC_LZG
		je	lzg
		call	UncompactPackBits		; deal with packbits
		jmp	dataCopied

lzg:
		push	ax
lzgMore:
		push	cx
		call	LZGUncompressSource
		add	di, cx				; update dest ptr
		add	si, ax				; update source ptr
		mov_tr	ax, cx				; ax = dest bytes
		pop	cx
		sub	cx, ax				; update dest bytes
		tst	cx
		jnz	lzgMore
		pop	ax
		jmp	dataCopied

		; copied data out of HugeArray block.  Unlock the block now.
unlockHugeBlock:
		call	HugeArrayUnlock			; release it
		jmp	restorePointers			; restore bitmap ptrs.


popCheckPartialSlice:
		pop	bx, di, cx
		jmp	checkPartialSlice

		; We are currently setup to skip (discard) slices until we
		; find BF_origBMfirstScan.
skipping:
		; is the first scanline of interest in this slice?
		push	cx
		mov	ax, BMframe.BF_origBMcurScan
		mov	cx, BMframe.BF_origBMscansLeft
		add	ax, cx			 	; ax=first scan in orig slice
		cmp	ax, BMframe.BF_origBMfirstScan	; are you in there?
		ja	stopSkipping			; gotcha!

		; this slice is useless - consume it and get another.
EC <		test	BMframe.BF_origBMtype, mask BMT_HUGE			>
EC <		ERROR_NZ -1		; huge bitmap should never come here	>
		add	BMframe.BF_origBMcurScan, cx	; update current scan
		pop	cx
		jmp	doCallback			; get another
stopSkipping:
		pop	cx
		; Found it! Update various variables and jump back into the
		; main loop to actually start d/s/fc and drawing.

		andnf	BMframe.BF_stateFlags, not mask BMSF_SKIPPING_SCANLINES_OUTSIDE_MASK
		mov	dx, BMframe.BF_origBMcurScan	; dx = # scans we've skipped
		test	BMframe.BF_opType, mask BMOT_SCALE
		jz	skipAlmostDone			; not scaled, skip the next bit
		clr	cx				; dx.cx = # scans
		push	bx				; save bx
		movwwf	bxax, BMframe.BF_yScale		; bx.ax = y scale
		call	GrUDivWWFixed			; dx.cx = pos in doc coords
		tst	cx				; ceil dx.cx
		jz	noFrac				; got fraction?
		inc	dx				; yep, round up
noFrac:
		clr	cx				; don't forget to clear fraction
		push	dx				; dx.cx = distance to new drawPoint.y
		call	GrRegMul32			; dx.cx = new current scan
		movwwf	BMframe.BF_curScan, dxcx
		pop	bx, dx				; restore bx and dx = distance
skipAlmostDone:
		test	BMframe.BF_opType, mask BMOT_SCALE_NEGY
		jz	notNegY				; sign-adjust dx
		neg	dx
notNegY:
		add	BMframe.BF_drawPoint.P_y, dx	; adjust starting point
		mov	cx, es:[di].CB_numScans		; cx=numScansWanted
		jmp	allDoneSkipping			; back to the future!

GetSliceComplex	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UncompactPackBits
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Uncompact a block of data that is compacted in the
		Macintosh PackBits format.

CALLED BY:	INTERNAL
		BMGetSlice

PASS:
		ds:si	- segment,offset to data to uncompact
		es:di	- segment, offset to buffer to place uncompacted data
		cx	- # of bytes after uncompaction
RETURN:
		ds:si 	- segment, offset to first byte after compacted data
		es:di	- segment, offset to first byte after uncompacted

DESTROYED:
		cx

PSEUDO CODE/STRATEGY:
	see Macintosh documentation on PackBits

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	no error flagged in uncompacted data larger than cx bytes

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	6/29/89		Initial version
	jim	1/27/90		Didn't work if passed cx > 256.  added "clr cx"

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UncompactPackBitsFar	proc	far
	call	UncompactPackBits
	ret
UncompactPackBitsFar	endp

UncompactPackBits		proc	near
	push	ax,bx,dx
	clr	dh			;for 16 bit subtractions later
	mov	bx,cx			;use bx as total count
	clr	cx			; clear out count register
UPB_5:
	lodsb				;get flag/count byte
	tst	al
	jns	UPB_100			;jmp for discrete bytes
	neg	al			;convert to number of bytes packed
	inc	al			;i.e. number of copies plus the orig
	mov	dl,al			;save num bytes for sub from total
	mov	cl,al			;move into count register
	lodsb				;get byte to duplicate
	mov	ah,al			;so can duplicate as words
	shr	cl,1			;number of words to duplicate
	jnc	UPB_10			;jmp if even number of bytes
	stosb				;store odd byte
UPB_10:
	rep	stosw			;store copies of byte
UPB_20:
	sub	bx,dx			;subtract from total uncompacted bytes
	ja	UPB_5			;jmp if more bytes
	pop	ax,bx,dx
	ret

UPB_100:
	inc	al			;convert to number of discrete bytes
	mov	cl,al			;move into count register
	mov	dl,al			;save num bytes for sub from total
	shr	cl,1			;move discrete words not bytes
	jnc	UPB_120			;jmp if even number of bytes
	movsb				;move odd byte
UPB_120:
	rep	movsw			;move discrete bytes
	jmp	short	UPB_20
UncompactPackBits		endp

GraphicsDrawBitmapCommon ends

GraphicsDrawBitmap segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitFormatConversion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Might want to do some initialization for format conversion 
		before any slices are loaded up

CALLED BY:	INTERNAL
		DrawSlice

PASS:		BMframe stack frame

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		if the formats involve require some initialization, do it

		We have at our disposal, 65 different dither-level with an
		8x8 pattern matrix.  This is used for the 8/24bit to 1bit
		conversions, but a subset is used for the 4bit to 1bit 
		conversions, since we don't need that many levels and the 
		bigger the matrix, the lower the spacial resolution.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	08/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitFormatConversion proc far
BMframe		local	BitmapFrame
		.enter	inherit
		mov	bx, BMframe.BF_formatCombo
		call	cs:InitFormatRoutines[bx]	; do the conversion
		.leave
		ret
InitFormatConversion endp

		; This table holds the offsets to the bitmap format conversion
		; routines.  See the header for the function ChangeBitmapFormat

InitFormatRoutines label nptr
		nptr	0			; cannot happen
		nptr	offset InitVGAtoMono	; 4bit -> 1bit
		nptr	offset InitSVGAtoMono	; 8bit -> 1bit
		nptr	offset InitSVGAtoVGA	; 8bit -> 4bit
		nptr	offset InitRGBtoAll	; 24bit -> 4bit
		nptr	offset InitRGBtoAll	; 24bit -> 8bit
		nptr	offset InitRGBtoAll	; 24bit -> 1bit




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetPointerToPalette
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns a pointer to the palette to use when mapping from 
		one format to another( i.e 256 -> 16 colors, 16 -> mono,
		256-> mono). If there is a palette associated with the Bitmap,
		use that one, else, use the default system palette

CALLED BY:	InitSVGAtoVGA, InitSVGAtoMono, InitVGAtoMono
PASS:		inherits BMframe		
RETURN:		es:di	pointer to Palette
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	2/ 4/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetPointerToPalette	proc	near
		uses	ax,bx
BMframe		local	BitmapFrame
		.enter	inherit

		; Use the system palette, unless the original bitmap had one
		;
		clr	BMframe.BF_hugeBMlocked		; HugeArrayDir not lock
		LoadVarSeg es, di
		mov	di, offset defaultPalette
		test	BMframe.BF_origBMtype, mask BMT_PALETTE
		jz	done			;  if no palette, we're done

		; There is a palette, so we want to pass a pointer to the
		; original bitmap's palette data. Since we're going to perform
		; the conversion ourselves, clear all palette bits
		;
		and	BMframe.BF_args.PBA_bm.B_type, not mask BMT_PALETTE
		mov	di, BMframe.BF_finalBM.offset ; ds:di -> bitmap
		and	ds:[di].B_type, not mask BMT_PALETTE
		test	BMframe.BF_origBMtype, mask BMT_HUGE 
		jz	getOrigPalette		; if not huge, point at table
		
		; Else lock down the HugeArrayBitmap
		;
		movdw	bxdi, BMframe.BF_origBM	; bx.di is the Huge Array
		call	HugeArrayLockDir	;ax is the segment
		mov	es, ax
		mov	BMframe.BF_hugeBMlocked, ax	; save here too
		mov	di, offset EB_bm
		jmp	pointToRGBValues

		; set up pointer to the original bitmaps palette
getOrigPalette:
		movdw	esdi, BMframe.BF_origBM	 ; ds:di -> bitmap
pointToRGBValues:
		add	di, es:[di].CB_palette	; ds:di -> bitmap palette
		add	di, size Palette	; point to actual RGB data
done:
		.leave
		ret
GetPointerToPalette	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitVGAtoMono
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do some initialization for 4-bit to monochrome conversion

CALLED BY:	INTERNAL
		InitFormatConversion

PASS:		BMframe

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		build out the table of dither patterns in the scratch space we
		are provided

		For each index value
		    Convert it to RGB
		    Convert the RGB into a dither pattern index
		    Copy the dither pattern to our buffer

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		There are some better algorithms for this, like a Floyd-
		Steinberg error-propagation algorithm.  But they take more
		time/space.  

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	08/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitVGAtoMono	proc	near
		uses	es,ds,si,di,ax,bx,cx
BMframe		local	BitmapFrame
		.enter	inherit

		; this is where we'll want to check for palettes stored
		; with bitmaps

		mov	ds, BMframe.BF_finalBM.segment	; get original format
		test	BMframe.BF_opType, mask BMOT_SCALE ; already done ?
		jnz	calcConvertTable		;  yes, skip redo
		mov	al, BMframe.BF_origBMtype
		mov	cx, BMframe.BF_finalBMwidth ; get second y value
		call	CalcLineSize
		mov	BMframe.BF_scaledScanSize, ax ; and save it
calcConvertTable:
		mov	si, BMframe.BF_finalBM.offset
		mov	al, ds:[si].B_type
		mov	cx, BMframe.BF_finalBMwidth
		call	CalcLineSize		; ax = #bytes/scan
		mov	BMframe.BF_finalBMscanSize, ax ; store result
		mov	si, BMframe.BF_formatPtr


		; BMIndextoRGB takes es:di pointing at a palette -- either
		; one stored with the bitmap or the system palette
		call	GetPointerToPalette

		clr	ax			; start out with index 0
		mov	BMframe.BF_formatScan, ax ; init variable
		mov	cx, 16			; #entries for 4-bits
mapLoop:
		push	ax			; save current index
		call	BMIndexToRGB		; RGB in al,bl,bh
		call	MapRGBTo16GreyDither	; get dither pattern index
		xchg	si, di			; need to pass ds:di to routine
		call	GrCopyDrawMask		; copy out dither pattern
		xchg	si, di			; restore registers
		add	si, 8			; bump to next patterm space
		pop	ax			; restore current index
		inc	al			; on to the next one
		loop	mapLoop


		;must unlock the Directory block if it was a HugeArray Bitmap
		;
		mov	ax, BMframe.BF_hugeBMlocked
		tst	ax
		jz	done
		mov	ds, ax			; ds is Dir block to unlock
		call	HugeArrayUnlockDir
done:
		.leave
		ret
InitVGAtoMono	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MapRGBTo16GreyDither
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Map an RGB triplet to one of our grey-scale patterns

CALLED BY:	INTERNAL
		InitVGAToMono

PASS:		al,bl,bh	- RGB triplet

RETURN:		al		- grey scale dither pattern enum
				- between SDM_0 and SDM_100

DESTROYED:	ah, bx

PSEUDO CODE/STRATEGY:
		This routine maps the RGB value to a grey scale level using the
		following relation:

	    	Map color to grey level.  This section of code maps an RGB 
		triplet into a value (0-63) that is used to pick one of 64 
		dither patterns.  The optimal mapping is: 
			level = .299*red + .587*green + .114*blue
		The mapping we use is:  
			level = .375*red + .500*green + .125*blue
		since it's easier/faster to calculate.


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MapRGBTo16GreyDither proc	near
		uses	ds
BMframe		local	BitmapFrame
		.enter	inherit

		;
		;  If the MixMode is such that the color won't matter in
		;  the end result, then we can skip the calculation of the
		;  dither
		;

		call	CalcDitherFromMixMode
		jc	done		

		mov	ah, bl
		mov	bl, bh

		call	GrCalcLuminance		; ax = luminance

		; we need to map this luminence value (0-255) to a smaller 
		; range (0-16) so that's a shift right two bits. We then 
		; need to index into a table of dither patterns, 8 bytes each.

		shr	al, 1			; divide luminence by 16
		shr	al, 1			; divide luminence by 16
		shr	al, 1			; divide luminence by 16
		shr	al, 1			; divide luminence by 16
		adc	al, 0			; round up
		shl	al, 1			; *4 for get 0-63
		shl	al, 1
		neg	ax			; subtract from SDM_0
		add	ax, SDM_0		; base mask value

done:
		.leave
		ret
MapRGBTo16GreyDither endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcDitherFromMixMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	This routine checks to see whether the dither can be
		calculated from the MixMode, which is the case for MixModes
		wherein the result is not a function of the source
		(eg. MM_SET, MM_CLEAR)
		
Pass:		nothing (inherits BitmapFrame)

Return:		If dither can be calculated from MixMode:

			carry set
			al	- grey scale dither pattern enum
				  between SDM_0 and SDM_100

		else:
			carry clear

Destroyed:	ah

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 24, 1993 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcDitherFromMixMode	proc	near
	uses	ds
BMframe		local	BitmapFrame
	.enter	inherit

	mov	ds, BMframe.BF_gstate
	mov	ah, ds:[GS_mixMode]

	;
	;  If the MixMode is either MM_SET, MM_CLEAR, or MM_INVERT,
	;  then we want SDM_100
	;
	cmp	ah, MM_SET
	je	returnTrue

	cmp	ah, MM_CLEAR
	je	returnTrue

	cmp	ah, MM_INVERT
	clc
	jnz	done

returnTrue:
	mov	al, SDM_0			;SDM_0 for some inverted reason
	stc

done:
	.leave
	ret
CalcDitherFromMixMode	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitSVGAtoMono
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do some initialization for 8-bit to monochrome conversion

CALLED BY:	INTERNAL
		InitFormatConversion

PASS:		BMframe

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		build out the table of dither patterns in the scratch space we
		are provided

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	08/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitSVGAtoMono	proc	near
		uses	es,ds,si,di,ax,bx,cx
BMframe		local	BitmapFrame
		.enter	inherit

		; this is where we'll want to check for palettes stored
		; with bitmaps

		mov	ds, BMframe.BF_finalBM.segment	; get original format
		test	BMframe.BF_opType, mask BMOT_SCALE ; already done ?
		jnz	calcConvertTable		;  yes, skip redo
		mov	al, BMframe.BF_origBMtype
		mov	cx, BMframe.BF_finalBMwidth ; get second y value
		call	CalcLineSize
		mov	BMframe.BF_scaledScanSize, ax ; and save it
calcConvertTable:
		mov	si, BMframe.BF_finalBM.offset
		mov	al, ds:[si].B_type
		mov	cx, BMframe.BF_finalBMwidth
		call	CalcLineSize		; ax = #bytes/scan
		mov	BMframe.BF_finalBMscanSize, ax ; store result
		mov	si, BMframe.BF_formatPtr

		; BMIndextoRGB takes es:di pointing at a palette -- either
		; one stored with the bitmap or the system palette
		;
		call	GetPointerToPalette

		clr	ax			; start out with index 0
		mov	BMframe.BF_formatScan, ax ; init variable
		mov	cx, 256			; #entries for 8-bits
mapLoop:
		push	ax			; save current index
		call	BMIndexToRGB		; RGB in al,bl,bh
		call	MapRGBTo16GreyDither	; get dither pattern index
		mov	ds:[si], al		; store pattern number
		inc	si			; bump to next patterm space
		pop	ax			; restore current index
		inc	al			; on to the next one
		loop	mapLoop


		;must unlock the Directory block if it was a HugeArray Bitmap
		;
		mov	ax, BMframe.BF_hugeBMlocked
		tst	ax
		jz	done
		mov	ds, ax			; ds is Dir block to unlock
		call	HugeArrayUnlockDir
done:
		.leave
		ret
InitSVGAtoMono	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BMIndexToRGB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A quick verison of the old standby.  

CALLED BY:	INTERNAL
		InitSVGAtoMono, InitVGAtoMono
PASS:		al		- index
		es:di		- pointer to palette to use
RETURN:		al,bl,bh	- equivalent RGB values
DESTROYED:	ah

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	11/17/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BMIndexToRGB	proc	near

		clr	ah
		mov	bx, ax
		shl	bx, 1
		add	bx, ax			; index *3
		mov	al, es:[di][bx]
		mov	bx, {word} es:[di][bx+1]

		ret
BMIndexToRGB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BMIndex256toIndex16
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	our version of MapRGBtoIndex

CALLED BY:	INTERNAL
		InitSVGAtoVGA
PASS:		al		- 256-value index
		es:di		- palette for bitmap data (either palette stored with
				  bitmap or the default palette)
RETURN:		ah		- closest match in 16-entry palette
DESTROYED:	bx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	11/17/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BMIndex256toIndex16	proc	near
		uses	ds, dx, cx, si
		.enter

		clr	ah
		mov	bx, ax
		shl	bx, 1
		add	bx, ax			; index *3
		mov	al, es:[di][bx].RGB_red
		mov	bx, {word} es:[di][bx].RGB_green
		mov	ch, 0xf		

		; Get a pointer to the palette for the window, the custom one,
		; if any, otherwise return a pointer to the default palette
		;
						; pass window segment in dx 
		call	GetCurrentPalette	; pointer to palette-> ds:si
		call	MapRGBtoIndex

		.leave
		ret
BMIndex256toIndex16	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitSVGAtoVGA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do some initialization for 8-bit to 4-bit conversion

CALLED BY:	INTERNAL
		InitFormatConversion

PASS:		BMframe

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		build out the table of dither patterns in the scratch space we
		are provided

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	08/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitSVGAtoVGA	proc	near
		uses	ds,si,di,ax,bx,cx,dx,es
BMframe		local	BitmapFrame
		.enter	inherit

		; this is where we'll want to check for palettes stored
		; with bitmaps
		mov	dx,es				; save window segment
		mov	ds, BMframe.BF_finalBM.segment	; get original format
		test	BMframe.BF_opType, mask BMOT_SCALE ; already done ?
		jnz	calcConvertTable		;  yes, skip redo
		mov	al, BMframe.BF_origBMtype
		mov	cx, BMframe.BF_finalBMwidth ; get second y value
		call	CalcLineSize
		mov	BMframe.BF_scaledScanSize, ax ; and save it
calcConvertTable:
		mov	si, BMframe.BF_finalBM.offset
		mov	al, ds:[si].B_type
		mov	cx, BMframe.BF_finalBMwidth
		call	CalcLineSize		; ax = #bytes/scan
		mov	BMframe.BF_finalBMscanSize, ax ; store result
		mov	si, BMframe.BF_formatPtr
		mov	BMframe.BF_formatScan, ax ; init variable

		; BMIndex256toIndex16 takes es:di pointing at a palette --
		; either one stored with the bitmap or the system palette
		call	GetPointerToPalette

		clr	ax			; start out with index 0
		mov	cx, 256			; #entries for 8-bits
		mov	dx, BMframe.BF_window
mapLoop:
		push	ax			; save current index
		call	BMIndex256toIndex16	; al -> ah
		mov	ds:[si], ah		; store pattern number
		inc	si			; bump to next patterm space
		pop	ax			; restore current index
		inc	al			; on to the next one
		loop	mapLoop

		;must unlock the Directory block if it was a HugeArray Bitmap
		;
		mov	ax, BMframe.BF_hugeBMlocked
		tst	ax
		jz	done
		mov	ds, ax			; ds is Dir block to unlock
		call	HugeArrayUnlockDir
done:
		.leave
		ret
InitSVGAtoVGA endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitRGBtoAll
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do some initialization for 24-bit to monochrome conversion
		Also used for 4-bit and 8-bit conversions		

CALLED BY:	INTERNAL
		InitFormatConversion

PASS:		BMframe

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		build out the table of dither patterns in the scratch space we
		are provided

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	08/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitRGBtoAll	proc	near
		uses	ds,si,di,ax,bx,cx
BMframe		local	BitmapFrame
		.enter	inherit

		; this is where we'll want to check for palettes stored
		; with bitmaps

		mov	ds, BMframe.BF_finalBM.segment	; get original format
		test	BMframe.BF_opType, mask BMOT_SCALE ; already done ?
		jnz	calcConvertTable		;  yes, skip redo
		mov	al, BMframe.BF_origBMtype
		mov	cx, BMframe.BF_finalBMwidth ; get second y value
		call	CalcLineSize
		mov	BMframe.BF_scaledScanSize, ax ; and save it
calcConvertTable:
		mov	si, BMframe.BF_finalBM.offset
		mov	al, ds:[si].B_type
		mov	cx, BMframe.BF_finalBMwidth
		call	CalcLineSize		; ax = #bytes/scan
		mov	BMframe.BF_finalBMscanSize, ax ; store result
		mov	si, BMframe.BF_formatPtr
		clr	ax			; start out with index 0
		mov	BMframe.BF_formatScan, ax ; init variable

		.leave
		ret
InitRGBtoAll	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChangeBitmapFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change to a simpler format

CALLED BY:	GLOBAL

PASS:		ss:bp	- pointer to DrawBitmap frame

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Basically, we have to change higher bit-per-pixel formats into
		lower bit-per-pixel formats.  This is so we can display, for
		example, an 8-bit/pixel image on a 4-bit/pixel device. 

		This routine acts as the distributor -- it figures out which
		format conversion routine is needed.  It bases that on what
		the two types of input bitmaps are, according to the 
		following table.  The (formats added)*2 column is how the
		jump table index is calculated.  Basically, the enums of the
		two formats are added and shifted left.  This yields 5
		distinct values for the 6 possibilities.  The last case is
		handled specially.
						(formats
		old format	new format	added)*2	Routine
		----------	----------	-------		-------	
		4-bit		1-bit		2		VGAtoMono
		8-bit		4-bit		6		SVGAtoVGA
		8-bit		1-bit		4		SVGAtoMono
		24-bit		8-bit		10		RGBtoSVGA
		24-bit		4-bit		8		RGBtoVGA
		24-bit		1-bit		6		RGBtoMono

		The way table that is build is a combination of the format
		bits for each of bitmap/device.  The B_type in the bitmap
		structure has a three bit field that describes the bitmap
		format, of which there are now four values defined:
		BMF_MONO(=0), BMF_4BIT(=1), BMF_8BIT(=2), BMF_24BIT(=3).
		The values for both device/bitmap are added, then multiplied
		by two to get a table index.  This leads to the mapping in 
		the above table

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	01/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChangeBitmapFormat proc	far
BMframe		local	BitmapFrame
		.enter	inherit

		; first load up all the registers we need.
		;	ds:si	-> pointer to source bitmap data
		;	es:di	-> pointer to destination area in bitmap
		;	ds:dx	-> pointer to mask for bitmap

		mov	si, BMframe.BF_finalBM.segment	; get original format
		mov	ds, si				; ds,es -> bitmap
		mov	es, si
		mov	si, BMframe.BF_finalBM.offset
		mov	bx, BMframe.BF_formatCombo
		mov	di, ds:[si].CB_data		; target is data space
		add	di, si				; es:di -> data area
		clr	dx				; assume no mask
		test	ds:[si].B_type, mask BMT_MASK	; any mask with bitmap?
		jz	haveMaskPtr			;  no, all done
		mov	dx, di				;  yes, copy offset
haveMaskPtr:
		call	cs:FormatRoutines[bx]		; do the conversion
		.leave
		ret
ChangeBitmapFormat endp

		; This table holds the offsets to the bitmap format conversion
		; routines.  See the header for the function ChangeBitmapFormat

FormatRoutines	label	nptr
		nptr	0			; cannot happen
		nptr	offset VGAtoMono	; 4bit -> 1bit
		nptr	offset SVGAtoMono	; 8bit -> 1bit
		nptr	offset SVGAtoVGA	; 8bit -> 4bit
		nptr	offset RGBtoVGA		; 24bit -> 4bit
		nptr	offset RGBtoSVGA	; 24bit -> 8bit
		nptr	offset RGBtoMono	; 24bit -> 1bit

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VGAtoMono
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert bitmap pixels from 4-bit to monochrome

CALLED BY:	INTERNAL
		ChangeBitmapFormat

PASS:		BMframe stack frame
		ds:si		- points to bitmap header of bitmap containing
				  data to convert
		es:di		- points to beginning data section of same 
				  bitmap
		dx		- 0 if no mask in bitmap, else offset to 
				  mask info (same as di coming in to routine)

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		This routine maps color pixels to some grey scale level (dither
		pattern).

		Basically, we have to go through the slice and replace the 
		4-bit pixels there with monochrome data.  We map the colors
		to dither patterns, then select the proper bit within the 
		dither to choose whether to set/reset the bit.

		Build dither pattern table (4-bit index -> dither pattern #)
		   {this was done earlier in InitFormatConversion...}

		For each scan line of the slice:
		    For each pixel in source scan
			map pixel to dither bit
			accumulate bits
			if (bitmap has a mask)
			    AND with the mask
			if (filled out an entire byte)
			    store to the destination

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		this code should check for a color palette stored with the
		bitmap.

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	08/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetHighDither	macro
		lodsb				; get the next source byte
		mov	cl, al			; make a copy
		shr	al, 1			; high nibble (1st pixel) * 8
		and	al, 0xf8		; eliminate low three bits
		or	al, dh			; al = index into table
		clr	ah
		xchg	ax, bx			; save format table pointer
		add	bx, ax			; ds:bx = ptr to scan in dither
		mov	bh, ds:[bx]		; get the dither scan
		xchg	ax, bx			; restore regs
endm

GetLowDither	macro
		mov	al, cl			; recover other pixel
		and	al, 0xf			; just want low bits
		mov	cl, 3			; shift count
		shl	al, cl
		or	al, dh
		clr	ah
		xchg	ax, bx			; save format table pointer
		add	bx, ax			; ds:bx = ptr to scan in dither
		mov	bh, ds:[bx]		; get the dither scan
		xchg	ax, bx			; restore regs
endm

VGAtoMono	proc	near
		uses	si,di,ax,bx,cx,dx
BMframe		local	BitmapFrame
		.enter	inherit

		; compute #bytes in the source scan line...

		mov	ax, BMframe.BF_finalBMwidth
		add	ax, 7			; round up to next byte
		mov	cl, 3
		shr	ax, cl			; divide by eight for #bytes
		mov	bx, BMframe.BF_formatPtr ; get ptr to convert table
		or	dl, dh			; dl = mask flag (0=no mask)
		mov	dh, {byte} BMframe.BF_formatScan ; just need low 3 bits

		; for each scan line...

		mov	cx, ds:[si].CB_numScans
		tst	cx			; if zero, dont do anything
		LONG jz	done
		add	si, ds:[si].CB_data
		tst	dl			; is there a mask there ?
		jz	setTarget		;  no, continue
		mov	BMframe.BF_formatMaskPtr, si  ; yes, save mask pointer
		add	si, ax			;   and bump past mask

setTarget:
		;
		; We want to preserve the mask, so bump di to point
		; right at the data, skipping the mask
		; 
		mov	di, si

scanLoop:
		push	cx
		push	ax,si,di,dx		; save pointers, values

		mov	cx, ax			; cx = #bytes in scan line
		and	dh, 7			; index into dither

		; this loop is executed for each byte of the CONVERTED data
		; basically, we keep accumulating the bits until we have a 
		; bytes worth, then write it out.  In this loop:
		;	ax = scratch registers
		;	bx = pointer to format conversion table
		;	ch = accumulated pixel
		;	cl = scratch
		;	dl = mask flag (0=no mask)
		;	dh = low three bits of current scan line
		;	ds:si = source pointer
		;	es:di = dest pointer.  if there is a mask, this also
		;		points at the mask.
byteLoop:
		push	cx			; save #bytes left to do
		GetHighDither			; ah = dither byte
		rcl	ah, 1			; get the bit we want
		rcl	ch, 1			; accumualte it
		GetLowDither			; ah = dither byte
		rcl	ah, 1			; its the 2nd bit in
		rcl	ah, 1
		rcl	ch, 1			; accumulate 2nd bit
		GetHighDither			; ...and so on....
		rcl	ah, 1
		rcl	ah, 1
		rcl	ah, 1
		rcl	ch, 1
		GetLowDither
		rcl	ah, 1
		rcl	ah, 1
		rcl	ah, 1
		rcl	ah, 1
		rcl	ch, 1
		GetHighDither
		rcr	ah, 1
		rcr	ah, 1
		rcr	ah, 1
		rcr	ah, 1
		rcl	ch, 1
		GetLowDither
		rcr	ah, 1
		rcr	ah, 1
		rcr	ah, 1
		rcl	ch, 1
		GetHighDither
		rcr	ah, 1
		rcr	ah, 1
		rcl	ch, 1
		GetLowDither
		rcr	ah, 1
		rcl	ch, 1

		; now we have ch = byte we want to store.  if there is a
		; mask, then and it in, else store it.

		mov	al, ch
		not	al			; bitmap data 1=black
		stosb
		pop	cx			; restore num scans left
		sub	cx, 1
		LONG ja byteLoop

		; on to the next scan line

		pop	ax,si,di,dx		; restore pointers
		mov	cx, BMframe.BF_scaledScanSize
		add	si, cx			; bump the source pointer
		add	di, BMframe.BF_finalBMscanSize
		inc	BMframe.BF_formatScan	; on to the next one
		inc	dh			; on to the next scan line
		add	BMframe.BF_formatMaskPtr, cx

		; see if we're done yet

		pop	cx
		dec	cx
		jcxz	done

		; if necessary, copy the mask data the next line

		tst	dl			; if no mask, leave it that way
		jz	nextScan
		push	cx, si
		mov	si, BMframe.BF_formatMaskPtr	;ds:si <- source mask
		sub	di, ax
		mov	cx, ax				;cx <- n bytes
		rep movsb				;spunk!
		pop	cx, si
nextScan:
		jmp	scanLoop
done:
		.leave
		ret
VGAtoMono	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SVGAtoMono
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert bitmap pixels from 8-bit to monochrome

CALLED BY:	INTERNAL
		ChangeBitmapFormat

PASS:		BMframe stack frame

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		This routine maps color pixels to some grey scale level (dither
		pattern).

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	08/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetDither	macro
		lodsb				; get the next source byte
		clr	ah			; need word offset
		xchg	ax, bx			; save format table pointer
		add	bx, ax			; ds:bx = ptr to scan in dither
		mov	bl, ds:[bx]		; get the dither number
		clr	bh
		shl	bx, 1
		shl	bx, 1
		shl	bx, 1			; 8-bytes/dither
		or	bl, dh			; take scan line into account
		mov	bh, es:[di][bx]
		xchg	ax, bx			; restore regs
endm

SVGAtoMono	proc	near
		uses	si,di,ax,bx,cx,dx
BMframe		local	BitmapFrame
		.enter	inherit

		; compute #bytes in the source scan line...

		mov	ax, BMframe.BF_finalBMwidth
		add	ax, 7			; round up to next byte
		mov	cl, 3
		shr	ax, cl			; divide by eight for #bytes
		mov	bx, BMframe.BF_formatPtr ; get ptr to convert table
		or	dl, dh			; dl = mask flag (0=no mask)
		mov	dh, {byte} BMframe.BF_formatScan ; just need low 3 bits

		; for each scan line...

		mov	cx, ds:[si].CB_numScans
		tst	cx			; if zero, dont do anything
		LONG jz	done
		add	si, ds:[si].CB_data
		tst	dl			; is there a mask there ?
		jz	setTarget		;  no, continue
		mov	BMframe.BF_formatMaskPtr, si  ; yes, save mask pointer
		add	si, ax			;   and bump past mask

setTarget:
		;
		; We want to preserve the mask, so bump di to point
		; right at the data, skipping the mask
		; 
		mov	di, si

scanLoop:
		push	cx
		push	ax,si,di,dx		; save pointers, values

		mov	cx, ax			; cx = #bytes in scan line
		and	dh, 7			; index into dither

		; this loop is executed for each byte of the CONVERTED data
		; basically, we keep accumulating the bits until we have a 
		; bytes worth, then write it out.  In this loop:
		;	ax = scratch registers
		;	bx = pointer to format conversion table
		;	ch = accumulated pixel
		;	cl = scratch
		;	dl = mask flag (0=no mask)
		;	dh = low three bits of current scan line
		;	ds:si = source pointer
		;	es:di = dest pointer.  if there is a mask, this also
		;		points at the mask.
byteLoop:
		push	cx			; save #bytes left to do
		push	es, di
		LoadVarSeg es
		mov	di, offset idata:sysPatt00 ; set source to system table
		GetDither			; ah = dither byte
		rcl	ah, 1			; get the bit we want
		rcl	ch, 1			; accumualte it
		GetDither			; ah = dither byte
		rcl	ah, 1			; its the 2nd bit in
		rcl	ah, 1
		rcl	ch, 1			; accumulate 2nd bit
		GetDither			; ...and so on....
		rcl	ah, 1
		rcl	ah, 1
		rcl	ah, 1
		rcl	ch, 1
		GetDither
		rcl	ah, 1
		rcl	ah, 1
		rcl	ah, 1
		rcl	ah, 1
		rcl	ch, 1
		GetDither
		rcr	ah, 1
		rcr	ah, 1
		rcr	ah, 1
		rcr	ah, 1
		rcl	ch, 1
		GetDither
		rcr	ah, 1
		rcr	ah, 1
		rcr	ah, 1
		rcl	ch, 1
		GetDither
		rcr	ah, 1
		rcr	ah, 1
		rcl	ch, 1
		GetDither
		rcr	ah, 1
		rcl	ch, 1
		pop	es, di

		; now we have ch = byte we want to store.

		mov	al, ch
		not	al			; bitmap data 1=black
		stosb
		pop	cx			; restore num scans left
		sub	cx, 1
		LONG ja byteLoop

		; on to the next scan line

		pop	ax,si,di,dx		; restore pointers
		mov	cx, BMframe.BF_scaledScanSize
		add	si, cx			; bump the source pointer
		add	di, BMframe.BF_finalBMscanSize
		inc	BMframe.BF_formatScan	; on to the next one
		inc	dh			; on to the next scan line
		add	BMframe.BF_formatMaskPtr, cx ; set it up

		; see if we're done yet

		pop	cx
		dec	cx
		jcxz	done

		; if necessary, copy the mask data the next line

		tst	dl			; if no mask, leave it that way
		jz	nextScan
		push	cx, si
		mov	si, BMframe.BF_formatMaskPtr	;ds:si <- source mask
		sub	di, ax
		mov	cx, ax				;cx <- n bytes
		rep movsb				;spunk!
		pop	cx, si
nextScan:
		jmp	scanLoop
done:
		.leave
		ret
SVGAtoMono	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SVGAtoVGA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert bitmap pixels from 8-bit to 4-bit color

CALLED BY:	INTERNAL
		ChangeBitmapFormat

PASS:		BMframe stack frame

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		This routine maps 256 colors to 16.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	08/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetIndex16	macro
		lodsb				; get the next source byte
		shl	ch, cl			; shift up color
		clr	ah			; need word offset
		xchg	ax, bx			; save format table pointer
		add	bx, ax
		mov	bl, ds:[bx]		; get 16-value color
		or	ch, bl
		mov	bx, ax			; restore regs
endm

SVGAtoVGA	proc	near
		uses	si,di,ax,bx,cx,dx
BMframe		local	BitmapFrame
		.enter	inherit

		; compute #bytes in the source scan line...

		mov	ax, BMframe.BF_finalBMwidth
		inc	ax			; round up to next byte
		shr	ax, 1			; divide by two for #bytes
		mov	bx, BMframe.BF_formatPtr ; get ptr to convert table
		or	dl, dh			; dl = mask flag (0=no mask)

		; for each scan line...

		mov	cx, ds:[si].CB_numScans
		jcxz	done			; if zero, don't do anything
		add	si, ds:[si].CB_data
		tst	dl			; is there a mask there ?
		jz	setTarget		;  no, continue

		; adjust width to account for mask bytes

		mov	BMframe.BF_formatMaskPtr, si  ; yes, save mask pointer
		push	ax
		mov	ax, BMframe.BF_finalBMwidth
		add	ax, 7
		shr	ax, 1
		shr	ax, 1
		shr	ax, 1
		mov	BMframe.BF_origBMmaskSize, ax
		add	si, ax			;   and bump past mask
		pop	ax

		; we don't want to nuke the mask anymore, so bump the dest
		; pointer past the mask
setTarget:
		mov	di, si
scanLoop:
		push	cx
		push	ax,si,di,dx		; save pointers, values

		mov	cx, ax			; cx = #bytes in scan line

		; this loop is executed for each byte of the CONVERTED data
		; basically, we keep accumulating the bits until we have a 
		; bytes worth, then write it out.  In this loop:
		;	ax = scratch registers
		;	bx = pointer to format conversion table
		;	ch = accumulated pixel
		;	cl = scratch
		;	dl = mask flag (0=no mask)
		;	dh = mask byte
		;	ds:si = source pointer
		;	es:di = dest pointer.  if there is a mask, this also
		;		points at the mask.
byteLoop:
		push	cx			; save #bytes left to do
		mov	cl, 4
		GetIndex16
		GetIndex16
		mov	al, ch			; byte to store
		stosb	
		pop	cx			; restore byte count
		loop	byteLoop

		; on to the next scan line

		pop	ax,si,di,dx		; restore pointers
		mov	cx, BMframe.BF_scaledScanSize
		add	si, cx			; bump the source pointer
		add	di, BMframe.BF_finalBMscanSize
		inc	BMframe.BF_formatScan	; on to the next one
		add	BMframe.BF_formatMaskPtr, cx ; set it up

		; see if we're done yet

		pop	cx
		dec	cx
		jcxz	done

		; if necessary, copy the mask data the next line

		tst	dl			; if no mask, leave it that way
		jz	nextScan
		push	cx, si
		mov	si, BMframe.BF_formatMaskPtr	;ds:si <- source mask
		mov	cx, BMframe.BF_origBMmaskSize	;cx <- size of mask data
		sub	di, cx
		rep movsb				;spunk!
		pop	cx, si
nextScan:
		jmp	scanLoop
done:
		.leave
		ret
SVGAtoVGA	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RGBtoMono
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert bitmap pixels from 24-bit to monochrome

CALLED BY:	INTERNAL
		ChangeBitmapFormat

PASS:		BMframe stack frame

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		This routine maps color pixels to some grey scale level (dither
		pattern).

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	08/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetRGBDither	macro
		mov	bx, {word} ds:[si].RGB_green
		lodsb
		add	si, 2
		call	MapRGBTo16GreyDither	; get dither pattern index
		mov	bl, al
		clr	bh
		shl	bx, 1
		shl	bx, 1
		shl	bx, 1			; 8-bytes/dither
		or	bl, dh			; take scan line into account
		mov	ah, es:[di][bx]
endm


RGBtoMono	proc	near
		uses	si,di,ax,bx,cx,dx
BMframe		local	BitmapFrame
		.enter	inherit

		; compute #bytes in the source scan line...

		mov	ax, BMframe.BF_finalBMwidth
		add	ax, 7			; round up to next byte
		mov	cl, 3
		shr	ax, cl			; divide by eight for #bytes
		or	dl, dh			; dl = mask flag (0=no mask)
		mov	dh, {byte} BMframe.BF_formatScan ; just need low 3 bits

		; for each scan line...

		mov	cx, ds:[si].CB_numScans
		tst	cx			; if zero, dont do anything
		LONG jz	done
		add	si, ds:[si].CB_data
		tst	dl			; is there a mask there ?
		jz	setTarget		;  no, continue
		mov	BMframe.BF_formatMaskPtr, si  ; yes, save mask pointer
		add	si, ax			;   and bump past mask

setTarget:
		;
		; We want to preserve the mask, so bump di to point
		; right at the data, skipping the mask
		; 
		mov	di, si

scanLoop:
		push	cx
		push	ax,si,di,dx		; save pointers, values

		mov	cx, ax			; cx = #bytes in scan line
		and	dh, 7			; index into dither

		; this loop is executed for each byte of the CONVERTED data
		; basically, we keep accumulating the bits until we have a 
		; bytes worth, then write it out.  In this loop:
		;	ax = scratch registers
		;	bx = pointer to format conversion table
		;	ch = accumulated pixel
		;	cl = scratch
		;	dl = mask flag (0=no mask)
		;	dh = low three bits of current scan line
		;	ds:si = source pointer
		;	es:di = dest pointer.  if there is a mask, this also
		;		points at the mask.
byteLoop:
		push	cx			; save #bytes left to do
		push	es, di
		LoadVarSeg es
		mov	di, offset idata:sysPatt00 ; set source to system table
		GetRGBDither			; ah = dither byte
		rcl	ah, 1			; get the bit we want
		rcl	ch, 1			; accumualte it
		GetRGBDither			; ah = dither byte
		rcl	ah, 1			; its the 2nd bit in
		rcl	ah, 1
		rcl	ch, 1			; accumulate 2nd bit
		GetRGBDither			; ...and so on....
		rcl	ah, 1
		rcl	ah, 1
		rcl	ah, 1
		rcl	ch, 1
		GetRGBDither
		rcl	ah, 1
		rcl	ah, 1
		rcl	ah, 1
		rcl	ah, 1
		rcl	ch, 1
		GetRGBDither
		rcr	ah, 1
		rcr	ah, 1
		rcr	ah, 1
		rcr	ah, 1
		rcl	ch, 1
		GetRGBDither
		rcr	ah, 1
		rcr	ah, 1
		rcr	ah, 1
		rcl	ch, 1
		GetRGBDither
		rcr	ah, 1
		rcr	ah, 1
		rcl	ch, 1
		GetRGBDither
		rcr	ah, 1
		rcl	ch, 1
		pop	es, di

		; now we have ch = byte we want to store.  if there is a
		; mask, then and it in, else store it.

		mov	al, ch
		not	al			; bitmap data 1=black
		stosb
		pop	cx			; restore num scans left
		sub	cx, 1
		LONG ja byteLoop

		; on to the next scan line

		pop	ax,si,di,dx		; restore pointers
		mov	cx, BMframe.BF_scaledScanSize
		add	si, cx			; bump the source pointer
		add	di, BMframe.BF_finalBMscanSize
		inc	BMframe.BF_formatScan	; on to the next one
		inc	dh			; on to the next scan line
		add	BMframe.BF_formatMaskPtr, cx ; set it up

		; see if we're done yet

		pop	cx
		dec	cx
		jcxz	done

		; if necessary, copy the mask data the next line

		tst	dl
		jz	nextScan
		push	cx, si
		mov	si, BMframe.BF_formatMaskPtr	;ds:si <- source mask
		sub	di, ax
		mov	cx, ax				;cx <- n bytes
		rep movsb				;spunk!
		pop	cx, si
nextScan:
		jmp	scanLoop
done:
		.leave
		ret
RGBtoMono	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BMRGBtoIndex
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	local version of kernel routine

CALLED BY:	INTERNAL
		RGBtoVGA, RGBtoSVGA
PASS:		al,bl,bh	- RGBValue
		ah		- #palette entries to check
RETURN:		ah		- index closest
DESTROYED:	al, bx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	11/18/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BMRGBtoIndex		proc	far
		uses	ds, si, cx,dx
BMframe		local	BitmapFrame
		.enter	inherit

		mov	dx, BMframe.BF_window
		call	GetCurrentPalette
		mov	ch, ah
		call	MapRGBtoIndex
		.leave
		ret
BMRGBtoIndex		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RGBtoVGA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert bitmap pixels from 24-bit to 4-bit color

CALLED BY:	INTERNAL
		ChangeBitmapFormat

PASS:		BMframe stack frame

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		This routine maps color pixels to some other lower res 
		color level.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	08/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetRGBIndex16	macro
		mov	bx, {word} ds:[si].RGB_green
		lodsb				; get the next source byte
		add	si, 2
		mov	ah, 0xf	
		call	BMRGBtoIndex
		shl	ch, cl			; shift up color
		or	ch, ah
endm

RGBtoVGA	proc	near
		uses	si,di,ax,bx,cx,dx
BMframe		local	BitmapFrame
		.enter	inherit

		; compute #bytes in the source scan line...

		mov	ax, BMframe.BF_finalBMwidth
		inc	ax			; round up to next byte
		shr	ax, 1			; divide by two for #bytes
		mov	bx, BMframe.BF_formatPtr ; get ptr to convert table
		or	dl, dh			; dl = mask flag (0=no mask)

		; for each scan line...

		mov	cx, ds:[si].CB_numScans
		tst	cx			; if zero, dont do anything
		LONG jz	done
		add	si, ds:[si].CB_data
		tst	dl			; is there a mask there ?
		jz	setTarget		;  no, continue
		mov	BMframe.BF_formatMaskPtr, si  ; yes, save mask pointer
		push	ax
		mov	ax, BMframe.BF_finalBMwidth
		add	ax, 7
		shr	ax, 1
		shr	ax, 1
		shr	ax, 1
		mov	BMframe.BF_origBMmaskSize, ax
		add	si, ax			;   and bump past mask
		pop	ax

		; we don't want to nuke the mask anymore, so bump the dest
		; pointer past the mask
setTarget:
		mov	di, si
scanLoop:
		push	cx
		push	ax,si,di,dx		; save pointers, values

		mov	cx, ax			; cx = #bytes in scan line

		; this loop is executed for each byte of the CONVERTED data
		; basically, we keep accumulating the bits until we have a 
		; bytes worth, then write it out.  In this loop:
		;	ax = scratch registers
		;	bx = pointer to format conversion table
		;	ch = accumulated pixel
		;	cl = scratch
		;	dl = mask flag (0=no mask)
		;	dh = mask byte
		;	ds:si = source pointer
		;	es:di = dest pointer.  if there is a mask, this also
		;		points at the mask.
byteLoop:
		push	cx			; save #bytes left to do
		mov	cl, 4
		GetRGBIndex16
		GetRGBIndex16
		mov	al, ch			; byte to store
		stosb	
		pop	cx			; restore byte count
		loop	byteLoop

		; on to the next scan line

		pop	ax,si,di,dx		; restore pointers
		mov	cx, BMframe.BF_scaledScanSize
		add	si, cx			; bump the source pointer
		add	di, BMframe.BF_finalBMscanSize
		inc	BMframe.BF_formatScan	; on to the next one
		add	BMframe.BF_formatMaskPtr, cx ; set it up

		; see if we're done yet

		pop	cx
		dec	cx
		jcxz	done

		; if necessary, copy the mask data the next line

		tst	dl			; if no mask, leave it that way
		jz	nextScan
		push	cx, si
		mov	si, BMframe.BF_formatMaskPtr	;ds:si <- source mask
		mov	cx, BMframe.BF_origBMmaskSize	;cx <- size of mask data
		sub	di, cx
		rep movsb				;spunk!
		pop	cx, si
nextScan:
		jmp	scanLoop
done:
		.leave
		ret
RGBtoVGA	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RGBtoSVGA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert bitmap pixels from 24-bit to 8-bit color

CALLED BY:	INTERNAL
		ChangeBitmapFormat

PASS:		BMframe stack frame

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		This routine maps color pixels to some other lower res 
		color level.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	08/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetRGBIndex256	macro
		local	doMap, done
		mov	bx, {word} ds:[si].RGB_green
		lodsb				; get the next source byte
		add	si, 2
		cmp	BMframe.BF_lastMapBlueGreen, bx
		jne	doMap
		cmp	BMframe.BF_lastMapIndexRed.low, al  ; red in low byte
		jne	doMap
		mov	al, BMframe.BF_lastMapIndexRed.high ; index in high byte
		jmp	done
doMap:
		mov	BMframe.BF_lastMapBlueGreen, bx
		mov	BMframe.BF_lastMapIndexRed.low, al
		mov	ah, 255
		call	BMRGBtoIndex
		mov	al, ah			; al <- result
		mov	BMframe.BF_lastMapIndexRed.high, al
done:
endm

RGBtoSVGA	proc	near
		uses	si,di,ax,bx,cx,dx
BMframe		local	BitmapFrame
		.enter	inherit

		; initialize RGB/index cache in stack frame

		clr	ax
		mov	BMframe.BF_lastMapIndexRed, ax
		mov	BMframe.BF_lastMapBlueGreen, ax

		; compute #bytes in the source scan line...

		mov	ax, BMframe.BF_finalBMwidth
		or	dl, dh			; dl = mask flag (0=no mask)

		; for each scan line...

		mov	cx, ds:[si].CB_numScans
		tst	cx			; if zero, dont do anything
		LONG jz	done
		add	si, ds:[si].CB_data
		tst	dl			; is there a mask there ?
		jz	setTarget		;  no, continue
		mov	BMframe.BF_formatMaskPtr, si  ; yes, save mask pointer
		push	ax
		mov	ax, BMframe.BF_finalBMwidth
		add	ax, 7
		shr	ax, 1
		shr	ax, 1
		shr	ax, 1
		mov	BMframe.BF_origBMmaskSize, ax
		add	si, ax			;   and bump past mask
		pop	ax

		; we don't want to nuke the mask anymore, so bump the dest
		; pointer past the mask
setTarget:
		mov	di, si
scanLoop:
		push	cx
		push	ax,si,di,dx		; save pointers, values

		mov	cx, ax			; cx = #bytes in scan line

		; this loop is executed for each byte of the CONVERTED data
		; basically, we keep accumulating the bits until we have a 
		; bytes worth, then write it out.  In this loop:
		;	ax = scratch registers
		;	bx = pointer to format conversion table
		;	dl = mask flag (0=no mask)
		;	ds:si = source pointer
		;	es:di = dest pointer.  if there is a mask, this also
		;		points at the mask.
byteLoop:
		GetRGBIndex256
		stosb
		loop	byteLoop

		; on to the next scan line

		pop	ax,si,di,dx		; restore pointers
		mov	cx, BMframe.BF_scaledScanSize
		add	si, cx			; bump the source pointer
		add	di, BMframe.BF_finalBMscanSize
		inc	BMframe.BF_formatScan	; on to the next one
		add	BMframe.BF_formatMaskPtr, cx ; set it up

		; see if we're done yet

		pop	cx
		dec	cx
		jcxz	done

		; if necessary, copy the mask data the next line

		tst	dl			; if no mask, leave it that way
		jz	nextScan
		push	cx, si
		mov	si, BMframe.BF_formatMaskPtr	;ds:si <- source mask
		mov	cx, BMframe.BF_origBMmaskSize	;cx <- size of mask data
		sub	di, cx
		rep movsb				;spunk!
		pop	cx, si
nextScan:
		jmp	scanLoop
done:
		.leave
		ret
RGBtoSVGA	endp

GraphicsDrawBitmap 	ends
