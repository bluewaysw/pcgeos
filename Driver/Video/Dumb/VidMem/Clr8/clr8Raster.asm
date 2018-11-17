COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Video Drivers	
FILE:		vga8Raster.asm

AUTHOR:		Jim DeFrisco, Oct  8, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/ 8/92		Initial revision

DESCRIPTION:

	$Id: vga8Raster.asm,v 1.1 97/04/18 11:42:04 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VidSegment	Blt


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BltSimpleLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	blt a single scan line 

CALLED BY:	INTERNAL

PASS:		bx	- first x point in simple region
		ax	- last x point in simple region
		d_x1	- left side of blt
		d_x2	- right side of blt
		es:si	- points to scan line start of source
		es:di	- points to scan line start of dest


RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:
		if source is to right of destination
		   mask left;
		   copy left byte;
		   mask = ff;
		   copy middle bytes
		   mask right;
		   copy right byte;
		else
		   do the same, but from right to left

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

NMEM <.assert		((offset writeWindow) +1) eq (offset readWindow) >

BltSimpleLine	proc	near
		uses	ds
		.enter
NMEM <		mov	ds, ss:[readSegment]	; ds -> read window	>
MEM  <		mov	ds, ss:[bm_lastSegSrc]	; get source segment	>

		; calc some setup values

		mov	bx, ss:[bmLeft]		; save passed values
		mov	ax, ss:[bmRight]

		; calculate # bytes to fill in and indices into source and 
		; dest scan lines.  We have to compensate here if the left 
		; side of the clip region is to the right of the left side 
		; of the destination rectangle.

		mov	dx, bx			; save left clipped side
		add	di, bx			; setup dest pointer
		sub	dx, ss:[d_x1]		; sub dest unclipped left side
		add	dx, ss:[d_x1src]	; get offset to source
		add	si, dx			;  add that to source index
		sub	ax, bx			; ax = count of bytes - 1
		mov	cx, ax			; cx = count-1

		; see if using one window or two

NMEM <		mov	ax, {word} ss:[writeWindow]			>
NMEM <		cmp	al, ah			; if one window, check ypos >
NMEM <		je	oneWindow					>

		; we have two memory windows.  Cool.  Just do the copy.
NMEM <fastCopy:								>
		mov	ax, ss:[d_x1]		; if going right, copy left
		cmp	ax, ss:[d_x1src]	; 
		jle	goingLeft
		std				; copy backwards
		add	si, cx			; start on right side
		add	di, cx
goingLeft:
		inc	cx
		rep	movsb			; copy 'em
		cld				; restore direction in case
NMEM <done:								>
		.leave
		ret

ifndef	IS_MEM
		; have a single window.  Probably have to use temp buffer
oneWindow:
		mov	dx, ss:[curWinPageSrc]	; see if on the same scan line
		cmp	dx, ss:[curWinPage]	;  so we can do direct copy
		je	fastCopy		; nope.  use the buffer.

		; not the same window. Use the temp buffer to do the copy.

		inc	cx
		push	di, cx			; save real destination
		segmov	es, cs, di
		mov	di, offset bltBuffer	; point at our space
		mov	bl, ss:[readWindow]
		call	SetWinPage
		rep	movsb			; copy the source
		pop	di, cx
		segmov	es, ds, si
		segmov	ds, cs, si
		mov	si, offset bltBuffer
		mov	bl, ss:[writeWindow]
		mov	dx, ss:[curWinPage]
		call	SetWinPage
		rep	movsb
		jmp	done
endif

BltSimpleLine	endp

ifndef	IS_MEM

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetWinPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Just set the current memory window

CALLED BY:	INTERNAL
PASS:		bl	- window to set
		dx	- which window to set
RETURN:		nothing
DESTROYED:	bx,dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	10/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetWinPage	proc	near
		clr	bh
		tst	ss:[modeInfo].VMI_winFunc.segment ; check for routine
		jz	useInterrupt
		call	ss:[modeInfo].VMI_winFunc	; set page
done:		
		ret

useInterrupt:
		mov	ax, VESA_WINDOW_CONTROL or (VESA_BIOS_EXT shl 8)
		int	VIDEO_BIOS
		jmp	done		
SetWinPage	endp

bltBuffer	byte	1024 dup (?)			; allocate max
endif

VidEnds		Blt


VidSegment 	Bitmap


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PutColor8Scan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw an 8-bit/pixel scan line of bitmap data

