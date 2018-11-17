COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		VidMem video driver
FILE:		cmykColorRaster.asm

AUTHOR:		Jim DeFrisco, Mar  4, 1992

ROUTINES:
	Name			Description
	----			-----------
    INT PutColor24Mask		Write a 24-bit/pixel scan line
    INT PutColor24		Write a 24-bit/pixel scan line
    INT WriteClr24Byte		Build and write a 24-bit/pixel byte to all
				4 CMYK planes
    INT PutColor8Mask		Write a 8-bit/pixel scan line
    INT PutColor8		Write a 8-bit/pixel scan line
    INT WriteClr8Byte		Build and write a 8-bit/pixel byte to all 4
				CMYK planes
    INT PutColor4Mask		Write a 4-bit/pixel scan line
    INT PutColor4		Write a 4-bit/pixel scan line
    INT WriteClr4Byte		Build and write a 4-bit/pixel byte to all 4
				CMYK planes
    INT PickDitherBits		Given a bit mask and the dither matrices
				setup, set the appropriate bits in the
				output plane bytes
    INT SetDitherIndex		Setup the "current" dither, given a color
				index
    INT SetDitherRGB		Set new bitmap color, pass it an RGB value
				(used for 24-bit)
    INT CalcCacheEntry		Calculate the dither offsets for the cache
				entry
    INT CopyShiftCyan		Copy a cyan/magenta dither matrix and shift
				it
    INT CopyShiftBlack		Copy and shift a black dither matrix

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	3/ 4/92		Initial revision


DESCRIPTION:
		Color bitmap routines for CMYK module
		

	$Id: cmykColorRaster.asm,v 1.1 97/04/18 11:43:05 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VidSegment	ClrBitmap

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PutColor24Mask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a 24-bit/pixel scan line

CALLED BY:	PutBitsSimple
PASS:		ds:si	- pointer into bitmap data
		es:di	- pointer into frame buffer
			
		plus	- all kinds of nice things setup by PutLineSetup
RETURN:		nothing
DESTROYED:	all

PSEUDO CODE/STRATEGY:
		we have a bitmap mask, and a user-specified draw mask
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
		register usage:
			ds:si	- points to bitmap picture data
			ds:bx	- points to bitmap mask data
			es:di	- points into frame buffer
			   ax	- scratch registerr
			   ch	- mask for bit that we are working on
			   cl	- #bit shifts for mask
			   dh	- mask shift out bits
			   bp	- #bytes to do

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	3/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PutColor24Mask	proc	far
		uses	bp
		.enter

		; intialize some of our dither stuff

		mov	cs:[colorWriteByte], offset WriteClr24Byte
		InitDitherIndex	<ss:[yellowBase]>

		; since there is a mask, compute where it is...

		mov	bx, si				; ds:bx -> picture data
		sub	bx, ss:[bmMaskSize]		; ds:bx -> mask data

		; next, calculate the offsets into the source and destination
		; scan lines.

		mov	cl, 3				; dividing by 8 for msk
		mov	ax, ss:[bmLeft]			; get left side
		mov	bp, ax				; dx = #bits into image
		sub	bp, ss:[d_x1]			; get left bm coord
		shr	ax, cl				; ax = #bytes to left
		add	di, ax				; es:di -> left byte
		add	si, bp				; ds:si -> left bm byte
		shl	bp, 1				;  3 bytes/pixel
		add	si, bp
		shr	bp, 1				; divide by 8 for mask
		shr	bp, 1				; shift over for mask
		shr	bp, 1
		shr	bp, 1				; continue divide for 
		add	bx, bp				;  index into mask
		mov	bp, ss:[bmRight]		; need #bytes wide
		shr	bp, cl				; bp = #bytes to right
		sub	bp, ax				; bp=#bytes - 1
		jmp	colorMaskCommon

		.leave	.UNREACHED
		
PutColor24Mask	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PutColor24
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a 24-bit/pixel scan line

CALLED BY:	PutBitsSimple
PASS:		ds:si	- pointer into bitmap data
		es:di	- pointer into frame buffer
			
		plus	- all kinds of nice things setup by PutLineSetup
RETURN:		nothing
DESTROYED:	all

PSEUDO CODE/STRATEGY:
		we don't have a bitmap mask, just a user-specified draw mask
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
		register usage:
			ds:si	- points to bitmap picture data
			es:di	- points into frame buffer
			   ax	- scratch registerr
			   ch	- mask for bit that we are working on
			   bx	- #bytes to do

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	3/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PutColor24	proc	far
		.enter

		; intialize some of our dither stuff

		mov	cs:[colorWriteByte], offset WriteClr24Byte
		InitDitherIndex	<ss:[yellowBase]>

		; next, calculate the offsets into the source and destination
		; scan lines.

		mov	cl, 3				; dividing by 8 for msk
		mov	ax, ss:[bmLeft]			; get left side
		mov	bp, ax				; dx = #bits into image
		sub	bp, ss:[d_x1]			; get left bm coord
		shr	ax, cl				; ax = #bytes to left
		add	di, ax				; es:di -> left byte
		add	si, bp				; ds:si -> left bm byte
		shl	bp, 1				;  3 bytes/pixel
		add	si, bp
		mov	bx, ss:[bmRight]		; need #bytes wide
		shr	bx, cl				; bp = #bytes to right
		sub	bx, ax				; bp=#bytes - 1

		GOTO	colorCommon
		
		.leave	.UNREACHED
		
PutColor24	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteClr24Byte
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build and write a 24-bit/pixel byte to all 4 CMYK planes

CALLED BY:	INTERNAL
		PutColor8Mask, PutColor8
PASS:		al		- mask to use
		ch		- bit mask for bit to start on
				  (pass 80h to build the whole byte)
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		for each bit that is set in the mask:
		    setup the dither matrices for that color;
		    set the appropriate pixels in the output bytes;
		    write the byte;
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	3/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WriteClr24Byte	proc	near
		
		; we need some room to work, so save a few values that we
		; won't be using here.

		push	bx, bp		; save mask ptr, byte count
		xchg	ch, dh			; dh = single bit mask
		push	cx			; save shift, xtra mask bits
		push	di			; need another register

		; ds:si	- bitmap data
		;    dh	- single bit mask
		;    bl - yellow;   bh - cyan;   cl - magenta;  ch - black
		;    bp - copy of byte mask 

		mov	bp, ax			; save copy
		clr	cx			; init color bytes
		clr	bx

		; start processing picture bytes
pixelLoop:
		lodsw				; get next data byte
		mov	di, ax
		lodsb
		mov	ah, al			; RGB in cl,ch,ah
		xchg	bp, cx			; get mask in cl
		mov	ch, cl			; make copy of byte mask
		and	ch, dh			; see if need to do this pixel
		xchg	bp, cx			; restore magenta/black
		jz	nextPixel
		xchg	di, cx
		call	SetDitherRGB		; make sure color is OK
		xchg	di, cx
		call	PickDitherBits		; set the appropriate bits
