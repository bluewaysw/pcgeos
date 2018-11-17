COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel graphics	
FILE:		graphicsBitmapHuge.asm

AUTHOR:		Jim DeFrisco, Jan 20, 1992

ROUTINES:
	Name			Description
	----			-----------
    GLB GrDrawHugeBitmapAtCP	Draw a bitmap that resides in a HugeArray
    GLB GrDrawHugeBitmap	Draw a bitmap that resides in a HugeArray

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	1/20/92		Initial revision


DESCRIPTION:
	This code is very similar to GrDrawBitmap, but is separated so
	that we can store it in another module.
		

	$Id: graphicsBitmapHuge.asm,v 1.1 97/04/05 01:13:03 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GraphicsDrawBitmap	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrFillHugeBitmap  GrFillHugeBitmapAtCP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Treat a monochrome bitmap as a mask, filling it with the
		current area color.

CALLED BY:	GLOBAL

PASS:		di	- GStateHandle
		ax,bx	- x,y coordinate to draw at (doc units) (not for AtCP)
		dx	- VM file handle (or zero if TPD_file is set)
		cx	- VM block handle

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		same as GrFillBitmap, except we can draw more.

	The format of the bitmap block is as follows:

		+-------------------------------+
		| HugeArray Directory Header	|
		+-------------------------------+
		| Complex Bitmap Header		|
		+-------------------------------+
		| 				|
		| Data Buffer			|
		| 				|
		+-------------------------------+

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		this generates a normal GrDrawBitmap opcode for GString 
		purposes.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	11/18/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrFillHugeBitmapAtCP proc	far
		call	EnterGraphics
		call	GetDocPenPos
		jnc	maskHBitmapCommon

		; handle writing to a gstring

		mov	al, GR_FILL_BITMAP_CP ; set opcode
		jmp	gsHBMcpCommon
GrFillHugeBitmapAtCP endp

GrFillHugeBitmap proc	far
BMframe		local	BitmapFrame
		call	EnterGraphics		; returns with  ds->gState
		call	SetDocPenPos
		jnc	maskHBitmapCommon

		; handle writing to a gstring

		push	cx, dx		; save HugeArray handle
		mov	dx, bx		; write out coordinate and opcode
		mov	bx, ax
		mov	al, GR_FILL_BITMAP
		jmp	gsHBMCommon

maskHBitmapCommon label	near
		call	TrivialRejectFar	; check null window, clip

		; finally, we can start in earnest.

		.enter				; allocate stack frame

		mov	BMframe.BF_cbFunc.segment, 0 	; save ptr to callback
		mov	BMframe.BF_origBM.segment, dx	; save VM file handle
		mov	BMframe.BF_origBM.offset, cx	; save block handle too
		clr	cx
		mov	BMframe.BF_finalBMsliceSize, cx	; init # bytes/scanline
		mov	BMframe.BF_getSliceDSize, cx ; init callback flag 
		mov	BMframe.BF_opType,  mask BMOT_FILL_MASK
		jmp	drawFillHugeBitmap
		.leave	.UNREACHED
GrFillHugeBitmap endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrDrawHugeBitmap, GrDrawHugeBitmapAtCP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a bitmap that resides in a HugeArray

CALLED BY:	GLOBAL

PASS:		di	- GStateHandle
		ax,bx	- x,y coordinate to draw at (doc units) (not for AtCP)
		dx	- VM file handle (or zero if TPD_file is set)
		cx	- VM block handle

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		same as GrDrawBitmap, except we can draw more.

	The format of the bitmap block is as follows:

		+-------------------------------+
		| HugeArray Directory Header	|
		+-------------------------------+
		| Complex Bitmap Header		|
		+-------------------------------+
		| 				|
		| Data Buffer			|
		| 				|
		+-------------------------------+

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		this generates a normal GrDrawBitmap opcode for GString 
		purposes.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	1/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrDrawHugeBitmapAtCP proc far
		call	EnterGraphics
		call	GetDocPenPos		; get current pen position
		jnc	drawHugeBitmapCommon

		; handle writing to a gstring

		mov	al, GR_DRAW_BITMAP_CP	; set opcode
gsHBMcpCommon	label	near
		mov	bx, cx			; save register
		clr	cl			; no data bytes
		mov	ch, GSSC_DONT_FLUSH
		call	GSStoreBytes		; just write opcode
		mov	cx, bx			; restore reg
		jmp	writeHugeBMData		; join up with code below
GrDrawHugeBitmapAtCP endp

		; graphical segment open...
hbmGString	label	near
		push	cx, dx		; save HugeArray handle
		mov	dx, bx		; write out coordinate and opcode
		mov	bx, ax
		mov	al, GR_DRAW_BITMAP
gsHBMCommon	label	near
		mov	cl, size Point	; write data bytes at first
		mov	ch, GSSC_DONT_FLUSH
		call	GSStoreBytes	; write em out
		pop	cx, dx		; restore callback address

		; now write out bitmap data (including header)
writeHugeBMData	label	near
		call	HugeBitmapToString ; copy bitmap to graphics string
		jmp	ExitGraphicsGseg