CALLED BY:	INTERNAL
		
PASS:		d_x1	- x coordinate to start drawing
		d_y1	- scan line to draw to
		d_x2	- x coordinate of right side of image
		d_dx	- width of image (pixels)
		d_bytes	- width of image (bytes) (bytes/scan/plane)

		ax	- rightmost ON point for simple region
		bx	- leftmost ON point for simple region
		ds:si	- pointer to bitmap data
		es	- segment of frame buffer

RETURN:		bp intact

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:

		build out a group of 8 pixels, then
		write each byte, using write mode 0 of EGA

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/26/92	Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PutColor8Scan	proc	near

		; calculate # bytes to fill in

		mov	bx, ss:[bmLeft]
		mov	ax, ss:[d_x1]		; 
		add	si, bx			; 
		sub	si, ax			; ds:si -> pic bytes
		add	di, bx			; es:di -> dest bytes
		mov	cx, ss:[bmRight]	; compute #bytes to write
		sub	cx, bx			; #bytes-1
		inc	cx

		; check for a palette
		test	ss:[bmType], mask BMT_PALETTE	; test for palette
		jnz	mapPalette

		shr	cx, 1			; #words
		jnc	moveWords
		movsb
		jcxz	done
moveWords:
		rep	movsw
done:
		ret

mapPalette:
		; handle the case where there is a palette with the bitmap.
		; Read each byte, look it up in the table, then write that
		; corresponding byte out
		;
		lodsb				; get the first byte
		push	es			; map to palette
		les	bx, ss:[bmPalette]	; es:bx - palette
		xlat	es:[bx]
		pop	es
		stosb				; write to frame buffer
		loop	mapPalette
		jmp	done

PutColor8Scan	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PutColor8ScanMask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw an 8-bit/pixel scan line of bitmap data

CALLED BY:	INTERNAL
		
PASS:		d_x1	- x coordinate to start drawing
		d_y1	- scan line to draw to
		d_x2	- x coordinate of right side of image
		d_dx	- width of image (pixels)
		d_bytes	- width of image (bytes) (bytes/scan/plane)

		ax	- rightmost ON point for simple region
		bx	- leftmost ON point for simple region
		ds:si	- pointer to bitmap data
		es	- segment of frame buffer

RETURN:		bp intact

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:

		build out a group of 8 pixels, then
		write each byte, using write mode 0 of EGA

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
n	----	----		-----------
	Jim	10/26/92	Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PutColor8ScanMask	proc	near

		; calculate # bytes to fill in

		mov	bx, ss:[bmLeft]
		mov	ax, ss:[d_x1]		; 
		sub	bx, ax			; bx = index into pic data
		mov	dx, bx			; save index
		mov	cx, bx
		xchg	bx, si			; ds:bx -> mask data
		add	si, bx
		sub	bx, ss:[bmMaskSize]	; ds:si -> pic data
		shr	dx, 1
		shr	dx, 1
		shr	dx, 1			; bx = index into mask
		add	bx, dx			; ds:bx -> into mask data
		add	di, ax			; es:di -> dest bytes
		and	cl, 7
		mov	dh, 0x80		; test bit for mask data
		shr	dh, cl			; dh = starting mask bit
		mov	cx, ss:[bmRight]	; compute #bytes to write
		sub	cx, ss:[bmLeft]		; #bytes-1
		inc	cx
		mov	dl, ds:[bx]		; get first mask byte
		inc	bx
		; check for a palette
		test	ss:[bmType], mask BMT_PALETTE	; test for palette
		jnz	mapPalette
pixLoop:
		lodsb
		test	dl, dh			; do this pixel ?
		jz	nextPixel
		mov	es:[di], al		; store it
nextPixel:
		inc	di
		shr	dh, 1			; move test bit down
		jc	reloadTester		;  until we need some more
haveTester:
		loop	pixLoop

done:
		ret

		; done with this mask byte, get next
reloadTester:
		mov	dl, ds:[bx]		; load next mask byte
		inc	bx
		mov	dh, 0x80
		jmp	haveTester

mapPalette:
		lodsb
		push	es, bx			; map to palette
		les	bx, ss:[bmPalette]	; es:bx - palette
		xlat	es:[bx]
		pop	es, bx
		test	dl, dh			; do this pixel ?
		jz	paletteNextPixel
		mov	es:[di], al		; store it