nextPixel:
		shr	dh, 1
		jnc	pixelLoop
		
		; done with byte.  Store flag for next time and write byte

		pop	di			; restore dest ptr
		mov	ax, bp			; al = byte mask
		mov	ah, al
		mov	al, bl			; do yellow
		mov	bp, di			; save di
		call	ss:[modeRoutine]
		mov	al, bh			; do cyan
		mov	bx, ss:[bm_bpMask]	; get offset to next plane
		add	di, bx
		call	ss:[modeRoutine]
		add	di, bx
		mov	al, cl			; do magenta
		call	ss:[modeRoutine]
		add	di, bx
		mov	al, ch			; do black
		call	ss:[modeRoutine]
		mov	di, bp			; restore original ptr
		inc	di
		pop	cx
		xchg	ch, dh
		BumpDitherIndex			; set indices for next byte
		pop	bx, bp
		ret

WriteClr24Byte	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PutColor8Mask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a 8-bit/pixel scan line

CALLED BY:	PutBitsSimple
PASS:		ds:si	- pointer into bitmap data
		es:di	- pointer into frame buffer
			
		plus	- all kinds of nice things setup by PutLineSetup
RETURN:		nothing
DESTROYED:	all

PSEUDO CODE/STRATEGY:
		we have a bitmap mask, and a user-specified draw mask
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
		register usage:
			ds:si	- points to bitmap picture data
			ds:bx	- points to bitmap mask data
			es:di	- points into frame buffer
			   ax	- scratch registerr
			   ch	- mask for bit that we are working on
			   cl	- #bit shifts for mask
			   dh	- mask shift out bits
			   bp	- #bytes to do

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	3/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PutColor8Mask	proc	far
		uses	bp
		.enter

		; intialize some of our dither stuff

		mov	cs:[colorWriteByte], offset WriteClr8Byte
		InitDitherIndex	<ss:[yellowBase]>

		; since there is a mask, compute where it is...

		mov	bx, si				; ds:bx -> picture data
		sub	bx, ss:[bmMaskSize]		; ds:bx -> mask data

		; next, calculate the offsets into the source and destination
		; scan lines.

		mov	cl, 3				; dividing by 8 for msk
		mov	ax, ss:[bmLeft]			; get left side
		mov	bp, ax				; dx = #bits into image
		sub	bp, ss:[d_x1]			; get left bm coord
		shr	ax, cl				; ax = #bytes to left
		add	di, ax				; es:di -> left byte
		add	si, bp				; ds:si -> left bm byte
		shr	bp, 1				; shift over for mask
		shr	bp, 1
		shr	bp, 1				; continue divide for 
		add	bx, bp				;  index into mask
		mov	bp, ss:[bmRight]		; need #bytes wide
		shr	bp, cl				; bp = #bytes to right
		sub	bp, ax				; bp=#bytes - 1

		jmp	colorMaskCommon

		.leave	.UNREACHED
		
PutColor8Mask	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PutColor8
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a 8-bit/pixel scan line

CALLED BY:	PutBitsSimple
PASS:		ds:si	- pointer into bitmap data
		es:di	- pointer into frame buffer
			
		plus	- all kinds of nice things setup by PutLineSetup
RETURN:		nothing
DESTROYED:	all

PSEUDO CODE/STRATEGY:
		we don't have a bitmap mask, but we have can a user-specified 
		draw mask
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
		register usage:
			ds:si	- points to bitmap picture data
			es:di	- points into frame buffer
			   ax	- scratch registerr
			   ch	- mask for bit that we are working on
			   bx	- #bytes to do

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	3/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PutColor8	proc	far
		.enter

		; intialize some of our dither stuff

		mov	cs:[colorWriteByte], offset WriteClr8Byte
		InitDitherIndex	<ss:[yellowBase]>

		; next, calculate the offsets into the source and destination
		; scan lines.

		mov	cl, 3				; dividing by 8 for msk
		mov	ax, ss:[bmLeft]			; get left side
		mov	bp, ax
		sub	bp, ss:[d_x1]			; get left bm coord
		shr	ax, cl				; ax = #bytes to left
		add	di, ax				; es:di -> left byte
		add	si, bp				; ds:si -> left bm byte
		mov	bx, ss:[bmRight]		; need #bytes wide
		shr	bx, cl				; bp = #bytes to right
		sub	bx, ax				; bp=#bytes - 1

		GOTO	colorCommon
		.leave	.UNREACHED
		
PutColor8	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteClr8Byte
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build and write a 8-bit/pixel byte to all 4 CMYK planes

CALLED BY:	INTERNAL
		PutColor8Mask, PutColor8
PASS:		al		- mask to use
		ch		- bit mask for bit to start on
				  (pass 80h to build the whole byte)
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		for each bit that is set in the mask:
		    setup the dither matrices for that color;
		    set the appropriate pixels in the output bytes;
		    write the byte;
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	3/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WriteClr8Byte	proc	near
		
		; we need some room to work, so save a few values that we
		; won't be using here.

		push	bx, bp			; save mask ptr, byte count
		xchg	ch, dh			; dh = single bit mask
		push	cx			; save shift, xtra mask bits

		; ds:si	- bitmap data
		;    dh	- single bit mask
		;    bl - yellow;   bh - cyan;   cl - magenta;  ch - black
		;    bp - copy of byte mask 

		mov	bp, ax			; save copy
		clr	cx			; init color bytes
		clr	bx

		; start processing picture bytes
pixelLoop:
		lodsb				; get next data byte
		xchg	bp, cx			; get mask in cl
		mov	ch, cl			; make copy of byte mask
		and	ch, dh			; see if need to do this pixel
		xchg	bp, cx			; restore magenta/black
		jz	nextPixel
		call	SetDitherIndex		; make sure color is OK
		call	PickDitherBits		; set the appropriate bits
nextPixel:
		shr	dh, 1
		jnc	pixelLoop
		
		; done with byte.  Store flag for next time and write byte

		mov	ax, bp			; al = byte mask
		mov	ah, al
		mov	al, bl			; do yellow
		mov	bp, di			; save di
		call	ss:[modeRoutine]
		mov	al, bh			; do cyan
		mov	bx, ss:[bm_bpMask]	; get offset to next plane
		add	di, bx
		call	ss:[modeRoutine]
		add	di, bx
		mov	al, cl			; do magenta
		call	ss:[modeRoutine]
		add	di, bx
		mov	al, ch			; do black
		call	ss:[modeRoutine]
		mov	di, bp			; restore original ptr
		inc	di
		pop	cx
		xchg	ch, dh
		BumpDitherIndex			; set indices for next byte
		pop	bx, bp
		ret

