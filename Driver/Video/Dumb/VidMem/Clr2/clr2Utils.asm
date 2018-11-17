COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	PC GEOS
MODULE:		VidMem/Clr2
FILE:		clr2Utils.asm

AUTHOR:		Joon Song, Oct 7, 1996

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	10/7/96   	Initial revision


DESCRIPTION:


	$Id: clr2Utils.asm,v 1.1 97/04/18 11:43:10 newdeal Exp $

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
CalcDitherIndices	proc	far
		uses	ax, bx
		.enter
		and	bx, 7			; 8 scans in buffer2
		shl	bx, 1			; * 2 since 2 bytes/scan
		mov	cs:[buff2Top], bl	
		.leave
		ret
CalcDitherIndices	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BuildDataByte
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Expand a one-bit/pixel byte into two-bit/pixel bytes

CALLED BY:	INTERNAL
PASS:		al	- byte to expand
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	6/ 4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BuildDataByteFar	proc	far
		call	BuildDataByte
		ret
BuildDataByteFar	endp

BuildDataByte	proc	near
		uses	bx
		.enter

		mov	bl, al

;	BL <- high nibble (left most bits of data)

		shr	bl, 4
		clr	bh
		mov	bl, cs:[nibbleTable][bx]	; do first 4 pixels
		mov	cs:[dataBuff2+1], bl
		mov	bl, al
		and	bl, 0xf
		mov	bl, cs:[nibbleTable][bx]
		mov	cs:[dataBuff2], bl
		
		.leave
		ret
BuildDataByte	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BuildDataMask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Expand a one-bit/pixel mask into two-bit/pixel masks

CALLED BY:	INTERNAL
PASS:		bh	- mask to expand
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	6/ 4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BuildDataMaskFar	proc	far
		call	BuildDataMask
		ret
BuildDataMaskFar	endp

BuildDataMask	proc	near
		uses	bx
		.enter

		mov	al, bh
		mov	bl, al

;	BL <- high nibble (left most bits of data)

		shr	bl, 4
		clr	bh
		mov	bl, cs:[nibbleTable][bx]	; do first 4 pixels
		mov	cs:[dataMask2+1], bl
		mov	bl, al
		and	bl, 0xf
		mov	bl, cs:[nibbleTable][bx]
		mov	cs:[dataMask2], bl
		
		.leave
		ret
BuildDataMask	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BuildMasks2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build out a 8-pixel by 8-line mask buffer

CALLED BY:	INTERNAL
		CopyMask macro
PASS:		maskBuffer setup with 8-byte mask
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	6/ 4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MapMonoMaskTo2BitMask macro
		mov	al, bl
		and	bl, 0xf
		mov	bl, cs:[nibbleTable][bx]
		xchg	al, bl
		shr	bl, 4
		mov	ah, cs:[nibbleTable][bx]
		stosw
endm

BuildMasks2	proc	far
		uses	ax,bx,di,es
		.enter

		segmov	es, cs, di
		mov	di, offset maskBuff2

		clr	bh
		mov	bl, cs:maskBuffer	; do first byte
		MapMonoMaskTo2BitMask
		mov	bl, cs:maskBuffer+1	; do second byte
		MapMonoMaskTo2BitMask
		mov	bl, cs:maskBuffer+2	; do third byte
		MapMonoMaskTo2BitMask
		mov	bl, cs:maskBuffer+3	; do fourth byte
		MapMonoMaskTo2BitMask
		mov	bl, cs:maskBuffer+4	; do fifth byte
		MapMonoMaskTo2BitMask
		mov	bl, cs:maskBuffer+5	; do sixth byte
		MapMonoMaskTo2BitMask
		mov	bl, cs:maskBuffer+6	; do seventh byte
		MapMonoMaskTo2BitMask
		mov	bl, cs:maskBuffer+7	; do eigth byte
		MapMonoMaskTo2BitMask

		.leave
		ret
BuildMasks2	endp

ifdef	LEFT_PIXEL_IN_LOW_BITS
nibbleTable	label	byte
		byte	00000000b		;0000b
		byte	11000000b		;0001b
		byte	00110000b		;0010b
		byte	11110000b		;0011b
		byte	00001100b		;0100b
		byte	11001100b		;0101b
		byte	00111100b		;0110b
		byte	11111100b		;0111b
		byte	00000011b		;1000b
		byte	11000011b		;1001b
		byte	00110011b		;1010b
		byte	11110011b		;1011b
		byte	00001111b		;1100b
		byte	11001111b		;1101b
		byte	00111111b		;1110b
		byte	11111111b		;1111b
else
nibbleTable	label	byte
		byte	00000000b		;0000b
		byte	00000011b		;0001b
		byte	00001100b		;0010b
		byte	00001111b		;0011b
		byte	00110000b		;0100b
		byte	00110011b		;0101b
		byte	00111100b		;0110b
		byte	00111111b		;0111b
		byte	11000000b		;1000b
		byte	11000011b		;1001b
		byte	11001100b		;1010b
		byte	11001111b		;1011b
		byte	11110000b		;1100b
		byte	11110011b		;1101b
		byte	11111100b		;1110b
		byte	11111111b		;1111b
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetDither
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup ditherMatrix for 2-bit video

CALLED BY:	various drawing routines
PASS:		ds:si	-> CommonAttr structure
		es	-> Window structure
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		*** DOES NOT YET DEAL WITH RGB COLORS ***
		*** AND WE SHOULD TRY TO DITHER NON-GRAY COLORS ***

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	10/ 7/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

colorTable word 0xffff, 0xaaaa, 0xaaaa, 0xaaaa, 0xaaaa, 0xaaaa, 0xaaaa, 0x5555,
		0xaaaa, 0x5555, 0x5555, 0x5555, 0x5555, 0x5555, 0x5555, 0x0000

SetDither	proc	far
	uses	bx
	.enter

	clr	bx
	mov	bl, ds:[si].CA_colorIndex
	and	bl, (length colorTable) - 1
	shl	bx, 1
	mov	bx, cs:[colorTable][bx]

	mov	{word} cs:[ditherMatrix+0], bx
	mov	{word} cs:[ditherMatrix+2], bx
	mov	{word} cs:[ditherMatrix+4], bx
	mov	{word} cs:[ditherMatrix+6], bx

	.leave
	ret
SetDither	endp