paletteNextPixel:
		inc	di
		shr	dh, 1			; move test bit down
		jc	paletteReloadTester	;  until we need some more
paletteHaveTester:
		loop	mapPalette
		jmp	done

		; done with this mask byte, get next
paletteReloadTester:
		mov	dl, ds:[bx]		; load next mask byte
		inc	bx
		mov	dh, 0x80
		jmp	paletteHaveTester
PutColor8ScanMask	endp


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PutColorScan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Transfer a scan line's worth of system memory to screen

CALLED BY:	INTERNAL

PASS:		d_x1	- x coordinate to start drawing
		d_y1	- scan line to draw to
		d_x2	- x coordinate of right side of image
		d_dx	- width of image (pixels)
		d_bytes	- width of image (bytes) (bytes/scan/plane)

		ax	- rightmost ON point for simple region
		bx	- leftmost ON point for simple region
		ds:si	- pointer to bitmap data
		es	- segment of frame buffer

RETURN:		bp intact

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:

		build out a group of 8 pixels, then
		write each byte, using write mode 0 of EGA

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/26/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

PutColorScan	proc	near
		uses	bp
		.enter

		; calculate # bytes to fill in

		mov	bx, ss:[bmLeft]
		mov	bp, bx			; get # bits into image
		sub	bp, ss:[d_x1]		; get left coordinate
		mov	ax, ss:[bmRight]	; get right side to get #bytes
		mov	dx, bp			; save low bit
		shr	bp, 1			; bp = #bytes index
		add	si, bp			; index into bitmap
		add	di, bx			; add to screen offset too
		mov	bp, ax			; get right side in bp
		sub	bp, bx			; bp = # dest bytes to write -1
		inc	bp			; bp = #dest bytes to write
		mov	cl, 4			; shift amount

		; check for a palette
		test	ss:[bmType], mask BMT_PALETTE	; test for palette
		jnz	handlePalette

		; we're all setup.  See if we're taking pixels from front or
		; rear (check shift value)

		test	dl, 1			; see if starting odd or even
		jz	evenLoop

		; do first one specially

		lodsb
		and	al, 0xf
		stosb
		dec	bp
		jz	done

		; specially, though.
evenLoop:
		lodsb				; get next byte
		mov	ah, al			; split them up
		shr	al, cl			; align stuff
		sub	bp, 2
		js	lastByte
		and	ax, 0x0f0f		; isolate pixels
		stosw				; store pixel values
		tst	bp			; if only one byte to do...
		jnz	evenLoop
done:
		.leave
		ret

		; odd number of bytes to do.  Last one here...
lastByte:
		stosb
		jmp	done
	
handlePalette:
		; we're all setup.  See if we're taking pixels from front or
		; rear (check shift value)

		test	dl, 1			; see if starting odd or even
		jz	paletteEvenLoop

		; do first one specially

		lodsb
		and	al, 0xf
		push	es
		les	bx, ss:[bmPalette]	; es:bx - palette
		xlat	es:[bx]
		pop	es

		stosb
		dec	bp
		jz	done

		; specially, though.
paletteEvenLoop:
		lodsb				; get next byte
		mov	ah, al			; split them up
		shr	al, cl			; align stuff
		and	ax, 0x0f0f		; isolate pixels
		push	es
		les	bx, ss:[bmPalette]	; es:bx - palette
		xlat	es:[bx]
		pop	es
		sub	bp, 2
		js	lastByte
		xchg	ah,al
		push	es
		les	bx, ss:[bmPalette]	; es:bx - palette
		xlat	es:[bx]
		pop	es
		xchg	ah,al
		stosw				; store pixel values
		tst	bp			; if only one byte to do...
		jnz	paletteEvenLoop
		jmp	done

PutColorScan	endp


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PutColorScanMask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Transfer a scan line's worth of system memory to screen
		applying a bitmap mask

CALLED BY:	INTERNAL

PASS:		d_x1	- x coordinate to start drawing
		d_y1	- scan line to draw to
		d_x2	- x coordinate of right side of image
		d_dx	- width of image (pixels)
		d_bytes	- width of image (bytes) (bytes/scan/plane)

		ax	- rightmost ON point for simple region
		bx	- leftmost ON point for simple region
		ds:si	- pointer to bitmap data
		es	- segment of frame buffer