WriteClr8Byte	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PutColor4Mask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a 4-bit/pixel scan line

CALLED BY:	PutBitsSimple
PASS:		ds:si	- pointer into bitmap data
		es:di	- pointer into frame buffer
			
		plus	- all kinds of nice things setup by PutLineSetup
RETURN:		nothing
DESTROYED:	all

PSEUDO CODE/STRATEGY:
		we have a bitmap mask, and a user-specified draw mask
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
		register usage:
			ds:si	- points to bitmap picture data
			ds:bx	- points to bitmap mask data
			es:di	- points into frame buffer
			   ax	- scratch registerr
			   ch	- mask for bit that we are working on
			   cl	- #bit shifts for mask
			   dh	- mask shift out bits
			   dl	- picture shift out bits
			   bp	- #bytes to do

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	3/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PutColor4Mask	proc	far
		uses	bp
		.enter

		; intialize some of our dither stuff

		mov	cs:[colorWriteByte], offset WriteClr4Byte
		InitDitherIndex	<ss:[yellowBase]>

		; since there is a mask, compute where it is...

		mov	bx, si				; ds:bx -> picture data
		sub	bx, ss:[bmMaskSize]		; ds:bx -> mask data

		; next, calculate the offsets into the source and destination
		; scan lines.

		mov	cl, 3				; dividing by 8 for msk
		mov	ax, ss:[bmLeft]			; get left side
		mov	bp, ax
		sub	bp, ss:[d_x1]			; get left bm coord
		shr	ax, cl				; ax = #bytes to left
		add	di, ax				; es:di -> left byte
		mov	cs:[oddOrEven], READ4_LOAD_NEW_PIXEL
		mov	dx, bp				; save low bit
		shr	bp, 1				; dx = #bytes into bm
		add	si, bp				; ds:si -> left bm byte
		test	dx, 1				; if low bit is set...
		mov	dl, 0
		jz	oddEvenSettled
		mov	cx, ax				; save x value
		lodsb					; get first data value
		and	al, 0xf				; need 2nd pixel
		mov	dl, al				; store it
		mov	cs:[oddOrEven], READ4_HAVE_ONE_PIXEL
		mov	ax, cx				; restore x value
		mov	cl, 3				; reload shift count
oddEvenSettled:
		shr	bp, 1
		shr	bp, 1				; continue divide for 
		add	bx, bp				;  index into mask
		mov	bp, ss:[bmRight]		; need #bytes wide
		shr	bp, cl				; bp = #bytes to right
		sub	bp, ax				; bp=#bytes - 1

		; figure mask for starting pixel
colorMaskCommon	label	far
		mov	cl, ss:[bmLeft].low
		and	cl, 7
		mov	ch, 80h				; shift bit into right
		shr	ch, cl				;  position

		; check preload bit, and preload mask data if needed

		clr	dh
		mov	cl, ss:[bmShift]		; load shift amount
		tst	ss:[bmPreload]			; if we need to preload
		jns	preloadDone
		mov	al, ds:[bx-1]			; do mask byte
		clr	ah
		ror	ax, cl
		mov	dh, ah				; save shift out bits

		; LEFT SIDE
		; do mask first, then get picture data
preloadDone:
		mov	al, ds:[bx]			; do mask from bitmap
		inc	bx
		clr	ah
		ror	ax, cl
		or	al, dh				; combine from preload
		mov	dh, ah				; save new shift out 
		and	al, ss:[bmLMask]		; do mask thing
		and	al, ss:[lineMask]			; combine user mask

		; see if we're doing a narrow band.  If so, combine left and
		; right sides to do the single byte

		tst	bp				; if zero, only 1 byte
		jz	narrowBM			;  yep, do it small
		call	cs:[colorWriteByte]
		
		; MIDDLE BYTES
		; check if we need to do any first
		
		dec	bp
		jz	doRightSide
midLoop:
		mov	al, ds:[bx]			; next mask byte
		inc	bx
		clr	ah
		ror	ax, cl
		or	al, dh
		and	al, ss:[lineMask]
		mov	dh, ah
		mov	ch, 80h				; start at left pixel 
		call	cs:[colorWriteByte]
		dec	bp
		jnz	midLoop

		; RIGHT SIDE
doRightSide:
		mov	al, ds:[bx]			; next mask byte
		inc	bx
		clr	ah
		ror	ax, cl
		or	al, dh
		and	al, ss:[lineMask]
		and	al, ss:[bmRMask]
		mov	dh, ah
		mov	ch, 80h				; start at left pixel 
doLastByte:
		call	cs:[colorWriteByte]
		
		.leave
		ret

		; bitmap is only a byte wide.  Combine left/right masks
narrowBM:
		and	al, ss:[bmRMask]
		jmp	doLastByte
		
PutColor4Mask	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PutColor4
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a 4-bit/pixel scan line

CALLED BY:	PutBitsSimple
PASS:		ds:si	- pointer into bitmap data
		es:di	- pointer into frame buffer
			
		plus	- all kinds of nice things setup by PutLineSetup
RETURN:		nothing
DESTROYED:	all

PSEUDO CODE/STRATEGY:
		we can have a user-specified draw mask
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
		register usage:
			ds:si	- points to bitmap picture data
			es:di	- points into frame buffer
			   ax	- scratch registerr
			   ch	- mask for bit that we are working on
			   dl	- picture shift out bits
			   cx	- #bytes to do

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	3/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PutColor4	proc	far
		.enter

		; intialize some of our dither stuff

		mov	cs:[colorWriteByte], offset WriteClr4Byte
		InitDitherIndex	<ss:[yellowBase]>

		; calculate the offsets into the source and destination
		; scan lines.

		mov	cl, 3				; dividing by 8 for msk
		mov	ax, ss:[bmLeft]			; get left side
		mov	bx, ax				; bx = #bits into image
		sub	bx, ss:[d_x1]			; get left bm coord
		shr	ax, cl				; ax = #bytes to left
		add	di, ax				; es:di -> left byte
		mov	cs:[oddOrEven], READ4_LOAD_NEW_PIXEL
		mov	dx, bx				; save low bit
		shr	bx, 1				; bx = #bytes into bm
		add	si, bx				; ds:si -> left bm byte
		test	dx, 1				; if low bit is set...
		mov	dl, 0
		jz	oddEvenSettled
		mov	cx, ax				; save x1 value
		lodsb					; get first data value
		and	al, 0xf				; need 2nd pixel
		mov	dl, al				; store it
		mov	cs:[oddOrEven], READ4_HAVE_ONE_PIXEL
		mov	ax, cx
		mov	cl, 3				; reload shift count
oddEvenSettled:
		mov	bx, ss:[bmRight]		; need #bytes wide
		shr	bx, cl				; bx = #bytes to right
		sub	bx, ax				; bx=#bytes - 1

		; figure mask for starting pixel
