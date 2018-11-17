COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		VidMem video driver	
FILE:		clr4Utils.asm

AUTHOR:		Jim DeFrisco, Feb 11, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	2/11/92		Initial revision


DESCRIPTION:
	
		

	$Id: clr4Utils.asm,v 1.1 97/04/18 11:42:52 newdeal Exp $

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
CalcDitherIndices		proc	far
		uses	ax, bx
		.enter
		shr	ax, 1
		and	al, 3			; do mask index
		mov	cs:[buff4Left], al
		and	ax, 1			; dither matrix is 1-word wide
		mov	{word} cs:[ditherLeftIndex], ax
		and	bx, 7			; 8 scans in buffer4
		shl	bx, 1			; *4 since 4bytes/scan
		shl	bx, 1
		mov	cs:[buff4Top], bl	
		.leave
		ret
CalcDitherIndices		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BuildDataByte
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Expand a one-bit/pixel byte into 4 nibble/pixel bytes

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

ifdef	USE_186
		shr	bl, 4
else
		mov	bh, cl
		mov	cl, 4
		shr	bl, cl
		mov	cl, bh
endif
		clr	bh
		shl	bx, 1				;Change to word index
		mov	bx, cs:[nibbleTable][bx]	; do first 4 pixels
		mov	cs:[dataBuff4], bx
		mov	bl, al
		and	bl, 0xf
		clr	bh
		shl	bx, 1				; 2 bytes/entry
		mov	bx, cs:[nibbleTable][bx]
		mov	cs:[dataBuff4+2], bx
		
		.leave
		ret
BuildDataByte	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BuildDataMask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Builds out a data mask

CALLED BY:	GLOBAL
PASS:		bh - mask to build out
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	8/ 7/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ifndef	MEM_CLR4
	; I haven't changed the vidmem driver to use this routine
BuildDataMaskFar	proc	far
		uses	ax, bx
		.enter
		mov	al, bh
		mov	bl, al

;	BL <- high nibble (left most bits of data)

ifdef	USE_186
		shr	bl, 4		;Shift to low nibble
else
		mov	bh, cl
		mov	cl, 4
		shr	bl, cl
		mov	cl, bh
endif
		clr	bh
		shl	bx, 1				;Change to word index
		mov	bx, cs:[nibbleTable][bx]	; do first 4 pixels
		mov	cs:[dataMask4], bx
		mov	bl, al
		and	bl, 0xf
		clr	bh
		shl	bx, 1				; 2 bytes/entry
		mov	bx, cs:[nibbleTable][bx]
		mov	cs:[dataMask4+2], bx
		
		.leave
		ret
BuildDataMaskFar	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BuildMasks4
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build out a 4-byte by 8-line mask buffer

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
MapByteToNibbles macro
		mov	ch, bl			; save byte
		shr	bl, cl
		shl	bx, 1
		mov	ax, cs:[nibbleTable][bx]
		stosw
		mov	bl, ch
		and	bl, 0xf
		shl	bx, 1
		mov	ax, cs:[nibbleTable][bx]
		stosw
endm

BuildMasks4	proc	far
		uses	bx, ax, es, di, cx
		.enter

		segmov	es, cs, di
		mov	di, offset maskBuff4

		mov	cl, 4
		clr	bh

		mov	bl, cs:maskBuffer	; do first byte
		MapByteToNibbles

		mov	bl, cs:maskBuffer+1	; do second byte
		MapByteToNibbles

		mov	bl, cs:maskBuffer+2	; do third byte
		MapByteToNibbles

		mov	bl, cs:maskBuffer+3	; do fourth byte
		MapByteToNibbles

		mov	bl, cs:maskBuffer+4	; do fifth byte
		MapByteToNibbles

		mov	bl, cs:maskBuffer+5	; do sixth byte
		MapByteToNibbles

		mov	bl, cs:maskBuffer+6	; do seventh byte
		MapByteToNibbles

		mov	bl, cs:maskBuffer+7	; do eigth byte
		MapByteToNibbles

		.leave
		ret
BuildMasks4	endp


ifdef	LEFT_PIXEL_IN_LOW_NIBBLE
nibbleTable	label	word
		byte	0x00, 0x00		;0000b
		byte	0x00, 0xf0		;0001b
		byte	0x00, 0x0f		;0010b
		byte	0x00, 0xff		;0011b

		byte	0xf0, 0x00		;0100b
		byte	0xf0, 0xf0		;0101b
		byte	0xf0, 0x0f		;0110b
		byte	0xf0, 0xff		;0111b
		
		byte	0x0f, 0x00		;1000b
		byte	0x0f, 0xf0		;1001b
		byte	0x0f, 0x0f		;1010b
		byte	0x0f, 0xff		;1011b

		byte	0xff, 0x00		;1100b
		byte	0xff, 0xf0		;1101b
		byte	0xff, 0x0f		;1110b
		byte	0xff, 0xff		;1111b
else
nibbleTable	label	word
		word	0x0000, 0x0f00, 0xf000, 0xff00
		word	0x000f, 0x0f0f, 0xf00f, 0xff0f
		word	0x00f0, 0x0ff0, 0xf0f0, 0xfff0
		word	0x00ff, 0x0fff, 0xf0ff, 0xffff
endif


