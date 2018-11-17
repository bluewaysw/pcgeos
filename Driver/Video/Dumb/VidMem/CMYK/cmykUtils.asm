COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		VidMem video driver
FILE:		cmykUtils.asm

AUTHOR:		Jim DeFrisco, Dec 13, 1991

ROUTINES:
	Name			Description
	----			-----------
    INT SetDither		Setup the dither patterns for the CMYK
				module
    INT CopyCyanDither		Initialize the common dither matrix from
				the dither resource
    INT CopyBlackDither		Same type of thing as CopyCyanDither, above
    INT CalcDitherIndices	Calculate the offsets into the dithers,
				based on the x and y positions, and the
				window y position.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	12/13/91	Initial revision


DESCRIPTION:
	Various utilities for CMYK vidmem module
		

	$Id: cmykUtils.asm,v 1.1 97/04/18 11:43:07 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetDither
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup the dither patterns for the CMYK module

CALLED BY:	various drawing 

PASS:		ds:si -> CommonAttr structure

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		convert RGB color value into CMYK and setup pointers to
		dither patterns for each plane.

		The RGB -> CMY conversion goes like:

			C = 255 - R
			M = 255 - G
			Y = 255 - B

		Then K is calculated as:

			K = min(C,M,Y)

		Then undercolor removal happens:

			C = C - K
			M = M - K
			Y = Y - K

		Then any supplied transfer function (a lookup table) is 
		applied to the CMYK values.  Then the resulting values are
		used to choose between 32 dither patterns available for
		each component.  The reason that different dither patterns
		are necc for each component is that the halftone functions
		are placed along an angle wrt horizontal to avoid moire 
		effects.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	12/13/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetDither	proc	far
		uses	ax, bx, ds, cx, dx, si
cyanBlack	local	word
magentaYellow	local	word
		.enter

		; first check to see if we already have this dither built

		push	dx
		mov	ax, es:[W_ditherY]		; only need it in y
		mov	cs:[bigDitherRotY], ax		; save for later
		cwd					; dxax = dividend
		mov	bx, BLACK_DITHER_HEIGHT 		; bx = divisor
		idiv	bx
		tst	dl
		jns	haveBlackRem
		add	dl, BLACK_DITHER_HEIGHT
haveBlackRem:
		mov	ah, dl				; dl = remainder
		mov	al, es:[W_pattPos].low 
		mov	{word} cs:[ditherRotX], ax	; save window rotation
		mov	ax, es:[W_ditherY]		; only need it in y
		cwd					; dxax = dividend
		mov	bx, CMYK_DITHER_HEIGHT 		; bx = divisor
		idiv	bx
		tst	dl
		jns	haveCyanRem
		add	dl, CMYK_DITHER_HEIGHT
haveCyanRem:
		mov	ah, dl				; dl = remainder
		mov	al, es:[W_pattPos].low 
		mov	{word} cs:[ditherCyanRotX], ax	; save window rotation

		pop	dx
		mov	cl, ds:[si].CA_colorRGB.RGB_red
		mov	ch, ds:[si].CA_colorRGB.RGB_green
		mov	ah, ds:[si].CA_colorRGB.RGB_blue

		; check to see if we really need to re-create it.  If the color
		; is the same, and the shift amount is the same, then we're OK.

		cmp	cl, cs:[ditherColor].RGB_red
		jne	setNewDither
		cmp	ch, cs:[ditherColor].RGB_green
		jne	setNewDither
		cmp	ah, cs:[ditherColor].RGB_blue
		jne	setNewDither

		; OK, the color matches the one stored.  Unfortunately, if
		; it's black, then the dither matrix might not be set up
		; because black is 0,0,0 and that is the initial value of
		; the RGB value stored in cs:[ditherColor].

		tst	ah
		jnz	nearDone
		jcxz	checkBlackDither
nearDone:
		jmp	done

		; see if black dither matrix is initialized
checkBlackDither:
		tst	cs:[blackDither]	; check for non-zero
		jnz	nearDone

		; first store the values, then do some conversions
setNewDither:
		mov	cs:[ditherColor].RGB_red, cl
		mov	cs:[ditherColor].RGB_green, ch
		mov	cs:[ditherColor].RGB_blue, ah

		; There may be some color correction table stored in the
		; printer driver.  If so, fetch it and do the correction.
		; no correction needed for black or white.  Handle those 
		; specially to avoid the pain of interpolation.

		
		tst	cs:colorTransfer		; if table non-zero...
		jz	convertToCMYK

		; don't color correct black, except if we are on a CMY printer
		; (no black ribbon).

		mov	al, cs:[bm_cacheType] 
		and	al, mask BMT_FORMAT
		cmp	al, BMF_3CMY			; do UC removal ?
		LONG je	doColorTransfer
		tst	cx
		LONG jnz	doColorTransfer
		tst	ah
		LONG jnz	doColorTransfer

		; have color corrected values.  Convert to CMYK
