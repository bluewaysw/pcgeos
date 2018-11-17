COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		VidMem video driver	
FILE:		monoUtils.asm

AUTHOR:		Jim DeFrisco, Feb 11, 1992

ROUTINES:
	Name			Description
	----			-----------
    INT CalcDitherIndices	Calculate dither indices, given rectangle
				position
    INT SetDitherClustered	Setup the dither matrix if we are in
				clustered mode
    INT ShiftClusterPattern	Rotate the dither pattern

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	2/11/92		Initial revision


DESCRIPTION:
	misc routines to support vidmem mono mode
		

	$Id: monoUtils.asm,v 1.1 97/04/18 11:42:40 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcDitherIndices
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate dither indices, given rectangle position

CALLED BY:	INTERNAL
		DrawSimpleRect
PASS:		ax	- left coordinate
		bx	- top coordinate
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcDitherIndices proc	far
		test	cs:[bm_flags], mask BM_CLUSTERED_DITHER	; clustered ?
		jnz	calcDither
done:
		ret

		; we only need to do something if we are in clustered dither
		; mode.  
calcDither:
		push	ax, cx, dx
		tst	ax			; if negative...
		js	negativePos
shiftIt:
		shr	ax, 1			; calc #bytes overrr
		shr	ax, 1
		shr	ax, 1			
		and	al, 0xfe		; clear low bit 
		clr	dx
		mov	cl, MONO_DITHER_WIDTH-1
		clr	ch
		div	cx
		mov	cs:[ditherLeftIndex], dl ; save it
		mov	ax, bx			; do same for y direction
		tst	ax
		js	negHeight
divHeight:
		sub	ax, cs:[bigDitherRotY]
		clr	dx
		mov	cl, MONO_DITHER_HEIGHT	; ditherMatrix is 6 scans high
		clr	ch
		div	cx
		shl	dl, 1
		shl	dl, 1			; *4 (byte width)
		mov	cs:[ditherTopIndex], dl	; save this too
		pop	ax, cx, dx
		jmp	done

negativePos:
		neg	ax
		jmp	shiftIt
negHeight:
		neg	ax
		jmp	divHeight
CalcDitherIndices endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetDitherClustered
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup the dither matrix if we are in clustered mode

CALLED BY:	SetDither

PASS:		cl,ch,bl - red,green,blue components, respectively
		es	- Window

RETURN: 	cs:[ditherMatrix] - set

DESTROYED:	ax,bx,cx,ds

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetDitherClustered proc	near
		uses	si
		.enter
	
		; copy a component to the dither index over 

		mov	ax, es:[W_ditherY]
		mov	cs:[bigDitherRotY], ax

		; calculate the luminence of the pixel

		mov	ax, cx
	
		call	GrCalcLuminance		; ax = luminance
		tst	cs:colorTransfer		; if table non-zero...
		jnz	doColorTransfer

		; we need to map this luminence value (0-255) to a smaller 
		; range (0-31) so that's a shift right three bits. We then 
		; need to index into a word table of offsets, that's a 
		; one bit shift left
haveLum:
		mov	cx, 255			; need inverse of luminence
		sub	cx, ax
		shr	cl, 1			; divide luminence by 8
		shr	cl, 1
		shr	cl, 1
		adc	cl, 0			; account for rounding
		shl	cx, 1			;   make into an index

		; lock down the resource with the 6x18 dither patterns

		mov	bx, handle CMYKDither
		call	MemLock
		mov	ds, ax			; ds -> dither resrce
		
		mov	bx, cx			; bx = table index
		assume	ds:CMYKDither
		mov	si, ds:[ditherBlack][bx]

		; this gets a little messy, since we are expanding the size
		; of the dither matrix that is stored in the resource by one
		; byte when we store in into the local buffer.  This allows us
		; to more easily access the bytes, since it will be four bytes
		; wide instead of three.

		mov	cl, cs:[ditherRotX]
		call	ShiftClusterPattern

		; done with dither block

		mov	bx, handle CMYKDither
		call	MemUnlock
		assume	ds:nothing

		.leave
		ret

		; do some gamma correction, since the printer driver was
		; so kind as to provide us with a table.
doColorTransfer:
		push	bx
		xchg	cx, ax
		mov	bx, cs:colorTransfer	; get block handle
		call	MemLock
		mov	ds, ax
		xchg	cx, ax
		mov	cx, bx			; save table handle
		clr	bx			; ds:bx -> table
		xlatb				; ax = corrected luminance
;doneColor:
		mov	bx, cx			; restore table handle
		call	MemUnlock		; release table
		pop	bx
		jmp	haveLum
SetDitherClustered endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ShiftClusterPattern
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Rotate the dither pattern

CALLED BY:	SetDitherClustered
PASS:		cl = amount to rotate in X
RETURN:		nothing
DESTROYED:	ax, cx, si

PSEUDO CODE/STRATEGY:
		we can finesse the y rotation by starting further down in the
		dither matrix (this is done in CalcDitherIndices), but we 
		have to do the X rotation the hard way.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ShiftClusterPattern	proc	near
		uses	dx, es, di
		.enter

		segmov	es, cs, di
		mov	di, offset cs:ditherMatrix
		mov	dl, {byte} cs:[resetColor]	; XOR with reset color
		mov	ch, MONO_DITHER_HEIGHT

		; use ax to rotate each byte
scanLoop:
		mov	bh, MONO_DITHER_WIDTH-2
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
		xor	al, dl
		stosb
		dec	bh
		jnz	byteLoop
		or	dh, bl
		xor	dh, dl
		mov	es:[di], dh
		mov	es:[di-(MONO_DITHER_WIDTH-1)], dh
		inc	di
		dec	ch
		jnz	scanLoop

		.leave
		ret
ShiftClusterPattern	endp