colorCommon	label	far
		mov	cl, ss:[bmLeft].low
		and	cl, 7
		mov	ch, 80h				; shift bit into right
		shr	ch, cl				;  position

		; LEFT SIDE
		; no mask, just get picture data

		mov	al, ss:[bmLMask]		; do mask thing
		and	al, ss:[lineMask]		; combine user mask

		; see if we're doing a narrow band.  If so, combine left and
		; right sides to do the single byte

		tst	bx
		jz	narrowBM			;  yep, do it small
		call	cs:[colorWriteByte]
		
		; MIDDLE BYTES
		; check if we need to do any first
		
		dec	bx
		jz	doRightSide
midLoop:
		mov	al, ss:[lineMask]
		mov	ch, 80h				; start at left pixel 
		call	cs:[colorWriteByte]
		dec	bx
		jnz	midLoop

		; RIGHT SIDE
doRightSide:
		mov	al, ss:[lineMask]
		and	al, ss:[bmRMask]
		mov	ch, 80h				; start at left pixel 
doLastByte:
		call	cs:[colorWriteByte]
		
		.leave
		ret

		; bitmap is only a byte wide.  Combine left/right masks
narrowBM:
		and	al, ss:[bmRMask]
		jmp	doLastByte
		
PutColor4	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteClr4Byte
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build and write a 4-bit/pixel byte to all 4 CMYK planes

CALLED BY:	INTERNAL
		PutColor4Mask, PutColor4
PASS:		al		- mask to use
		ch		- bit mask for bit to start on
				  (pass 80h to build the whole byte)
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		for each bit that is set in the mask:
		    setup the dither matrices for that color;
		    set the appropriate pixels in the output bytes;
		    write the byte;
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	3/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

		; one of the following is stored below
READ4_LOAD_NEW_PIXEL equ 0xf9	; opcode for stc
READ4_HAVE_ONE_PIXEL equ 0xf8	; opcode for clc

WriteClr4Byte	proc	near
		
		; we need some room to work, so save a few values that we
		; won't be using here.

		push	bx, bp			; save mask ptr, byte count
		xchg	ch, dh			; dh = single bit mask
		push	cx			; save shift, xtra mask bits

		; ds:si	- bitmap data
		;    dh	- single bit mask
		;    dl - xtra data pixel
		;    bl - yellow;   bh - cyan;   cl - magenta;  ch - black
		;    bp - copy of byte mask 

		mov	bp, ax			; save copy
		clr	cx			; init color bytes
		clr	bx

		; this jump is modified depending on if we have a pixel loaded
		; in dl already or if we need to load more from the bitmap.

oddOrEven	equ (this byte)
		stc				; alternates between set and
		jc	loadMoreData		;  clear
doStoredPixel:
		mov	al, dl			; set color dithers
		xchg	bp, cx			; get mask in cl
		mov	ch, cl			; make copy of byte mask
		and	ch, dh			; see if need to do this pixel
		xchg	bp, cx			; restore magenta/black
		jz	nextPixelOdd
		call	SetDitherIndex		; load up dither if needed
		call	PickDitherBits
nextPixelOdd:
		shr	dh, 1			; onto next pixel
		LONG jc	finishedLoad		;  if we hit the end...
loadMoreData:
		lodsb				; get next data byte
		mov	ah, al			; make it two pixels
		and	ah, 0xf			; isolate right pixel
		shr	al, 1			; shift down left pixel
		shr	al, 1
		shr	al, 1
		shr	al, 1
		mov	dl, ah			; save right pixel for next...
		xchg	bp, cx			; get mask in cl
		mov	ch, cl			; make copy of byte mask
		and	ch, dh			; see if need to do this pixel
		xchg	bp, cx			; restore magenta/black
		jz	nextPixelEven
		call	SetDitherIndex		; make sure color is OK
		call	PickDitherBits		; set the appropriate bits
nextPixelEven:
		shr	dh, 1
		jnc	doStoredPixel
		
		; done with byte.  Store flag for next time and write byte

		mov	cs:[oddOrEven], READ4_HAVE_ONE_PIXEL
writeBytes:
		mov	ax, bp			; al = byte mask
		mov	ah, al
		mov	al, bl			; do yellow
		mov	bp, di			; save di
		call	ss:[modeRoutine]
		mov	al, bh			; do cyan
		mov	bx, ss:[bm_bpMask]	; get offset to next plane
		add	di, bx
		call	ss:[modeRoutine]
		add	di, bx
		mov	al, cl			; do magenta
		call	ss:[modeRoutine]
		add	di, bx
		mov	al, ch			; do black
		call	ss:[modeRoutine]
		mov	di, bp			; restore original ptr
		inc	di
		pop	cx
		xchg	ch, dh
		BumpDitherIndex			; set indices for next byte
		pop	bx, bp
		ret

		; done with this pixel.  Set flag for next entry and write..
finishedLoad:
		mov	cs:[oddOrEven], READ4_LOAD_NEW_PIXEL
		jmp	writeBytes
WriteClr4Byte	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PickDitherBits
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a bit mask and the dither matrices setup, set
		the appropriate bits in the output plane bytes

CALLED BY:	WriteClr4Byte
PASS:		current color setup up (for dithers)
		dh	- one bit set for pixel we're doing
		bl,bh	- yellow,cyan bytes
		cl,ch	- magenta,black bytes
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	3/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PickDitherBits	proc	near
		
curYellow	equ (this word) + 2
		mov	al, cs:[1234h]	; grab yellow dither byte
		and	al, dh		; isolate bit
		or	bl, al		; accumulate yellow bits

curCyan		equ (this word) + 2
		mov	al, cs:[1234h]	; grab cyan dither byte
		and	al, dh
		or	bh, al

curMagenta	equ (this word) + 2
		mov	al, cs:[1234h]	; grab magenta dither byte
		and	al, dh
		or	cl, al

curBlack	equ (this word) + 2
		mov	al, cs:[1234h]	; grab black dither byte
		and	al, dh
		or	ch, al

		ret
PickDitherBits	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModeRoutines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Routines to combine pixel data with screen content

CALLED BY:	INTERNAL
		WriteClr4Byte, WriteClr8Byte, WriteClr24Byte
PASS:		es:[di]		- points at frame buffer byte
		al		- data to store
		ah		- mask to use

RETURN:		nothing
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	3/ 4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CMYKCOPY	label	near
		and	al, ah			; isolate bits
		not	ah
		and	es:[di], ah
		not	ah
		or	es:[di], al
CMYKNOP		label	near
		retn

CMYKCLEAR	label 	near	
		mov	al, ah
		and	al, byte ptr ss:[resetColor]
		not	ah
		and	es:[di], ah
		not	ah
		or	es:[di], al
		retn
CMYKAND		label	near
		and	al, ah
		not	ah
		or	al, ah
		not	ah
		and	es:[di], al
		retn