convertToCMYK:
		mov	al, 255
		mov	bh, al
		mov	bl, al
		sub	al, cl
		sub	bl, ch
		sub	bh, ah
		mov	ah, cs:[bm_cacheType] 
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

		mov	bx, handle CMYKDither
		call	MemLock
		mov	ds, ax				; ds -> dither resrce

assume	ds:CMYKDither

		mov	dx, cs:[resetColor]		; xor with this
		clr	bh
		mov	bl, cyanBlack.low		; get cyan value
		mov	cl, 3
		shr	bx, cl				; divide by 8 and
		adc	bx, 0				; round up
		shl	bx, 1				;  word table
		mov	si, ds:[ditherCyan][bx]		; get offset to dither
		mov	bx, offset cyanDither		; put after yellow
		call	CopyCyanDither
		call	CopyCyanDither
		call	CopyCyanDither
		call	CopyCyanDither
		call	CopyCyanDither
; setMagenta
		clr	bh
		mov	bl, magentaYellow.low		; get magenta value
		shr	bx, cl				; divide by 8 and
		adc	bx, 0				; round up
		shl	bx, 1				;  word table
		mov	si, ds:[ditherMagenta][bx]	; get offset to dither
		mov	bx, offset magentaDither
		call	CopyCyanDither			; copy another of these
		call	CopyCyanDither
		call	CopyCyanDither
		call	CopyCyanDither
		call	CopyCyanDither
; setYellow:
		clr	bh
		mov	bl, magentaYellow.high		; get yellow value
		shr	bx, cl				; divide by 8 and
		adc	bx, 0				; round up
		shl	bx, 1				;  word table
		mov	bx, ds:[ditherYellow][bx]	; get offset to dither
		mov	ax, ds:[bx]
		xor	ax, dx
		mov	cs:[ditherMatrix], al
		mov	cs:[ditherMatrix+1], al
		mov	cs:[ditherMatrix+2], ah
		mov	cs:[ditherMatrix+3], ah
		mov	ax, ds:[bx+2]			; only four bytes
		xor	ax, dx
		mov	cs:[ditherMatrix+4], al
		mov	cs:[ditherMatrix+5], al
		mov	cs:[ditherMatrix+6], ah
		mov	cs:[ditherMatrix+7], ah
; setBlack:
		clr	bh
		mov	bl, cyanBlack.high		; get black value
		shr	bx, cl				; divide by 8 and
		adc	bx, 0				; round up
		shl	bx, 1				;  word table
		mov	si, ds:[ditherBlack][bx]	; get offset to dither
		call	CopyBlackDither

		mov	bx, handle CMYKDither
		call	MemUnlock
done:
		.leave
		ret

		; there are color transfer tables defined.  use them.
		; As a first pass, don't do any interpolation.  The values
		; in the tables are delta values.
doColorTransfer:
		cmp	cx, 0xffff			; check white
		jne	doTransfer
		cmp	ah, 0xff			; if done, go
		LONG je	convertToCMYK

if _INDEX_RGB_CORRECTION	;16 RGB value pallette.....
		;added for systems that only use 16 colors ....ever....
		;DJD 6/14/95
doTransfer:

		push	di,bp		;save stuff

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
		cmp	ah, cs:[validRGBTable][bx]
		jne	slowWay
		mov	dl, bl			; else accumulate bits in DL
	;
	; Now work on the green
	;
		mov	bl, ch
		and	bl, 0x03
		cmp	ch, cs:[validRGBTable][bx]
		jne	slowWay
		shl	dl
		shl	dl
		or	dl, bl			; accumulate bits in DL
	;
	; Finally do the red
	;
		mov	bl, cl
		and	bl, 0x03
		cmp	cl, cs:[validRGBTable][bx]
		jne	slowWay
		shl	dl
		shl	dl
		or	bl, dl			; accumulate bits in BL
	;
	; Look up our index value
	;
		mov	al, cs:[colorRGBIndexTable][bx]
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
		mov	bl,cs:redTable.[si]
		mov	bh,cs:greenTable.[si]
		mov	dl,cs:blueTable.[si]
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
                mov     bx, cs:[colorTransfer]          ; get block handle
                push    ds
                call    MemLock                         ; lock the block
                mov     ds, ax                          ; ds -> block
		
		mov	si,bp		;get index of corrected RGB triple
		add	si,bp
		add	si,bp		;three byte index

		lodsw			;get R and G
		mov	cx,ax		; cl = red, ch = green
		lodsb			;get B
		mov	ah,al		; ah = blue

                mov     bx, cs:[colorTransfer]          ; get block handle
                call    MemUnlock                       ; lock the block
                pop     ds
		pop	di,bp		;restore stuff.

	;Exit:
	;cl = corrected red
	;ch = corrected green
	;ah = corrected blue
                jmp     convertToCMYK


