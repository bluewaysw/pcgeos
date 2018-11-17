COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Video Drivers	
FILE:		vga8Output.asm

AUTHOR:		Jim DeFrisco, Oct  7, 1992

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/ 7/92	Initial revision

DESCRIPTION:
	Low-level rectangle drawing routines for 8-bit devices

	$Id: vga8Output.asm,v 1.1 97/04/18 11:42:03 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawOptRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a rectangle with draw mode GR_COPY and all bits in the
		draw mask set

CALLED BY:	INTERNAL
		DrawSimpleRect
PASS:		dx - number of bytes covered by rectangle - 1
		cx - pattern index (scan line number AND 7)
		es:di - buffer address for first left:top of rectangle
		ds - Window structure
		bp - number of lines to draw
RETURN:		nothing	
DESTROYED:	ax,bx,cx,dx,si,di,bp

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		jim	10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DrawOptRect	proc	near

		; check the dither flag and do the right thing

		test	cs:[driverState], mask VS_DITHER
		LONG jnz	BlastDitheredRect

		; drawing a solid rectangle.  See if it's just one pixel wide,
		; and use the quick one...

NMEM <		mov	si, cs:[modeInfo].VMI_scanSize ; optimization	>
		mov	al, cs:[currentColor]	; get current color index
		mov	ah, al
		tst	dx
		jz	oneByteWide

		; calculate #bytes in the middle of the line and
		; offset to next line

		inc	dx			; total #bytes in line

NMEM <		cmp	di, cs:[lastWinPtr]	; is it in the last line    >
NMEM <		jae	firstPartial		; check for complete line   >

lineLoop:
		mov	cx, dx			; setup count
		shr	cx, 1
		jnc	doWords
		stosb
doWords:
		rep	stosw			; fill in scan line
		sub	di, dx			; restore line pointer
		dec	bp			; fewer scans to do
		jz	done
NMEM <		NextScan di, si			; adj ptr to next scan line >
MEM <		NextScan di			; adj ptr to next scan line >
NMEM <		jc	lastWinLine		; oops, on last line in win >
NMEM <		jmp	lineLoop					>
MEM <		tst	cs:[bm_scansNext]	; if negative, bogus	 >
MEM <		jns	lineLoop					>
done:
		ret

ifndef	IS_MEM
		; first line is already an partial scan
firstPartial:
		clc
		call	SetNextWin

		; the current line is no totally in the window, so take it slow
lastWinLine:
		cmp	dx, cs:[pixelsLeft]	; if doing less, do normal
		jb	lineLoop
		mov	cx, cs:[pixelsLeft]	; #pixels left in window
		shr	cx, 1
		jnc	doLastWords1
		stosb
doLastWords1:
		rep	stosw		
		call	MidScanNextWin		; goto next window
		mov	cx, dx			; setup remaining count
		sub	cx, cs:[pixelsLeft]
		shr	cx, 1
		jcxz	null1
		jnc	doLastWords2
		stosb
doLastWords2:
		rep	stosw			; do remaining part of line
null1:
		dec	bp
		jz	done
		FirstWinScan			; set di to start of next
		jmp	lineLoop
endif		

		; it's only a byte wide.  Do it quickly.
oneByteWide:
		mov	cx, bp			; get line count in cd
oneLoop:
		mov	es:[di], al		; store the color
		dec	cx			; one less line to do
		jz	done
NMEM <		NextScan di, si			; always enuf room todo 1 pix >
MEM <		NextScan di			; always enuf room todo 1 pix >
MEM <		tst	cs:[bm_scansNext]	;			>
MEM <		js	done						>
		jmp	oneLoop

DrawOptRect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BlastDitheredRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a rectangle in MM_COPY, mask all 1s, dithered.

CALLED BY:	INTERNAL
		DrawOptRect
PASS:		dx - number of words covered by rectangle + 1
		cx - pattern index (scan line number AND 7)
		es:di - buffer address for first left:top of rectangle
		bp - number of lines to draw
