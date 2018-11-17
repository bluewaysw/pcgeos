
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		PostScript print driver
FILE:		psbGraphics.asm

AUTHOR:		Jim DeFrisco

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	6/11/91		Initial revision


DESCRIPTION:
	This file contains most of the code to implement the 
	print driver graphics mode support

	$Id: psbGraphics.asm,v 1.1 97/04/18 11:52:10 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintSwath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Print a page-wide bitmap

CALLED BY:	GLOBAL

PASS:		bp	- PState segment
		dx:si	- Start of bitmap structure.

RETURN:		carry	-set if some communications error

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintSwath	proc	far
		uses	ax,cx,bx,dx,si,di,ds,es
		.enter
	
		mov	es, bp			; es -> PState
		mov	ds, dx			; ds:si -> bitmap
		mov	cx, ds:[si].B_height	; get scan line count for this
		sub	{word} es:[PS_asciiSpacing+2], cx ; fewer after this
		jns	doSlice			; if not done yet, continue 
		add	cx, {word} es:[PS_asciiSpacing+2] ; do this many only
		mov	{word} es:[PS_asciiSpacing+2], 0	; we're done
doSlice:
		mov	ax, ds:[si].B_width	; ax = width, cx = height
		add	ax, 7
		shr	ax, 1			; divide by 8 to get byte width
		shr	ax, 1
		shr	ax, 1			; ax = scan line byte width
						; cx = #scans in this slice
		add	si, ds:[si].CB_data	; ds:si -> first scan line
scanLoop:
		call	EmitScanLine		; write out one scan line
		jc	done
		add	si, ax			; point to next scan line
		loop	scanLoop		; keep going til swatch done 
		clc				; signal no error
done:
		.leave
		ret
PrintSwath	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitScanLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out a single scan line

CALLED BY:	INTERNAL
		PrintSwath

PASS:		ds:si	- points to scan line data 
		es	- points to locked PState

RETURN:		carry	- set if some transmission error

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		convert scan to hex ascii and write out

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	06/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EmitScanLine	proc	near
		uses	ax, cx, dx, di, si, ds, es
pstate		local	sptr
scratchBuffer	local	90 dup(char)
		.enter

		; just loop on the size of the bitmap as stored in PState

		mov	pstate, es		; save PState segment
		mov	cx, {word} es:[PS_asciiSpacing] ; get width
		shr	cx, 1			; get #bytes
		shr	cx, 1
		shr	cx, 1
		segmov	es, ss, di
		lea	di, scratchBuffer	; es:di -> buffer
		clr	dx			; dx holds #chars curr in buff
byteLoop:
		lodsb				; get next byte of bitmap
		not	al			; invert for stupid vidmem
		call	WriteHexByte		; write out the byte
		jc	done
		loop	byteLoop		; finish them all

		; done converting the scan line.  write it out

		mov	al, C_CR
		mov	ah, C_LF
		stosw
		mov	es, pstate		; restore PState segment
		mov	cx, dx			; write out this many
		jcxz	done
		add	cx, 2
		segmov	ds, ss, si
		lea	si, scratchBuffer
		call	PrintStreamWrite
done:
		.leave
		ret
EmitScanLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteHexByte
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out a hex byte, with some buffer control

CALLED BY:	INTERNAL
		EmitMonoScan

PASS:		al		- byte to write
		dx		- #chars in buffer so far
		es:di		- pointer into buffer

RETURN:		carry		- set if transmission error
		dx		- updated appropriately
		es:di		- bumped to where next char should go

DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		put pseudo code here

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WriteHexByte	proc	near
		uses	bx
pstate		local	sptr
scratchBuffer	local	90 dup(char)
		.enter	inherit

		mov	bl, al			; get byte
		clr	bh
		and	bl, 0xf0		; do high nibble first
		shr	bl, 1
		shr	bl, 1
		shr	bl, 1
		shr	bl, 1
		mov	ah, cs:hexDigits[bx]
		mov	bl, al
		and	bl, 0xf
		mov	al, cs:hexDigits[bx]
		xchg	al, ah
		stosw				; save hex digits
		add	dx, 2			; see if line is complete
		cmp	dx, 80			; if at line's end
		jae	finishLine
		clc				; no error possible
done:
		.leave
		ret

		; have a full line.  Write out the CRLF
finishLine:
		mov	al, C_CR
		mov	ah, C_LF
		stosw
		push	ds, si, cx, es
		segmov	ds, ss, si
		lea	si, scratchBuffer
		mov	cx, dx			; cx = char count (almost)
		add	cx, 2			; get CRLF too
		mov	es, pstate
		call	PrintStreamWrite	; write out bytes
		lea	di, scratchBuffer	; reset pointer to beginning
		mov	dx, 0			; reset count (don't use clr)
		pop	ds, si, cx, es		; restore regs
		jmp	done			; carry will be set correctly
WriteHexByte	endp

hexDigits	char	"0123456789abcdef"