redTable	label	byte
	byte	0,0,0,0,170,170,170,170,85,85,85,85,255,255,255,255
greenTable	label	byte
	byte	0,0,170,170,0,0,85,170,85,85,255,255,85,85,255,255
blueTable	label	byte
	byte	0,170,0,170,0,170,0,170,85,255,85,255,85,255,85,255

validRGBTable	byte	0, 85, 170, 255

colorRGBIndexTable	label	byte
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
		push	ds
		mov	bx, cs:[colorTransfer]		; get block handle
		call	MemLock				; lock the block
		mov	ds, ax				; ds -> block
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
		mov	bx, cs:[colorTransfer]		; get block handle
		call	MemUnlock			; lock the block
		pop	ds
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
if (0)
checkRedUnderflow:
		tst	dl				; if negative, set 0
		jns	adjustGreen
		clr	dl
		jmp	adjustGreen
endif
checkGreenOverflow:
		tst	ah				; check adjust value
		js	adjustBlue
		mov	dh, 0xff			; limit value
		jmp	adjustBlue
if (0)
checkGreenUnderflow:
		tst	dh
		jns	adjustBlue
		clr	dh
		jmp	adjustBlue
endif
checkBlueOverflow:
		tst	ah
		js	colorAdjusted
		mov	ch, 0xff			; limit value
		jmp	colorAdjusted
if (0)
checkBlueUnderflow:
		tst	ch
		jns	colorAdjusted
		clr	ch
		jmp	colorAdjusted
endif
endif ;_INDEX_RGB_CORRECTION
SetDither	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyCyanDither
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the common dither matrix from the dither resource

CALLED BY:	SetDither
PASS:		ds:si	- pointer to dither matrix in resource
		cs:bx	- pointer to dither matrix to initialize
		dx	- resetColor
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		The dither matrix to initialize is padded in x to an even
		number of bytes to make the drawing code more optimal.  This
		means that for each scan line of the dither, the first byte is
		repeated as the last byte (this the special routine to copy it)

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyCyanDither	proc	near
		lodsw					; get word
		xor	ax, dx
		mov	{word} cs:[bx], ax	; store pattern away
		mov	{byte} cs:[bx+5], al  ; store 2nd copy
		lodsw					; get word
		xor	ax, dx
		mov	{word} cs:[bx+2], ax
		lodsw					; get word
		xor	ax, dx
		mov	{byte} cs:[bx+4], al
		mov	{byte} cs:[bx+6], ah
		mov	{byte} cs:[bx+11], ah
		lodsw					; get word
		xor	ax, dx
		mov	{word} cs:[bx+7], ax
		lodsw					; get word
		xor	ax, dx
		mov	{word} cs:[bx+9], ax
		add	bx, 2*CMYK_DITHER_WIDTH		; 2 scans per call
		ret
CopyCyanDither	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyBlackDither
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Same type of thing as CopyCyanDither, above

CALLED BY:	
PASS:		ds:si	- pointer to dither matrix in resource
		dx	- resetColor
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyBlackDither	proc	near
		lodsw					; get word
		xor	ax, dx
		mov	{word} cs:[blackDither], ax	; store pattern away
		mov	{byte} cs:[blackDither+3], al ; store 2nd copy
		lodsw					; get word
		xor	ax, dx
		mov	{byte} cs:[blackDither+2], al
		mov	{byte} cs:[blackDither+4], ah
		mov	{byte} cs:[blackDither+7], ah
		lodsw					; get word
		xor	ax, dx
		mov	{word} cs:[blackDither+5], ax
		lodsw					; get word
		xor	ax, dx
		mov	{word} cs:[blackDither+8], ax
		mov	{byte} cs:[blackDither+11], al
		lodsw					; get word
		xor	ax, dx
		mov	{byte} cs:[blackDither+10], al	
		mov	{byte} cs:[blackDither+12], ah	
		mov	{byte} cs:[blackDither+15], ah	
		lodsw					; get word
		xor	ax, dx
		mov	{word} cs:[blackDither+13], ax
		lodsw					; get word
		xor	ax, dx
		mov	{word} cs:[blackDither+16], ax
		mov	{byte} cs:[blackDither+19], al
		lodsw					; get word
		xor	ax, dx
		mov	{byte} cs:[blackDither+18], al	
		mov	{byte} cs:[blackDither+20], ah	
		mov	{byte} cs:[blackDither+23], ah	
		lodsw					; get word
		xor	ax, dx
		mov	{word} cs:[blackDither+21], ax
		ret
