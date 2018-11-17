
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		PostScript (bitmap) Printer driver
FILE:		psbBitmap.asm

AUTHOR:		Jim DeFrisco

ROUTINES:
	Name			Description
	----			-----------
	EmitBitmap		write out bitmap to PS file

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	6/91		Initial revision


DESCRIPTION:
	This file contains the code to output a PC/GEOS bitmap to PostScript
		

	$Id: psbBitmap.asm,v 1.1 97/04/18 11:52:04 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitBitmapParams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out the beginning of a bitmap 

CALLED BY:	INTERNAL
		EmitPageSetup

PASS:		es		- points to locked PState

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Beware.  There are a lot of pseudo-magic constants in this
		routine.  That's what you get with a printer driver written
		in two days.  so sue me.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	06/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EmitBitmapParams	proc	near
		uses	ax, bx, cx, dx, si, di, ds, es
scratchBuffer	local	80 dup(char)
		.enter
		
		push	es			; we'll need this later

		; we need to output a few pieces of info, in the following 
		; order:  <bitmap width> <bitmap height> <scan line size>
		; <image width> <image height> <0> <0> DMB
		; the bitmap width and height depend on the resolution that
		; we are printing to.  The scan line size is the bitmap width
		; divided by 8, rounded up if necc.  The image width and height
		; is the paper width/height minus the margins

		; common to all modes is the need to calc the printable area

		mov	ax, es:[PS_customHeight]	; get paper size
		sub	ax, 36				; fixed margins (sorry)
		push	ax				; save for later
		mov	bx, es:[PS_customWidth]		; get paper size
		sub	bx, 36				; fixed margins (sorry)
		push	bx				; save for later
		mov	si, ax			; save height
		clr	ax
		
		; falls through for hires case (probably most common)...
		; To get bitmap size, mult width and height by 300/72 = 4.166667

		mov	dx, 4			; 4.
		mov	cx, 0x2aab		; 4.16667

		cmp	es:[PS_mode], PM_GRAPHICS_MED_RES ; see which it is
		jb	handleLowRes
		je	handleMedRes
calcWidth:
		push	cx, dx			; save mul factor for height
		call	GrMulWWFixed		; dx.cx = bitmap width
		shl	cx, 1			; push overflow into carry
		adc	dx, 7			; round up to nearest byte
		and	dl, 0xf8		; 
		segmov	ds, es, di		; ds -> PState
		segmov	es, ss, di		; set up scratch
		lea	di, scratchBuffer
		mov	bx, dx			; set up for writing
		mov	{word} ds:[PS_asciiSpacing], dx ; save width
		call	UWordToAscii		; write out bitmap width
		mov	al, ' '			; space delimited numbers
		stosb
		pop	cx, dx			; restore mul factor
		push	bx			; save width
		mov	bx, si			; recover height
		clr	ax
		call	GrMulWWFixed		; dx.cx = bitmap height
		mov	bx, dx			; write bitmap height
		mov	{word} ds:[PS_asciiSpacing+2], dx ; save height
		call	UWordToAscii		; change to ascii
		mov	al, ' '			; space delimited numbers
		stosb
		pop	bx			; restore width
		shr	bx, 1			; calc #bytes to hold scan
		shr	bx, 1
		shr	bx, 1			; divide by 8...
		call	UWordToAscii		; save it
		stosb
		pop	bx			; recover image width
		call	UWordToAscii
		stosb
		pop	bx			; recover image height
		call	UWordToAscii
		mov	ah, '0'			; need to write two zeroes next
		stosw
		stosw
		stosb				; final space
		mov	al, 'D'			; write "DMB"
		mov	ah, 'M'
		stosw
		mov	al, 'B'
		stosb
		mov	al, C_CR		; write newline
		mov	ah, C_LF
		stosw
		segmov	ds, ss, si		; ds:si -> buffer
		lea	si, scratchBuffer
		mov	cx, di			; calc length
		sub	cx, si
		pop	es			; restore PState pointer
		call	PrintStreamWrite	; copy buffer to port

		.leave
		ret

		; load mul factors for other resolutions
handleLowRes:
		mov	dx, 1			; load up 75/72 = 1.04
		mov	cx, 0xaab
		jmp	calcWidth

handleMedRes:
		mov	dx, 2			; load up 150/72 = 2.08
		mov	cx, 0x1555
		jmp	calcWidth
EmitBitmapParams	endp