GrDrawHugeBitmap	proc	far
BMframe		local	BitmapFrame
		call	EnterGraphics		; returns with  ds->gState
		call	SetDocPenPos		; set new pen position
		jc	hbmGString		

		; make sure there is no evil window lurking
drawHugeBitmapCommon label	near

		call	TrivialRejectFar	; check null window, clip

		; finally, we can start in earnest.

		.enter				; allocate stack frame

		mov	BMframe.BF_cbFunc.segment, 0 	; save ptr to callback
		mov	BMframe.BF_origBM.segment, dx	; save VM file handle
		mov	BMframe.BF_origBM.offset, cx	; save block handle too
		clr	cx
		mov	BMframe.BF_finalBMsliceSize, cx	; init # bytes/scanline
		mov	BMframe.BF_getSliceDSize, cx	; init callback flag 
		mov	BMframe.BF_opType,  cl		; init function pointer
drawFillHugeBitmap	label	near
		mov	BMframe.BF_imageFlags, cl	; not doing image thing
		mov	BMframe.BF_args.PBA_flags, cx	; clear the flags
		mov	BMframe.BF_stateFlags, cx	; init state flags

		; store the starting position (& error in that position)
		; for the bitmap (assumes document coord for bitmap origin
		; is in (ax, bx))

		call	BitmapSetDrawPoint	; window coords -> (ax, bx)
		LONG jc hBitmapEnd

		; get the format of the video buffer (bits/pixel)

		mov	cx, ds			; save GState seg
		mov	di, DR_VID_INFO		; get ptr to info table
		call	es:[W_driverStrategy]	; driver knows where
		mov	ds, dx			; set ds:si -> table
		mov	dl, ds:[si].VDI_bmFormat ; bitmap format supp
		and	dl, mask BMT_FORMAT	; isolate color part
		mov	BMframe.BF_deviceType, dl ; and save it

		; access the bitmap header to see if we need to allocate more
		; room.

		mov	bx, BMframe.BF_origBM.segment	; get file handle
		mov	di, BMframe.BF_origBM.offset	; get block handle
		call	HugeArrayLockDir
		mov	ds, ax				; ds -> dir block
		mov	si, offset EB_bm		; ds:si -> bitmap hdr

if	(DISPLAY_CMYK_BITMAPS eq FALSE)
EC <		mov	dl, ds:[si].B_type	; get color format	>
EC <		and	dl, mask BMT_FORMAT				>
EC <		cmp	dl, BMF_4CMYK		; don't do this		>
EC <		ERROR_AE GRAPHICS_CMYK_BITMAPS_NOT_SUPPORTED		>
endif

		; see if we need to do some massaging of the data

		call	BMCheckAllocation	; more work to do ?
		LONG jc	habAlloc

		; nothing complicated about this bitmap.  just draw it.
		; fill in the header info, then loop to do each piece.  
		; cx = GState segment, bx = HugeArrayDir mem block handle

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

		; lock down the next set of scan lines, 
lockNextBlock:
		push	ax			      ; save curr scan line
		push	dx			      ; save GState segment 
		clr	dx
		mov	bx, BMframe.BF_origBM.segment ; get file handle
		mov	di, BMframe.BF_origBM.offset  ; get block handle
		call	HugeArrayLock		      ; ds:si -> element
		mov	BMframe.BF_args.PBA_bm.B_height, ax ; store #lines 
		mov	BMframe.BF_args.PBA_data.offset, si
		mov	BMframe.BF_args.PBA_data.segment, ds
		pop	ds			      ; restore GState
		mov	di,DR_VID_PUTBITS	      ; use putbits
		pop	bx			      ; restore current scan
		push	bx			      ; save stuff for vid call
		mov	ax, BMframe.BF_drawPoint.P_x
		add	bx, BMframe.BF_drawPoint.P_y
		call	es:[W_driverStrategy]	      ; make call to driver
		mov	dx, ds			      ; save GState segment
		mov	ds, BMframe.BF_args.PBA_data.segment
		call	HugeArrayUnlock
		pop	ax			      ; restore scan, GState
		add	ax, BMframe.BF_args.PBA_bm.B_height ; on to next one
		cmp	ax, BMframe.BF_origBMscansLeft ; done with bitmap ?
		jb	lockNextBlock
hBitmapEnd:
		test	BMframe.BF_args.PBA_flags, mask PBF_ALLOC_PALETTE
		jz	palFreed
		mov	bx, {word} BMframe.BF_palette	; get handle
		call	MemFree			; release block
palFreed:
		.leave				; restore stack
		jmp	ExitGraphics		; all done, go home

;-------------------------------------------------------------------------

		; need to alloc some space, use different routine.  This will
		; end up drawing the whole thing.
habAlloc:
		push	ds			; save HugeArrayDir blk han
		call	DrawSlice		; alloc and draw
		pop	ds
		call	HugeArrayUnlockDir	; release dir block
		jmp	hBitmapEnd

GrDrawHugeBitmap	endp

GraphicsDrawBitmap	ends