CopyBlackDither	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcDitherIndices
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the offsets into the dithers, based on the x and
		y positions, and the window y position.

CALLED BY:	various drawing routines
PASS:		ax,bx  x/y positions that object will be draw at
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcByteDitherIndices proc far
		push	ax, bx, cx, dx
		tst	ax			; if negative...
		jns	shiftIt
		neg	ax
shiftIt:
		shr	ax, 1			; calc #bytes overrr
		shr	ax, 1
		shr	ax, 1			
		push	ax
		cwd
		mov	cl, BLACK_DITHER_WIDTH-1
		clr	ch
		div	cx
		mov	cs:[blackLeftIndex], dl ; save it
		mov	ax, bx			; do same for y direction
		tst	ax
		jns	divHeight
		neg	ax
divHeight:
		mov	bx, ax			; save this for next time
		sub	ax, cs:[bigDitherRotY]	; take window pos into account
		cwd
		mov	cl, BLACK_DITHER_HEIGHT	; ditherMatrix is 6 scans high
		clr	ch
		idiv	cx
		tst	dx
		jns	haveBlackRem
		add	dx, BLACK_DITHER_HEIGHT
haveBlackRem:
		mov	al, dl
		shl	dl, 1			; *3 since this is the byte
		add	dl, al			;  width of the ditherMatrix
		mov	cs:[blackTopIndex], dl	; save this too

		; calc the cyan and magenta indices

		pop	ax
		cwd
		mov	cl, CMYK_DITHER_WIDTH-1
		clr	ch
		div	cx
		mov	cs:[cyanLeftIndex], dl	; save index
		mov	ax, bx
		sub	al, cs:[ditherCyanRotY]
		sbb	ah, 0
		cwd
		mov	cl, CMYK_DITHER_HEIGHT
		clr	ch
		idiv	cx
		tst	dx
		jns	haveCyanRem
		add	dx, CMYK_DITHER_HEIGHT
haveCyanRem:
		mov	al, dl			; save it
		shl	dl, 1			; *2
		shl	dl, 1			; *4
		add	dl, al			; *5
		mov	cs:[cyanTopIndex], dl

		and	bl, 3			; yellow matrix is 4 bytes hi
		mov	cs:[yellowTopIndex], bl
		pop	ax, bx, cx, dx
		ret
CalcByteDitherIndices endp

CalcDitherIndices proc	far
		push	ax, bx, cx, dx
		tst	ax			; if negative...
		jns	shiftIt
		neg	ax
shiftIt:
		shr	ax, 1			; calc #bytes overrr
		shr	ax, 1
		shr	ax, 1			
		and	al, 0xfe		; clear low bit to align with
						;  words
		push	ax
		cwd
		mov	cl, BLACK_DITHER_WIDTH-1
		clr	ch
		div	cx
		mov	cs:[blackLeftIndex], dl ; save it
		mov	ax, bx			; do same for y direction
		tst	ax
		jns	divHeight
		neg	ax
divHeight:
		mov	bx, ax			; save this for next time
		sub	ax, cs:[bigDitherRotY]	; need to use the big kahuna
		cwd
		mov	cl, BLACK_DITHER_HEIGHT	; ditherMatrix is 6 scans high
		clr	ch
		idiv	cx
		tst	dx
		jns	haveBlackRem
		add	dx, BLACK_DITHER_HEIGHT
haveBlackRem:
		shl	dl, 1			; *4 since this is the byte
		shl	dl, 1			;  width of the ditherMatrix
		mov	cs:[blackTopIndex], dl	; save this too

		; calc the cyan and magenta indices

		pop	ax			; restore byte position
		cwd
		mov	cl, CMYK_DITHER_WIDTH-1
		clr	ch
		div	cx
		mov	cs:[cyanLeftIndex], dl	; save index
		mov	ax, bx
		sub	al, cs:[ditherCyanRotY]
		sbb	ah, 0
		cwd
		mov	cl, CMYK_DITHER_HEIGHT
		clr	ch
		idiv	cx
		tst	dx
		jns	haveCyanRem
		add	dx, CMYK_DITHER_HEIGHT
haveCyanRem:
		shl	dl, 1			; *2
		mov	al, dl			; save it
		shl	dl, 1			; *4
		add	dl, al			; *6
		mov	cs:[cyanTopIndex], dl

		and	bl, 3			; yellow matrix is 4 bytes hi
		mov	cs:[yellowTopIndex], bl
		pop	ax, bx, cx, dx
		ret

CalcDitherIndices endp