CMYKINV		label	near
		xor	es:[di], ah
		retn
CMYKXOR		label	near
		and	al, ah
		xor	es:[di], al
		retn
CMYKSET		label	near
		not	ah	
		and	es:[di], ah	
		not	ah	
		and	al, byte ptr ss:[setColor]
		or	es:[di], al
		retn
CMYKOR		label	near		; screenv(data^mask^pattern) 
		and	al, ah
		or	es:[di], al
		retn


CMYKModeRout	label	 word
		nptr	CMYKCLEAR
		nptr	CMYKCOPY
		nptr	CMYKNOP
		nptr	CMYKAND
		nptr	CMYKINV
		nptr	CMYKXOR
		nptr	CMYKSET
		nptr	CMYKOR

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetDitherIndex
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup the "current" dither, given a color index

CALLED BY:	Color bitmap drawing routines
PASS:		al	- color to set
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		check to see if the desired color is in the cache;
		if so, make it the current one;
		if not, throw out the least recently used entry and calculate
		   the new value;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	3/ 3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MAX_USAGE_COUNT	equ	0x7fff

SetDitherIndex	proc	near
		uses	bx, si
		.enter

		; first see if we're doing the same color

		mov	bx, cs:[curCacheEntry]
		tst	bx			; check for uninit table
		jz	findNewIndex
		cmp	al, cs:[bx].CCE_color
		jne	findNewIndex
		mov	si, bx
		call	SetDitherPointers	; setup indices into dithers
done:
		inc	cs:[bx].CCE_usage

		.leave
		ret

checkBogus:
		tst	cs:[si].CCE_usage	; if bogus, continue
		jns	foundIt
		jmp	nextEntry		;  bogus, keep looking

		; check the cache for the color we want
findNewIndex:
		push	cx, dx, ax
		mov	si, offset cs:colorCache
		mov	bx, si
		tst	cs:[curCacheEntry]	; if not init, go dir to fillit
		jz	haveEmptySlot
		mov	cx, length colorCache
		mov	dx, MAX_USAGE_COUNT
searchLoop:
		cmp	al, cs:[si].CCE_color
		je	checkBogus		; make sure valid entry
		cmp	dx, cs:[si].CCE_usage	; found new most-unpopular ?
		jl	nextEntry		;  no, continue
		mov	bx, si			; save entry as least used
		mov	dx, cs:[si].CCE_usage
		tst	dx			; if negative, bogus entry
		js	haveEmptySlot

nextEntry:
		add	si, size ColorCacheEntry
		loop	searchLoop

		; didn't find it in the cache, have pointer to one to get
		; rid of.
haveEmptySlot:
		mov	si, bx
		mov	cs:[si].CCE_color, al
		mov	bl, al
		clr	bh
		shl	bx, 1			; * 2
		add	bl, al
		adc	bh, 0			; index into palette
		
		push	ds
		lds	dx, ss:[bmPalette]
		xchg	dx, si
		mov	cx, {word} ds:[si][bx].RGB_red
		xchg	dx, si
		mov	{word} cs:[si].CCE_rgb.RGB_red, cx
		xchg	dx, si
		mov	ah, ds:[si][bx].RGB_blue
		xchg	dx, si
		mov	cs:[si].CCE_rgb.RGB_blue, ah
		pop	ds
		clr	cs:[si].CCE_usage
		
		; now calculate the CMYK dither offsets.

		call	CalcCacheEntry

		; entry all set, cs:si -> entry.  Set current offsets
foundIt:
		call	SetDitherPointers
		pop	cx, dx, ax
		jmp	done

SetDitherIndex	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetDitherPointers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup the dither pointers based on current indices.

CALLED BY:	INTERNAL
		SetDitherIndex
PASS:		cs:[si]	- points at ColorCacheEntry structure
RETURN:		cs:[bx]	- points at ColorCacheEntry
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	9/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetDitherPointers proc	near
		.enter

		mov	ax, cs:[si].CCE_dither		; get dither pointer
		mov	bx, ss:[yellowBase]
		add	bx, ax
		mov	cs:[curYellow], bx
		mov	bx, ss:[cyanBase]
		add	bx, CYAN_OFFSET
		add	bl, ss:[cyanIndex]
		adc	bh, 0
		add	bx, ax
		mov	cs:[curCyan], bx
		add	bx, MAGENTA_OFFSET-CYAN_OFFSET
		mov	cs:[curMagenta], bx
		mov	bx, ss:[blackBase]
		add	bl, ss:[blackIndex]
		adc	bh, 0
		add	bx, BLACK_OFFSET
		add	ax, bx
		mov	cs:[curBlack], ax
		mov	cs:[curCacheEntry], si		; record for next time
		mov	bx, si				; pass on index

		.leave
		ret
SetDitherPointers endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetDitherRGB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set new bitmap color, pass it an RGB value (used for 24-bit)

CALLED BY:	INTERNAL
		PutColor24Scan
PASS:		cl	- red
		ch	- green
		ah	- blue
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	3/ 3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetDitherRGB	proc	near
		uses	bx, si
		.enter

		; first see if we're doing the same color

		mov	bx, cs:[curCacheEntry]
		tst	bx					; if no entries
		jz	findNewIndex
		cmp	cx, {word} cs:[bx].CCE_rgb.RGB_red
		jne	findNewIndex
		cmp	ah, cs:[bx].CCE_rgb.RGB_blue
		jne	findNewIndex
		mov	si, bx
		call	SetDitherPointers
done:
		inc	cs:[bx].CCE_usage

		.leave
		ret

		; check the cache for the color we want
findNewIndex:
		push	di, cx, dx, ax
		mov	si, offset cs:colorCache
		mov	bx, si
		mov	di, cx			; save red/green here
		mov	cx, length colorCache
		mov	dx, MAX_USAGE_COUNT		; start at max
searchLoop:
		cmp	di, {word} cs:[si].CCE_rgb.RGB_red
		je	foundIt			
		cmp	ah, cs:[si].CCE_rgb.RGB_blue
		je	foundIt			
		cmp	dx, cs:[si].CCE_usage
		jl	nextEntry
		mov	bx, si			; save entry as least used
		mov	dx, cs:[si].CCE_usage
		tst	dx			; if negative, then invalide
		js	haveEmptySlot
nextEntry:
		add	si, size ColorCacheEntry
		loop	searchLoop

		; didn't find it in the cache, have pointer to one to get
		; rid of.
haveEmptySlot:
		mov	si, bx
		mov	{word} cs:[si].CCE_rgb.RGB_red, di
		mov	cs:[si].CCE_rgb.RGB_blue, ah
		clr	cs:[si].CCE_usage
		
		; now calculate the CMYK dither offsets.

		call	CalcCacheEntry

		; entry all set, cs:si -> entry.  Set current offsets