RETURN:		nothing	
DESTROYED:	ax,bx,cx,dx,si,di,bp

PSEUDO CODE/STRATEGY:
		We have a 4x4 ditherMatrix, so align stuff and copy the 
		four bytes across in the right order.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BlastDitheredRect proc	near

		; setup some stuff.  Get index to point at beginning of
		; ditherMatrix scan line (each 4 bytes), get scan size

		call	SetTempDither		; setup tempDither matrix
		mov	bx, cx			; line offset in bx
		shl	bx, 1			; *4
		shl	bx, 1
		and	bx, 0x0c		; pointer into tempDither
NMEM <		mov	si, cs:[modeInfo].VMI_scanSize ; optimization	>

		tst	dx
		jz	oneByteWide

		; calculate #bytes in the middle of the line and
		; offset to next line

		inc	dx			; total #bytes in line

NMEM <		cmp	di, cs:[lastWinPtr]	; is it in the last line    >
NMEM <		jae	firstPartial		; check for complete line   >

lineLoop:
		call	BlastDitheredScan	; do a scan line
		dec	bp			; fewer scans to do
		jz	done
		add	bl, 4			; onto next scan
		and	bl, 0xc			; limit it to 16 bytes
NMEM <		NextScan di,si			; adjust ptr to next scan line>
NMEM <		jc	lastWinLine		; oops, on last line in wind.>
MEM <		NextScan di			; adjust ptr to next scan line>
MEM <		tst	cs:[bm_scansNext]	;			>
MEM <		jns	lineLoop					>
NMEM <		jmp	lineLoop					>
done:
		ret

ifndef	IS_MEM
		; first line is already an partial scan
firstPartial:
		clc
		call	SetNextWin

		; the current line is no totally in the window, so take it slow
lastWinLine:
		cmp	dx, cs:[pixelsLeft]	; if doing less, do normal
		jb	lineLoop
		push	dx
		mov	dx, cs:[pixelsLeft]
		call	BlastDitheredScan
		call	MidScanNextWin		; goto next window
		pop	dx
		push	dx
		sub	dx, cs:[pixelsLeft]
		tst	dx
		jz	null1
		call	BlastDitheredScan
null1:
		pop	dx
		dec	bp
		jz	done
		add	bl, 4			; onto next scan
		and	bl, 0xc			; limit it to 16 bytes
		FirstWinScan			; set di to start of next
		jmp	lineLoop
endif		

		; it's only a byte wide.  Do it quickly.
oneByteWide:
		mov	al, cs:[tempDither][bx]
		mov	es:[di], al		; store the color
		dec	bp			; one less line to do
		jz	done
		add	bl, 4
		and	bl, 0xc
NMEM <		NextScan di, si			; always enuf room todo 1 pix >
MEM <		NextScan di			; always enuf room todo 1 pix >
MEM <		tst	cs:[bm_scansNext]	;			>
MEM <		js	done						>
		jmp	oneByteWide
BlastDitheredRect endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BlastDitheredScan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do a single scan line of dither stuff