RETURN:		bp intact

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:

		build out a group of 8 pixels, then
		write each byte, using write mode 0 of EGA

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/26/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

PutColorScanMask	proc	near
		uses	bp
		.enter

		; calculate # bytes to fill in

		mov	ax, ss:[bmLeft]
		mov	bp, ax			; get # bits into image
		sub	bp, ss:[d_x1]		; get left coordinate
		mov	dx, bp			; save low bit
		mov	bx, bp			; save pixel index into bitmap
		sar	bp, 1			; compute index into pic data
		sar	bx, 1			; compute index into mask data
		sar	bx, 1
		sar	bx, 1
		add	bx, si			; ds:bx -> mask byte
		sub	bx, ss:[bmMaskSize]	; ds:si -> picture data
		add	si, bp			; ds:si -> into picture data
		add	di, ax			; add to screen offset too
		mov	bp, ss:[bmRight]	; get right side in bp
		sub	bp, ax			; bp = # dest bytes to write -1
		inc	bp
		mov	cl, dl			; need index into mask byte
		mov	ch, 0x80		; form test bit for BM mask
		and	cl, 7
		shr	ch, cl			; ch = mask test bit
		mov	cl, 4			; cl = pic data shift amount

		; get first mask byte

		mov	dh, ds:[bx]		; dh = mask byte
		inc	bx			; get ready for next mask byte


		; check for a palette
		test	ss:[bmType], mask BMT_PALETTE	; test for palette
		jnz	handlePalette


		; we're all setup.  See if we're taking pixels from front or
		; rear (check shift value)

		test	dl, 1			; see if starting odd or even
		jz	evenLoop

		; do first one specially

		lodsb
		test	dh, ch			; mask bit set ?
		jz	doneFirst
		and	al, 0xf
		mov	es:[di], al
doneFirst:
		inc	di
		dec	bp
		jz	done
		shr	ch, 1			; test next bit
		jnc	evenLoop
		mov	dh, ds:[bx]		; load next mask byte
		inc	bx
		mov	ch, 0x80		; reload test bit

		; specially, though.
evenLoop:
		lodsb				; get next byte
		mov	ah, al			; split them up
		shr	al, cl			; align stuff
		and	ax, 0x0f0f		; isolate pixels
		test	dh, ch			; check pixel
		jz	doSecond
		mov	es:[di], al
doSecond:
		inc	di
		dec	bp			; one less to go
		jz	done
		shr	ch, 1
		test	dh, ch
		jz	nextPixel
		mov	es:[di], ah
nextPixel:
		inc	di
		shr	ch, 1
		jc	reloadTester
haveTester:
		dec	bp
		jnz	evenLoop
done:
		.leave
		ret

reloadTester:
		mov	dh, ds:[bx]		; get next mask byte
		inc	bx
		mov	ch, 0x80
		jmp	haveTester

handlePalette:
		; we're all setup.  See if we're taking pixels from front or
		; rear (check shift value)

		test	dl, 1			; see if starting odd or even
		jz	paletteEvenLoop

		; do first one specially

		lodsb
		test	dh, ch			; mask bit set ?
		jz	paletteDoneFirst
		and	al, 0xf
		push	es, bx			; save these
		les	bx, ss:[bmPalette]	; es:di -> palettw
		xlat	es:[bx]			; al = color value
		pop	es, bx			; restore
		mov	es:[di], al
paletteDoneFirst:
		inc	di
		dec	bp
		jz	done
		shr	ch, 1			; test next bit
		jnc	paletteEvenLoop
		mov	dh, ds:[bx]		; load next mask byte
		inc	bx
		mov	ch, 0x80		; reload test bit

		; specially, though.
paletteEvenLoop:
		lodsb				; get next byte
		mov	ah, al			; split them up
		shr	al, cl			; align stuff
		and	ax, 0x0f0f		; isolate pixels
		test	dh, ch			; check pixel
		jz	paletteDoSecond
		push	es, bx
		les	bx, ss:[bmPalette]	; es:bx - palette
		xlat	es:[bx]
		pop	es, bx
		mov	es:[di], al

paletteDoSecond:
		inc	di
		dec	bp			; one less to go
		jz	done
		shr	ch, 1
		test	dh, ch
		jz	paletteNextPixel
		mov	al, ah			; get second pixel value in al
		push	es, bx
		les	bx, ss:[bmPalette]	; es:bx - palette
		xlat	es:[bx]			; look up palette value
		pop	es, bx
		mov	es:[di], al