foundIt:
		call	SetDitherPointers
		pop	di, cx, dx, ax
		jmp	done
SetDitherRGB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcCacheEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the dither offsets for the cache entry

CALLED BY:	SetDither{Index,RGB}
PASS:		cs:si	- points to ColorCacheEntry
		cl	- red
		ch	- green
		ah	- blue
RETURN:		nothing
DESTROYED:	ax,bx,cx, dx

PSEUDO CODE/STRATEGY:
		calculate the offsets into the CMYKDither resource to the 
		dithers for the passed color, and set the cache entry.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	3/ 3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcCacheEntry	proc	near
		uses	ds,es,si,di
cyanBlack	local	word
magentaYellow	local	word
		.enter

		; There may be some color correction table stored in the
		; printer driver.  If so, fetch it and do the correction.
		; no correction needed for black or white.  Handle those 
		; specially to avoid the pain of interpolation.

		tst	ss:colorTransferSeg		; if table non-zero...
		jz	convertToCMYK

		; don't color correct black, except if we are on a CMY printer
		; (no black ribbon).

		mov	al, ss:[bm_cacheType] 
		and	al, mask BMT_FORMAT
		cmp	al, BMF_3CMY			; do UC removal ?
		LONG je	doColorTransfer
		tst	cx
		LONG jnz doColorTransfer
		tst	ah
		LONG jnz doColorTransfer

convertToCMYK:
		mov	al, 255
		mov	bh, al
		mov	bl, al
		sub	al, cl
		sub	bl, ch
		sub	bh, ah
		mov	ah, ss:[bm_cacheType] 
		and	ah, mask BMT_FORMAT
		cmp	ah, BMF_3CMY			; do UC removal ?
		mov	ah, 0				; don't use CLR
		je	haveK
		mov	ah, al				; assume red is min
		cmp	bl, ah				; find minimum
		ja	tryBlue
		mov	ah, bl
tryBlue:
		cmp	bh, ah
		ja	haveK
		mov	ah, bh

		; do undercolor removal
haveK:
		sub	al, ah				; al = new cyan
		sub	bl, ah				; bl = new magenta
		sub	bh, ah				; bh = new yellow
		mov	cyanBlack, ax			; save results
		mov	magentaYellow, bx

		; OK, we have valid CMYK values.  Do the dither lookup.

		mov	ds, ss:colorDitherSeg		; ds -> dither resrce
		segmov	es, cs, di			; es -> our dithers
		mov	di, es:[si].CCE_dither		; get ptr to buffer

		assume	ds:CMYKDither

		mov	dx, ss:[resetColor]		; xor with this
		mov	cl, ss:[ditherRotX]		; need to rotate them
		clr	bh
		mov	bl, magentaYellow.high		; get yellow value
		shr	bx, 1
		shr	bx, 1
		shr	bx, 1
		adc	bx, 0				; round up
		shl	bx, 1				;  word table
		mov	si, ds:[ditherYellow][bx]	; get offset to dither
		lodsb					; just do all four 
		ror	al, cl				;  bytes inline.
		stosb
		lodsb
		ror	al, cl
		stosb
		lodsb
		ror	al, cl
		stosb
		lodsb
		ror	al, cl
		stosb

		clr	bh
		mov	bl, cyanBlack.low		; get cyan value
		shr	bx, 1
		shr	bx, 1
		shr	bx, 1
		adc	bx, 0				; round up
		shl	bx, 1				;  word table
		mov	si, ds:[ditherCyan][bx]		; get offset to dither
		call	CopyShiftCyan

		clr	bh
		mov	bl, magentaYellow.low		; get magenta value
		shr	bx, 1
		shr	bx, 1
		shr	bx, 1
		adc	bx, 0				; round up
		shl	bx, 1				;  word table
		mov	si, ds:[ditherMagenta][bx]	; get offset to dither
		call	CopyShiftCyan

		clr	bh
		mov	bl, cyanBlack.high		; get black value
		shr	bx, 1
		shr	bx, 1
		shr	bx, 1
		adc	bx, 0				; round up
		shl	bx, 1				;  word table
		mov	si, ds:[ditherBlack][bx]	; get offset to dither
		call	CopyShiftBlack

		.leave
		ret

		assume	ds:nothing

;---------------------------------------
;	Color Correction Code
;---------------------------------------

		; there are color transfer tables defined.  use them.
		; cl, ch, ah = red, green, blue components
doColorTransfer:
		cmp	cx, 0xffff			; check white
		jne	doTransfer
		cmp	ah, 0xff			; if done, go
		LONG je	convertToCMYK

if _INDEX_RGB_CORRECTION	;16 RGB value palette.....
		;added for systems that only use 16 colors ....ever....
		;DJD 6/14/95
doTransfer:
		push	di,si,bp	;save stuff

	;Entry:
	;cl = red
	;ch = green
	;ah = blue
	;
	; We want to obtain any exact match for the RGB triple that may
	; exist. we look at the incoming triples for a match to the VGA
	; palette triples.

		clr	bh
	;
	; Do blue first
	;
		mov	bl, ah
		and	bl, 0x03
		cmp	ah, cs:[validRGBTable2][bx]
		jne	slowWay
		mov	dl, bl			; else accumulate bits in DL
	;
	; Now work on the green
	;
		mov	bl, ch
		and	bl, 0x03
		cmp	ch, cs:[validRGBTable2][bx]
		jne	slowWay
		shl	dl
		shl	dl
		or	dl, bl			; accumulate bits in DL
	;
	; Finally do the red
	;
		mov	bl, cl
		and	bl, 0x03
		cmp	cl, cs:[validRGBTable2][bx]
		jne	slowWay
		shl	dl
		shl	dl
		or	bl, dl			; accumulate bits in BL
	;
	; Look up our index value
	;
		mov	al, cs:[colorRGBIndexTable2][bx]
		cmp	al, 0xff		; not a standard color
		je	slowWay
		
		clr	ah		;Get the index into
		mov	bp,ax		;BP, and 
		jmp	getTransfer	;start the lookup for the new triple

slowWay:

	;Entry:
	;cl = red
	;ch = green
	;ah = blue
	;
	; We want to obtain the closest match to the passed RGB triple
	; contained in the standard VGA pallette. We simply choose the
	; closest sum of the RGB values


		mov	di,16000	;initialize to something big.
		mov	si,15		;check 16 VGA values
getRGBDifference:
		mov	bl,cs:redTable2.[si]
		mov	bh,cs:greenTable2.[si]
		mov	dl,cs:blueTable2.[si]
		sub	bl,cl		;get red difference.
		jnc	getGreenDiff	;if no neg result
		neg	bl
getGreenDiff:
		sub	bh,ch		;get green difference.
		jnc	getBlueDiff
		neg	bh
getBlueDiff:
		sub	dl,ah		;get blue difference.
		jnc	sumDiff
		neg	dl