CALLED BY:	BlastDitheredRect
PASS:		bx	- offset into tempDither of current scan line
		dx	- #pixels to write
		es:di	- points at starting pixel
		tempDither	- already setup (entries rotated in X so
				  that the first element in each scan is
				  the Nth element in the ditherMatrix scan
				  where N=(left side of rect) AND 7

RETURN:		nothing
DESTROYED:	ax, cx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	10/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BlastDitheredScan	proc	near
		mov	ax, {word} cs:[tempDither][bx]
		mov	cx, {word} cs:[tempDither][bx+2]
		push	dx
		jmp	startLine
pixLoop:
		stosb				; first byte
		mov	es:[di], ah
		inc	di
		mov	es:[di], cl
		inc	di
		mov	es:[di], ch
		inc	di
startLine:
		sub	dx, 4
		jns	pixLoop

		; down to less than 4 pixels on the scan line, do one at a time

		add	dx, 4
		jz	doneLine
		stosb
		dec	dx
		jz	doneLine
		mov	es:[di], ah
		inc	di
		dec	dx
		jz	doneLine
		mov	es:[di], cl
		inc	di
doneLine:
		pop	dx
		sub	di, dx			; restore line pointer
		ret
BlastDitheredScan	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetTempDither
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Optimization to setup a temporary dither matrix with the
		scan lines rotated in x to reflect which pixel we are 
		starting on (enables more efficient drawing routines)
CALLED BY:	INTERNAL
PASS:		si	- x offset (at least low two bits of it)
RETURN:		nothing
DESTROYED:	al, si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	10/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetTempDither	proc	near
		test	cs:[driverState], mask VS_DITHER
		jnz	handleDither
		mov	al, cs:[currentColor]
		mov	ah, al
		mov	cs:{word} [tempDither], ax
		mov	cs:{word} [tempDither+2], ax
		mov	cs:{word} [tempDither+4], ax
		mov	cs:{word} [tempDither+6], ax
		mov	cs:{word} [tempDither+8], ax
		mov	cs:{word} [tempDither+10], ax
		mov	cs:{word} [tempDither+12], ax
		mov	cs:{word} [tempDither+14], ax
done:
		ret
handleDither:
		and	si, 3
		test	si, 1
		jnz	handleOdd

		; deal with si=0 or si=2

		mov	ax, {word} cs:[ditherMatrix]
		mov	{word} cs:[tempDither][si], ax
		mov	ax, {word} cs:[ditherMatrix+4]
		mov	{word} cs:[tempDither+4][si], ax
		mov	ax, {word} cs:[ditherMatrix+8]
		mov	{word} cs:[tempDither+8][si], ax
		mov	ax, {word} cs:[ditherMatrix+12]
		mov	{word} cs:[tempDither+12][si], ax
		xor	si, 2
		mov	ax, {word} cs:[ditherMatrix+2]
		mov	{word} cs:[tempDither][si], ax
		mov	ax, {word} cs:[ditherMatrix+6]
		mov	{word} cs:[tempDither+4][si], ax
		mov	ax, {word} cs:[ditherMatrix+10]
		mov	{word} cs:[tempDither+8][si], ax
		mov	ax, {word} cs:[ditherMatrix+14]
		mov	{word} cs:[tempDither+12][si], ax
		jmp	done

		; have to wrap wierd, si=1 or si=3
handleOdd:
		dec	si
		mov	ax, {word} cs:[ditherMatrix+1]
		mov	{word} cs:[tempDither][si], ax
		mov	ax, {word} cs:[ditherMatrix+5]
		mov	{word} cs:[tempDither+4][si], ax
		mov	ax, {word} cs:[ditherMatrix+9]
		mov	{word} cs:[tempDither+8][si], ax
		mov	ax, {word} cs:[ditherMatrix+13]
		mov	{word} cs:[tempDither+12][si], ax
		xor	si, 2
		mov	al, cs:[ditherMatrix+3]
		mov	ah, cs:[ditherMatrix+0]
		mov	{word} cs:[tempDither][si], ax
		mov	al, cs:[ditherMatrix+7]
		mov	ah, cs:[ditherMatrix+4]
		mov	{word} cs:[tempDither+4][si], ax
		mov	al, cs:[ditherMatrix+11]
		mov	ah, cs:[ditherMatrix+8]
		mov	{word} cs:[tempDither+8][si], ax
		mov	al, cs:[ditherMatrix+15]
		mov	ah, cs:[ditherMatrix+12]
		mov	{word} cs:[tempDither+12][si], ax
		jmp	done	
		
SetTempDither	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawNOTRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a rectangle with draw mode MM_INVERT and all bits in the
		draw mask set

CALLED BY:	INTERNAL
		DrawSimpleRect
PASS:		dx - number of byte covered by rectangle - 1
		es:di - buffer address for first left:top of rectangle
		bp - number of lines to draw
RETURN:		nothing	
DESTROYED:	ax, bx, cx, dx, si, di, bp

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		jim	10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DrawNOTRect	proc		near
		push	ds
NMEM <		mov	ds, cs:[readSegment]				>
MEM  <		segmov	ds, es						>

		; see if we can do it in one byte

NMEM <		mov	si, cs:[modeInfo].VMI_scanSize ; optimization	>
		clr	bh
		tst	dx
		jz	oneByteWide	

		; calculate #bytes to write

		inc	dx			; number of bytes to draw

NMEM <		cmp	di, cs:[lastWinPtr]	; is it in the last line    >
NMEM <		jae	firstPartial		; check for complete line   >

lineLoop:
		mov	cx, dx			; setup count
notLoop:
		mov	bl, {byte} ds:[di]
		mov	bl, cs:NOTtable[bx]
		mov	{byte} es:[di], bl
		inc	di
		loop	notLoop			; to loop or not to loop...
		sub	di, dx			; restore scan pointer
		dec	bp			; fewer scans to do
		jz	done
NMEM <		NextScanBoth di,si		; adjust ptr to next scan line>
NMEM <		jc	lastWinLine					      >
MEM <		NextScan di			; adjust ptr to next scan line>
MEM <		segmov	ds, es			; make sure they match 	>
MEM <		tst	cs:[bm_scansNext]	;			>
MEM <		js	done						>
		jmp	lineLoop
done:
		pop	ds
		ret

		; it's only a byte wide.  Do it quickly.
oneByteWide:
		mov	cx, bp			; get line count in cd
oneLoop:
		mov	bl, {byte} ds:[di]
		mov	bl, cs:NOTtable[bx]
		mov	{byte} es:[di], bl
		dec	cx			; one less line to do
		jz	done
NMEM <		NextScanBoth di,si					>
MEM <		NextScan di						>
MEM <		segmov	ds, es			; make sure they match 	>
MEM <		tst	cs:[bm_scansNext]	;			>
MEM <		js	done						>
		jmp	oneLoop

ifndef	IS_MEM
		; first line is already an partial scan
firstPartial:
		clc
		call	SetNextWinSrc
		clc
		call	SetNextWin

		; the current line is no totally in the window, so take it slow
lastWinLine:
		cmp	dx, cs:[pixelsLeft]	; if doing less, do normal
		jb	lineLoop
		mov	cx, cs:[pixelsLeft]	; #pixels left in window
pixLoop1:
		mov	bl, {byte} ds:[di]
		mov	bl, cs:NOTtable[bx]
		mov	{byte} es:[di], bl
		inc	di
		loop	pixLoop1
		call	MidScanNextWinSrc	; goto next window
		call	MidScanNextWin		; goto next window
		mov	cx, dx			; setup remaining count
		sub	cx, cs:[pixelsLeft]
		jcxz	null1
pixLoop2:
		mov	bl, {byte} ds:[di]
		mov	bl, cs:NOTtable[bx]
		mov	{byte} es:[di], bl
		inc	di
		loop	pixLoop2
null1:
		dec	bp
		jz	done
		FirstWinScan			; set di to start of next
		jmp	lineLoop
endif

DrawNOTRect	endp
ForceRef	DrawNOTRect


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawSpecialRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a rectangle with a special draw mask or draw mode clipping
		left and right

CALLED BY:	INTERNAL
		DrawSimpleRect
PASS:		dx - number of words covered by rectangle - 1
		cx - pattern index
		es:di - buffer address for first left:top of rectangle
		bp - number of lines to draw
		si - low three bits of x position
RETURN:		nothing	
DESTROYED:	ax, bx, cx, dx, si, di, bp

PSEUDO CODE/STRATEGY:
	REGISTER USAGE:
		es:di	- points into frame buffer
		si	- offset into 8-byte mask buffer
		al	- color
		bh	- one bit set to test mask buffer		 
		bl	- starting value for bh

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		jim	10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DrawSpecialRect	proc		near

		push	ds	
NMEM <		mov	ds, cs:[readSegment]				>
MEM  <		segmov	ds, es						>

		; check the dither flag and do the right thing

		test	cs:[driverState], mask VS_DITHER
		LONG jnz	SpecialDitheredRect

		; setup ah to hold a bit flag to use in testing the mask
	
		mov	bl, 80h			; bit zero
		xchg	cx, si			; cx = low three bits of x pos
		and	cl, 7			
		shr	bl, cl			; ah = single bit tester
		mov	cx, si			; restore mask buffer index

		; load up the color that we're gonna use to fill

		mov	ah, cs:[currentColor]

		; check for one byte wide

		tst	dx
		jz	oneByteWide

		; calculate #bytes in the line, offset to next line

		inc	dx			; number of bytes

NMEM <		cmp	di, cs:[lastWinPtr]	; is it in the last line    >
NMEM <		LONG jae firstPartial		; check for complete line   >

lineLoop:
		push	di			; save pointer
		mov	cx, dx			; setup count
		mov	bh, bl			; reload tester
pixelLoop:
		test	cs:[maskBuffer][si], bh	; skip this pixel ?
		jz	pixelDone
		mov	al, ds:[di]		; get screen pixel
		call	cs:[modeRoutine]	; apply mix mode
		mov	es:[di], al		; store result
pixelDone:
		inc	di
		shr	bh, 1			; testing next pixel
		jc	reloadTester
haveTester:
		loop	pixelLoop
		pop	di			; restore scan pointer
		dec	bp			; fewer scans to do
		jz	done
		inc	si			; next scan line
		and	si, 0x7
NMEM <		NextScanBoth di			; adjust ptr to next scan line>
NMEM <		jc	lastWinLine					>
MEM <		NextScan di						>
MEM <		segmov	ds, es			; update source reg	>
MEM <		tst	cs:[bm_scansNext]	;			>
MEM <		jns	lineLoop					>
NMEM <		jmp	lineLoop					>
done:
		pop	ds
		ret

reloadTester:
		mov	bh, 80h
		jmp	haveTester

oneByteWide:
		mov	si, cx			; mask index in si
		mov	bh, bl			; reload tester
oneByteLoop:
		test	cs:[maskBuffer][si], bh	; skip this pixel ?
		jz	lineDone
		mov	al, ds:[di]		; get screen pixel
		call	cs:[modeRoutine]	; apply mix mode
		mov	es:[di], al		; store result
lineDone:
		dec	bp			; fewer scans to do
		jz	done
		inc	si			; next scan line
		and	si, 0x7
NMEM <		NextScanBoth di			; adjust ptr to next scan line>
MEM <		NextScan di			; adjust ptr to next scan line>
MEM <		segmov	ds, es			; reload source reg	>
MEM <		tst	cs:[bm_scansNext]	;			>
MEM <		js	done						>
		jmp	oneByteLoop

ifndef	IS_MEM
		; first line is already an partial scan
firstPartial:
		clc
		call	SetNextWin
		clc
		call	SetNextWinSrc

		; the current line is no totally in the window, so take it slow
lastWinLine:
		cmp	dx, cs:[pixelsLeft]	; if doing less, do normal
		LONG jb lineLoop
		mov	bh, bl
		mov	cx, cs:[pixelsLeft]	; #pixels left in window
pixLoop1:
		test	cs:[maskBuffer][si], bh	; skip this pixel ?
		jz	pixDone1
		mov	al, ds:[di]		; get screen pixel
		call	cs:[modeRoutine]	; apply mix mode
		mov	es:[di], al		; store result
pixDone1:
		inc	di
		shr	bh, 1			; testing next pixel
		jnc	nextPix1
		mov	bh, 80h
nextPix1:
		loop	pixLoop1
		call	MidScanNextWinSrc	; goto next window
		call	MidScanNextWin		; goto next window
		mov	cx, dx			; setup remaining count
		sub	cx, cs:[pixelsLeft]
		jcxz	null1
pixLoop2:
		test	cs:[maskBuffer][si], bh	; skip this pixel ?
		jz	pixDone2
		mov	al, ds:[di]		; get screen pixel
		call	cs:[modeRoutine]	; apply mix mode
		mov	es:[di], al		; store result
pixDone2:
		inc	di
		shr	bh, 1			; testing next pixel
		jnc	nextPix2
		mov	bh, 80h
nextPix2:
		loop	pixLoop2
null1:
		dec	bp
		LONG jz	done
		FirstWinScan			; set di to start of next
		inc	si			; next scan line
		and	si, 0x7
		jmp	lineLoop
endif
		
DrawSpecialRect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpecialDitheredRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a dithered rectangle, some random mix mode, w/draw mask

CALLED BY:	INTERNAL
		DrawSpecialRect
PASS:		dx - number of words covered by rectangle - 1
		cx - pattern index
		es:di - buffer address for first left:top of rectangle
		bp - number of lines to draw
		si - low three bits of x position
RETURN:		nothing	
DESTROYED:	ax, bx, cx, dx, si, di, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpecialDitheredRect proc	near

		; setup some stuff.  Get index to point at beginning of
		; ditherMatrix scan line (each 4 bytes), get scan size

		push	si
		call	SetTempDither		; setup tempDither matrix
		pop	si
		mov	bx, cx			; line offset in bx
		xchg	si, cx			; in si too.  xoffset in cx
		shl	bx, 1			; *4
		shl	bx, 1
		and	bx, 0x0c		; pointer into tempDither
		and	cx, 0x7			; need low three bits

		tst	dx
		jz	oneByteWide

		; calculate #bytes in the middle of the line and
		; offset to next line

		inc	dx			; total #bytes in line

NMEM <		cmp	di, cs:[lastWinPtr]	; is it in the last line    >
NMEM <		jae	firstPartial		; check for complete line   >

lineLoop:
		call	BlastDitheredMaskedScan	; do a scan line
		dec	bp			; fewer scans to do
		jz	done
		add	bl, 4			; onto next scan
		and	bl, 0xc			; limit it to 16 bytes
		inc	si			; next mask scan
		and	si, 7
NMEM <		NextScanBoth di			; adjust ptr to next scan >
NMEM <		jc	lastWinLine		; oops, on last line in wind.>
MEM <		NextScan di			; adjust ptr to next scan >
MEM <		segmov	ds, es			; make sure they match 	>
MEM <		tst	cs:[bm_scansNext]	;			>
MEM <		jns	lineLoop					>
NMEM <		jmp	lineLoop					>
done:
		pop	ds			; pushed in DrawSpecialRect
		ret

		; it's only a byte wide.  Do it quickly.
oneByteWide:
		mov	ch, 80h			; bit zero
		shr	ch, cl			; ch = single bit tester

oneByteLoop:
		test	ch, cs:[maskBuffer][si]
		jz	donePix

		mov	al, cs:[tempDither][bx]
		call	cs:[modeRoutine]
		mov	es:[di], al		; store the color
donePix:
		dec	bp			; one less line to do
		jz	done
		add	bl, 4
		and	bl, 0xc
		inc	si
		and	si, 7
NMEM <		NextScanBoth di			; always enuf room todo 1 pix >
MEM <		NextScan di			; always enuf room todo 1 pix >
MEM <		segmov	ds, es			; make sure they match 	>
MEM <		tst	cs:[bm_scansNext]	;			>
MEM <		js	done						>
		jmp	oneByteLoop

ifndef	IS_MEM
		; first line is already an partial scan
firstPartial:
		clc
		call	SetNextWinSrc
		clc
		call	SetNextWin

		; the current line is no totally in the window, so take it slow
lastWinLine:
		cmp	dx, cs:[pixelsLeft]	; if doing less, do normal
		jb	lineLoop
		push	cx
		push	dx
		mov	dx, cs:[pixelsLeft]
		call	BlastDitheredMaskedScan
		call	MidScanNextWinSrc	; goto next window
		call	MidScanNextWin		; goto next window

		pop	dx
		push	dx
		sub	dx, cs:[pixelsLeft]

		add	cx, cs:[pixelsLeft]
		and	cx, 7

		tst	dx
		jz	null1

		call	BlastDitheredMaskedScan
null1:
		pop	dx
		pop	cx
		dec	bp
		jz	done
		add	bl, 4			; onto next scan
		and	bl, 0xc			; limit it to 16 bytes
		inc	si
		and	si, 7			; limit to size of mask buffer
		FirstWinScan			; set di to start of next
		jmp	lineLoop
endif		
SpecialDitheredRect endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BlastDitheredMaskedScan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a scan line, dithered, with a draw mask

CALLED BY:	INTERNAL
		SpecialDitheredRect
PASS:		bx	- offset into tempDither of current scan line
		dx	- #pixels to write
		cl	- low three bits of left side x position
		es:di	- points at starting pixel
		tempDither	- already setup (entries rotated in X so
				  that the first element in each scan is
				  the Nth element in the ditherMatrix scan
				  where N=(left side of rect) AND 7
RETURN:		
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	10/22/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BlastDitheredMaskedScan		proc	near
		uses	bx, cx
		.enter

		; setup ch to hold a bit flag to use in testing the mask
	
		mov	ch, 80h			; bit zero
		shr	ch, cl			; ah = single bit tester

		mov	ax, {word} cs:[tempDither][bx]
		mov	bx, {word} cs:[tempDither][bx+2]

		mov	cl, al			; al gets trashed all the time
		push	dx
		jmp	startLine
pixLoop:
		xchg	ah, cl
		call	WriteSpecialPixel
		xchg	ah, cl

		call	WriteSpecialPixel

		xchg	ah, bl
		call	WriteSpecialPixel
		xchg	ah, bl

		xchg	ah, bh
		call	WriteSpecialPixel
		xchg	ah, bh
startLine:
		sub	dx, 4
		jns	pixLoop

		; down to less than 4 pixels on the scan line, do one at a time

		add	dx, 4
		jz	doneLine
		xchg	ah, cl
		call	WriteSpecialPixel
		xchg	ah, cl

		dec	dx
		jz	doneLine
		call	WriteSpecialPixel

		dec	dx
		jz	doneLine
		xchg	ah, bl
		call	WriteSpecialPixel
		xchg	ah, bl
doneLine:
		pop	dx
		sub	di, dx			; restore line pointer

		.leave
		ret

BlastDitheredMaskedScan		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteSpecialPixel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lots of stuff to do, mask, dither, mix a pixel

CALLED BY:	BlastDitheredMaskedScan
PASS:		ch	- current mask bit
		ah	- color to use
		es:di	- frame buffer pointer
		si	- mask buffer index
RETURN:		ch	- advanced to next pixel
		di	- points at next pixel
DESTROYED:	al

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	10/22/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteSpecialPixel proc	near
		test	ch, cs:[maskBuffer][si]
		jz	donePix
		mov	al, ds:[di]
		call	cs:[modeRoutine]
		mov	es:[di], al
donePix:
		inc	di
		shr	ch, 1
		jc	reloadMask
		ret
reloadMask:
		mov	ch, 0x80
		ret
WriteSpecialPixel endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MixModeRoutines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Various stub routines to implement mix modes

CALLED BY:	INTERNAL
		various low-level drawing routines
PASS:		ah - color
		al - screen
RETURN:		al - destination (byte to write out)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		jim	10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ModeRoutines	proc	near
		ForceRef ModeRoutines

ModeCLEAR	label near	
		clr	al
ModeNOP		label near
		ret
ModeCOPY	label  near	
		mov	al, ah
		ret
ModeAND		label  near		
		and	al, ah
		ret
ModeINVERT	label  near	
		xchg	bx, ax
		clr	bh
		mov	bl, cs:NOTtable[bx] 
		xchg	bx, ax
		ret
ModeXOR		label  near	
		xor	al, ah
		ret
ModeSET		label  near	
		mov	al, 0xff
		ret
ModeOR		label  near	
		or	al, ah
		ret
ModeRoutines	endp




		; for 8-bit devices, we want to re-define the NOT operation,
		; so that we achieve the same result as we do in monochrome
		; and 4-bit devices.   This table is a one-to-one mapping
		; from one index to another.
NOTtable	label	byte
		byte	0x0f, 0x0e, 0x0d, 0x0c, 0x0b, 0x0a, 0x09, 0x08
		byte	0x07, 0x06, 0x05, 0x04, 0x03, 0x02, 0x01, 0x00
		byte	0x1f, 0x1e, 0x1d, 0x1c, 0x1b, 0x1a, 0x19, 0x18
		byte	0x17, 0x16, 0x15, 0x14, 0x13, 0x12, 0x11, 0x10
		byte	0x27, 0x26, 0x25, 0x24, 0x23, 0x22, 0x21, 0x20
		byte	0xff, 0xfe, 0xfd, 0xfc, 0xfb, 0xfa, 0xf9, 0xf8
		byte	0xf7, 0xf6, 0xf5, 0xf4, 0xf3, 0xf2, 0xf1, 0xf0
		byte	0xef, 0xee, 0xed, 0xec, 0xeb, 0xea, 0xe9, 0xe8
		byte	0xe7, 0xe6, 0xe5, 0xe4, 0xe3, 0xe2, 0xe1, 0xe0
		byte	0xdf, 0xde, 0xdd, 0xdc, 0xdb, 0xda, 0xd9, 0xd8
		byte	0xd7, 0xd6, 0xd5, 0xd4, 0xd3, 0xd2, 0xd1, 0xd0
		byte	0xcf, 0xce, 0xcd, 0xcc, 0xcb, 0xca, 0xc9, 0xc8
		byte	0xc7, 0xc6, 0xc5, 0xc4, 0xc3, 0xc2, 0xc1, 0xc0
		byte	0xbf, 0xbe, 0xbd, 0xbc, 0xbb, 0xba, 0xb9, 0xb8
		byte	0xb7, 0xb6, 0xb5, 0xb4, 0xb3, 0xb2, 0xb1, 0xb0
		byte	0xaf, 0xae, 0xad, 0xac, 0xab, 0xaa, 0xa9, 0xa8
		byte	0xa7, 0xa6, 0xa5, 0xa4, 0xa3, 0xa2, 0xa1, 0xa0
		byte	0x9f, 0x9e, 0x9d, 0x9c, 0x9b, 0x9a, 0x99, 0x98
		byte	0x97, 0x96, 0x95, 0x94, 0x93, 0x92, 0x91, 0x90
		byte	0x8f, 0x8e, 0x8d, 0x8c, 0x8b, 0x8a, 0x89, 0x88
		byte	0x87, 0x86, 0x85, 0x84, 0x83, 0x82, 0x81, 0x80
		byte	0x7f, 0x7e, 0x7d, 0x7c, 0x7b, 0x7a, 0x79, 0x78
		byte	0x77, 0x76, 0x75, 0x74, 0x73, 0x72, 0x71, 0x70
		byte	0x6f, 0x6e, 0x6d, 0x6c, 0x6b, 0x6a, 0x69, 0x68
		byte	0x67, 0x66, 0x65, 0x64, 0x63, 0x62, 0x61, 0x60
		byte	0x5f, 0x5e, 0x5d, 0x5c, 0x5b, 0x5a, 0x59, 0x58
		byte	0x57, 0x56, 0x55, 0x54, 0x53, 0x52, 0x51, 0x50
		byte	0x4f, 0x4e, 0x4d, 0x4c, 0x4b, 0x4a, 0x49, 0x48
		byte	0x47, 0x46, 0x45, 0x44, 0x43, 0x42, 0x41, 0x40
		byte	0x3f, 0x3e, 0x3d, 0x3c, 0x3b, 0x3a, 0x39, 0x38
		byte	0x37, 0x36, 0x35, 0x34, 0x33, 0x32, 0x31, 0x30
		byte	0x2f, 0x2e, 0x2d, 0x2c, 0x2b, 0x2a, 0x29, 0x28