paletteNextPixel:
		inc	di
		shr	ch, 1
		jc	paletteReloadTester
paletteHaveTester:
		dec	bp
		jnz	paletteEvenLoop
		jmp	done

paletteReloadTester:
		mov	dh, ds:[bx]		; get next mask byte
		inc	bx
		mov	ch, 0x80
		jmp	paletteHaveTester
PutColorScanMask endp


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillBWScan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Transfer a scan line's worth of system memory to screen
		draws monochrome info as a mask, using current area color

CALLED BY:	INTERNAL

PASS:		d_x1	- x coordinate to start drawing
		d_y1	- scan line to draw to
		d_x2	- x coordinate of right side of image
		d_dx	- width of image (pixels)
		d_bytes	- width of image (bytes) (bytes/scan/plane)

		ax	- rightmost ON point for simple region
		bx	- leftmost ON point for simple region
		ds:si	- pointer to bitmap data
		es	- segment of frame buffer

RETURN:		bp intact

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:
		set drawing color;
		mask left;
		shift and copy left byte;
		shift and copy middle bytes
		mask right;
		shift and copy right byte;
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	1/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

FillBWScan	proc	near

		mov	dl, ss:currentColor	; dl = color to draw
fillPutCommon	label	near
		push	bp
		mov	bx, ss:[bmLeft]
		mov	ax, ss:[bmRight]

		; calculate # bytes to fill in

		add	di, bx			; add to screen offset 
		mov	bp, bx			; get #bits into image at start
		mov	cx, ss:[d_x1]		; get left coordinate
		sub	bp, cx			; bp = (bmLeft-x1)
		sub	ax, cx			; ax = (bmRight-x1)
		mov	dh, al			; figure new right mask
		and	dh, 7
		mov	ss:[bmShift], dh
		mov	bx, bp			; save low three bits of x indx
		mov	cl, 3
		sar	bp, cl			; compute byte index
		add	si, bp			; add bytes-to-left-side
		sar	ax, cl
		sub	ax, bp			; ax = (#srcBytes-1) to write
		mov	cx, bx
		and	cl, 7
		mov	dh, 0x80		; dh = test bit
		shr	dh, cl			;       properly aligned
		mov	cx, ax			; cx = source byte count - 1
		mov	ah, ss:lineMask		; draw mask to use
		jcxz	lastByte

		; for each byte of input data
byteLoop:
		lodsb				; next data byte
		call	WriteMonoByte
		loop	byteLoop

		; the loop will do all but the last byte.  It's probably a 
		; partial byte, so apply the right mask before finishing
lastByte:
		mov	al, 0x80
		mov	cl, ss:[bmShift]	
		sar	al, cl
		and	ah, al
		lodsb
		call	WriteMonoByte
		
		pop	bp
		ret
FillBWScan	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PutBWScan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a b/w scan line of a monochrome bitmap

CALLED BY:	INTERNAL
		PutBitsSimple
PASS:		bitmap drawing vars setup by PutLineSetup
RETURN:		nothing
DESTROYED:	most everything

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PutBWScan	proc	near
		clr	dl			; filling with black
		jmp	fillPutCommon
PutBWScan	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteMonoByte
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a monochrome source byte to the screen

CALLED BY:	INTERNAL
		PutBWScan
PASS:		al	- byte to write
		ah	- bitmap draw mask
		dh	- bit mask of bit to start with
		es:di	- frame buffer pointer
		dl	- color to use to draw
RETURN:		dh	- 0x80
DESTROYED:	bx

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	10/26/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteMonoByte	proc	near
		and	al, ah		; apply bitmap mask
pixLoop:
		test	al, dh		; check next pixel
		jz	nextPixel

		mov	bl, es:[di]
		call	ss:[modeRoutine]
		mov	es:[di], bl	; store pixel color
nextPixel:
		inc	di		; next pixel
		shr	dh, 1		; go until we hit a carry
		jnc	pixLoop

		mov	dh, 0x80	; reload test bit
		ret
WriteMonoByte	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PutBWScanMask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a monochrome bitmap with a store mask

CALLED BY:	see above
PASS:		
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PutBWScanMask	proc	near
		uses	bp
		.enter
		mov	bx, ss:[bmLeft]
		mov	ax, ss:[bmRight]

		; calculate # bytes to fill in

		add	di, bx			; add to screen offset too
		mov	bp, bx			; get #bits into image at start
		mov	cx, ss:[d_x1]		; get left coordinate
		sub	bp, cx			; bp = (bmLeft-x1)
		sub	ax, cx			; ax = (bmRight-x1)
		mov	dl, al			; figure new right mask
		and	dl, 7
		mov	ss:[bmShift], dl
		mov	dx, bp			; save low three bits of x indx
		mov	cl, 3			; want to get byte indices
		sar	bp, cl
		add	si, bp			; add bytes-to-left-side
		sar	ax, cl
		sub	ax, bp			; ax = (#srcBytes-1) to write
		mov	cl, dl			; need low three bits of index
		and	cl, 7
		mov	dh, 0x80		; dh = test bit
		shr	dh, cl			;       properly aligned
		clr	dl			; dl = color to draw
		mov	cx, ax			; cx = source byte count - 1
		mov	bp, si			; ds:bp -> mask data
		sub	bp, ss:[bmMaskSize]	; ds:si -> picture data
		jcxz	lastByte

		; for each byte of input data
byteLoop:
		lodsb				; next data byte
		mov	ah, ds:[bp]		; get mask byte
		inc	bp
		and	ah, ss:lineMask
		call	WriteMonoByte
		loop	byteLoop

		; the loop will do all but the last byte.  It's probably a 
		; partial byte, so apply the right mask before finishing
lastByte:
		mov	ah, 0x80
		mov	cl, ss:[bmShift]
		sar	ah, cl
		and	ah, ds:[bp]
		and	ah, ss:lineMask
		lodsb
		call	WriteMonoByte
		
		.leave
		ret
PutBWScanMask	endp

NullBMScan	proc	near
		ret
NullBMScan	endp

VidEnds		Bitmap


NMEM <VidSegment	GetBits						>
MEM  <VidSegment	Misc						>

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetOneScan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy one scan line of video buffer to system memory

CALLED BY:	INTERNAL
		VidGetBits

PASS:		ds:si	- address of start of scan line in frame buffer
		es:di	- pointer into sys memory where scan line to be stored
		cx	- # bytes left in buffer
		d_x1	- left side of source
		d_dx	- # source pixels
		shiftCount - # bits to shift

RETURN:		es:di	- pointer moved on past scan line info just stored
		cx	- # bytes left in buffer
			- set to -1 if not enough room to fit next scan (no
			  bytes are copied)

DESTROYED:	ax,bx,dx,si

PSEUDO CODE/STRATEGY:
		if (there's enough room to fit scan in buffer)
		   copy the scan out
		else
		   just return

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	04/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
		public	GetOneScan
GetOneScan	proc	near
		uses	si, cx
		.enter

		; form full address, copy bytes

		cmp	cx, ss:[d_dx]		; get width to copy
		jb	noRoom
		add	si, ss:[d_x1]		; setup source pointer
		mov	cx, ss:[d_dx]
		rep	movsb
done:
		.leave
		ret

		; not enough room to copy scan line
noRoom:
		mov	cx, 0xffff
		jmp	done
GetOneScan	endp

NMEM <VidEnds		GetBits						>
MEM <VidEnds		Misc						>

VidSegment	Bitmap


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ByteModeRoutines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Various stub routines to implement mix modes

CALLED BY:	INTERNAL
		various low-level drawing routines
PASS:		dl - color
		bl - screen
RETURN:		bl - destination (byte to write out)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		jim	10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ByteModeRoutines	proc		near
	ForceRef ByteModeRoutines

ByteCLEAR	label near
		clr	bl
ByteNOP		label near
		ret
ByteCOPY	label  near
		mov	bl, dl
		ret
ByteAND		label  near		
		and	bl, dl
		ret
ByteINV		label  near
		clr	bh
		mov	bl, ss:NOTtable[bx]
		ret
ByteXOR		label  near
		xor	bl, dl
		ret
ByteSET		label  near
		mov	bl, 0xff
		ret
ByteOR		label  near
		or	bl, dl
		ret
ByteModeRoutines	endp


ByteModeRout	label	 word
	nptr	ByteCLEAR
	nptr	ByteCOPY
	nptr	ByteNOP
	nptr	ByteAND
	nptr	ByteINV
	nptr	ByteXOR
	nptr	ByteSET
	nptr	ByteOR

VidEnds		Bitmap