sumDiff:
		clr	dh		;add the three differences together.
		add	dl,bh
		adc	dh,0
		add	dl,bl
		adc	dh,0
					;now check totals to see if less than
					;stored total.
		cmp	di,dx
		jle	newTotal
		mov	di,dx		;save total for future compare.
		mov	bp,si		;save index for this set of values.
		tst	dx		;see if exact hit.
		jz	getTransfer	;shortcut....

newTotal:

	
		dec	si		;new index to try.
		jns	getRGBDifference ;next try...

getTransfer:
                push    ds
		mov	ds, ss:[colorTransferSeg]	; get correction blk
		
		mov	si,bp		;get index of corrected RGB triple
		add	si,bp
		add	si,bp		;three byte index

		lodsw			;get R and G
		mov	cx,ax		; cl = red, ch = green
		lodsb			;get B
		mov	ah,al		; ah = blue

                pop     ds
		pop	di,si,bp	;restore stuff.

	;Exit:
	;cl = corrected red
	;ch = corrected green
	;ah = corrected blue
                jmp     convertToCMYK


redTable2	label	byte
	byte	0,0,0,0,170,170,170,170,85,85,85,85,255,255,255,255
greenTable2	label	byte
	byte	0,0,170,170,0,0,85,170,85,85,255,255,85,85,255,255
blueTable2	label	byte
	byte	0,170,0,170,0,170,0,170,85,255,85,255,85,255,85,255

validRGBTable2	byte	0, 85, 170, 255

colorRGBIndexTable2	label	byte
				;R	G	B
		byte	0	;0	0	0
		byte	0xff	;85	0	0
		byte	4	;170	0	0
		byte	0xff	;255	0	0

		byte	0xff	;0	85	0
		byte	0xff	;85	85	0
		byte	6	;170	85	0
		byte	0xff	;255	85	0

		byte	2	;0	170	0
		byte	0xff	;85	170	0
		byte	0xff	;170	170	0
		byte	0xff	;255	170	0

		byte	0xff	;0	255	0
		byte	0xff	;85	255	0
		byte	0xff	;170	255	0
		byte	0xff	;255	255	0

		byte	0xff	;0	0	85
		byte	0xff	;85	0	85
		byte	0xff	;170	0	85
		byte	0xff	;255	0	85

		byte	0xff	;0	85	85
		byte	8	;85	85	85
		byte	0xff	;170	85	85
		byte	12	;255	85	85

		byte	0xff	;0	170	85
		byte	0xff	;85	170	85
		byte	0xff	;170	170	85
		byte	0xff	;255	170	85

		byte	0xff	;0	255	85
		byte	10	;85	255	85
		byte	0xff	;170	255	85
		byte	14	;255	255	85

		byte	1	;0	0	170
		byte	0xff	;85	0	170
		byte	5	;170	0	170
		byte	0xff	;255	0	170

		byte	0xff	;0	85	170
		byte	0xff	;85	85	170
		byte	0xff	;170	85	170
		byte	0xff	;255	85	170

		byte	3	;0	170	170
		byte	0xff	;85	170	170
		byte	7	;170	170	170
		byte	0xff	;255	170	170

		byte	0xff	;0	255	170
		byte	0xff	;85	255	170
		byte	0xff	;170	255	170
		byte	0xff	;255	255	170

		byte	0xff	;0	0	255
		byte	0xff	;85	0	255
		byte	0xff	;170	0	255
		byte	0xff	;255	0	255

		byte	0xff	;0	85	255
		byte	9	;85	85	255
		byte	0xff	;170	85	255
		byte	13	;255	85	255

		byte	0xff	;0	170	255
		byte	0xff	;85	170	255
		byte	0xff	;170	170	255
		byte	0xff	;255	170	255

		byte	0xff	;0	255	255
		byte	11	;85	255	255
		byte	0xff	;170	255	255
		byte	15	;255	255	255

else ;_INDEX_RGB_CORRECTION

doTransfer:
		mov	dx, ax				; dh = blue
		xchg	dx, cx				; dl = red,dh = green
							; ch = blue
		push	ds, si
		mov	ds, ss:[colorTransferSeg]	; get correction blk
		;
		; dl = red, dh = green, ch = blue
		; cl = shift amount
		; si = offset into RGBDelta table (base value)
		; bx = offset into RGBDelta table (for interpolation)
		; al = 6 saved bits to use for interp (2 bits x 3 colors)
		push	cx, dx
		clr	al, bh				; use al for interpBits
		mov	cl, 4				; need six, but start4
		shr	ch, cl				; do blue first
		adc	ch, 0				; round up
		mov	ah, ch
		shr	ax, 1
		shr	ax, 1				; al = BBxxxxxx
		mov	bl, ah				; build base value

		shr	dh, cl				; now do GREEN
		adc	dh, 0				; round up
		mov	ah, dh
		shr	ax, 1				; save interp bits
		shr	ax, 1				; al = GGBBxxxx
		add	bl, ah				; need green *5
		shl	ah, 1				; *2
		shl	ah, 1				; *4
		add	bl, ah				; *5
		
		shr	dl, cl				; now do RED
		adc	dl, 0				; round up
		mov	ah, dl
		shr	ax, 1
		shr	ax, 1				; al = RRGGBBxx
		add	bl, ah				; need red *25
		mov	cl, 3
		shl	ah, cl
		add	bl, ah
		shl	ah, 1
		add	bl, ah

		; now see about offset to interp value
		; for each of the two bits that we saved above (the fractional
		; bits, if you will), we test and add either 1/2, 1/4 or
		; both of the difference between the base adjustment value
		; and the secondary value used to interpolate between.
		; Do this for each of red, green and blue.
		
		mov	si, bx				; save base offset
		test	al, 0x0c			; test blue bits
		jz	checkGreen
		inc	bx
checkGreen:
		test	al, 0x30			; test green interpBits
		jz	checkRed
		add	bx, 5
checkRed:
		test	al, 0xc0			; test red bits
		jz	haveInterpOffset
		add	bx, 25
haveInterpOffset:
		mov	dx, bx				; *3 (RGVDelta values)
		shl	bx, 1				;  (interp value)
		add	bx, dx
		mov	dx, si				; *3 (RGVDelta values)
		shl	si, 1				;  (base value)
		add	si, dx
		pop	cx, dx				; restore original clrs
		mov	ah, ds:[si].RGBD_red		; al = red base adjust
		test	al, 0xc0			; red interp ?
		jz	bumpRed
		mov	cl, ds:[bx].RGBD_red		; get other interp valu
		sub	cl, ah				; calc difference
		sar	cl, 1				; at least this
		test	al, 0x80			; check each bit
		jz	addRed4
		add	ah, cl
		test	al, 0x40
		jz	bumpRed
addRed4:
		sar	cl, 1
		add	ah, cl
bumpRed:
		add	dl, ah
		jc	checkRedOverflow
adjustGreen:
		mov	ah, ds:[si].RGBD_green		; al = red base adjust
		test	al, 0x30			; green interp ?
		jz	bumpGreen
		mov	cl, ds:[bx].RGBD_green		; get other interp valu
		sub	cl, ah				; calc difference
		sar	cl, 1				; at least this
		test	al, 0x20			; check each bit
		jz	addGreen4
		add	ah, cl
		test	al, 0x10
		jz	bumpGreen
addGreen4:
		sar	cl, 1
		add	ah, cl
bumpGreen:
		add	dh, ah
		jc	checkGreenOverflow
adjustBlue:
		mov	ah, ds:[si].RGBD_blue
		test	al, 0x0c			; blue interp ?
		jz	bumpBlue
		mov	cl, ds:[bx].RGBD_blue		; get other interp valu
		sub	cl, ah				; calc difference
		sar	cl, 1				; at least this
		test	al, 0x08			; check each bit
		jz	addBlue4
		add	ah, cl
		test	al, 0x04
		jz	bumpBlue
addBlue4:
		sar	cl, 1
		add	ah, cl
bumpBlue:
		add	ch, ah
		jc	checkBlueOverflow
colorAdjusted:
		mov	ah, ch				; ah = blue
		mov	cx, dx				; cl = red, ch = green
		pop	ds, si
		jmp	convertToCMYK

		; we need to catch wrapping of each component value past 
		; 0xff (or past 0x00 for negative adjustment values).  
		; We get here via the addition of the adjustment value 
		; generating a carry.  If the adjustment value was negative
		; and the result positive, we are OK.  Otherwise there was
		; a bad wrapping of the value.  Use the resulting sign of 
		; the component value to determine if we need to clamp the
		; value to 0x00 or 0xff.
checkRedOverflow:
		tst	ah				; check adjust value
		js	adjustGreen
		mov	dl, 0xff			; limit value
		jmp	adjustGreen
checkGreenOverflow:
		tst	ah				; check adjust value
		js	adjustBlue
		mov	dh, 0xff			; limit value
		jmp	adjustBlue
checkBlueOverflow:
		tst	ah
		js	colorAdjusted
		mov	ch, 0xff			; limit value
		jmp	colorAdjusted
endif ;_INDEX_RGB_CORRECTION
CalcCacheEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyShiftCyan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy a cyan/magenta dither matrix and shift it

CALLED BY:	CalcCacheEntry
PASS:		ds:si	- pointer to unshifted dither
		es:di   - pointer to buffer to store shifted one
		cl	- shift count
RETURN:		es:di 	- points to after dither
DESTROYED:	si, ax, cx, bx
		
PSEUDO CODE/STRATEGY:
		shift each scan line

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	3/ 4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyShiftCyan	proc	near

		mov	ch, CMYK_DITHER_HEIGHT

		; use ax to rotate each byte
scanLoop:
		clr	bl
		mov	bh, CMYK_DITHER_WIDTH-1
byteLoop:
		clr	ah
		lodsb
		ror	ax, cl				; last byte = first
		xchg	bl, ah				; save shift out bits
		or	al, ah
		stosb
		dec	bh
		jnz	byteLoop
		or	es:[di-(CMYK_DITHER_WIDTH-1)], bl
		dec	ch
		jnz	scanLoop
		ret
CopyShiftCyan	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyShiftBlack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy and shift a black dither matrix

CALLED BY:	CalcCacheEntry
PASS:		ds:si	- points to unshifted dither
		es:di	- points to buffer to hold shifted dither
		cl	- shift count
RETURN:		es:di	- points after dither
		
DESTROYED:	si, cx, bx,ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	3/ 4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyShiftBlack	proc	near

		mov	ch, BLACK_DITHER_HEIGHT

		; use ax to rotate each byte
scanLoop:
		mov	bh, BLACK_DITHER_WIDTH-2
		clr	ah
		lodsb
		ror	ax, cl				; last byte = first
		mov	bl, ah
		mov	dh, al				; save first byte...
		inc	di				; bump to 2nd byte
byteLoop:
		lodsb
		clr	ah
		ror	ax, cl
		xchg	bl, ah
		or	al, ah
		stosb
		dec	bh
		jnz	byteLoop
		or	dh, bl
		mov	es:[di-(BLACK_DITHER_WIDTH-1)], dh
		dec	ch
		jnz	scanLoop

		ret
CopyShiftBlack	endp


		; this structure holds all the info needed to cache pointers
		; to the dither matrices.
ColorCacheEntry	struct	
    CCE_color	byte		; color index
    CCE_rgb	RGBValue	; RGB value for that index 
    CCE_dither	nptr		; offset to dither matrix
    CCE_usage	word		; incremented each time used
ColorCacheEntry	ends


		; these offsets are the ones for the current color
curCacheEntry	nptr	0	; another optimization
colorWriteByte	nptr	0	; routine vector

		; allocate a few of these cached color dithering entries
colorCache	ColorCacheEntry 16 dup(<>)


		; now we allocate space for the actual dithers.  These are
		; a little smaller than the dither matrix that we store in
		; cmykgroup, since that is used to word-wide operations while
		; we only need one to do bytes (so these are a byte narrower)

YELLOW_SIZE	equ	4
CYAN_SIZE	equ	50
BLACK_SIZE	equ	18
BM_DITHER_SIZE	equ	YELLOW_SIZE + 2*CYAN_SIZE + BLACK_SIZE

YELLOW_OFFSET	equ	0
CYAN_OFFSET	equ	YELLOW_OFFSET + YELLOW_SIZE
MAGENTA_OFFSET  equ	CYAN_OFFSET + CYAN_SIZE
BLACK_OFFSET	equ	MAGENTA_OFFSET + CYAN_SIZE

dither0		byte	BM_DITHER_SIZE dup (0)
dither1		byte	BM_DITHER_SIZE dup (0)
dither2		byte	BM_DITHER_SIZE dup (0)
dither3		byte	BM_DITHER_SIZE dup (0)
dither4		byte	BM_DITHER_SIZE dup (0)
dither5		byte	BM_DITHER_SIZE dup (0)
dither6		byte	BM_DITHER_SIZE dup (0)
dither7		byte	BM_DITHER_SIZE dup (0)
dither8		byte	BM_DITHER_SIZE dup (0)
dither9		byte	BM_DITHER_SIZE dup (0)
ditherA		byte	BM_DITHER_SIZE dup (0)
ditherB		byte	BM_DITHER_SIZE dup (0)
ditherC		byte	BM_DITHER_SIZE dup (0)
ditherD		byte	BM_DITHER_SIZE dup (0)
ditherE		byte	BM_DITHER_SIZE dup (0)
ditherF		byte	BM_DITHER_SIZE dup (0)

VidEnds		ClrBitmap
