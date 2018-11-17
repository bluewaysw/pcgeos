
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		PostScript (bitmap) printer driver 
FILE:		psbUtils.asm

AUTHOR:		Jim DeFrisco

ROUTINES:
	Name			Description
	----			-----------
	EmitStartObject		emit PS code to start off drawing
	EmitEndObject		emit PS code to end drawing
	EmitTransform		emit PS code to effect the current transform
	EmitLineAttributes	emit PS code to set the current line attributes

	MatrixToAscii		convert a TransMatrix structure to ASCII
	WWFixedToAscii		convert a WWFixed number to ASCII
	UWordToAscii		convert an unsigned integer to ASCII
	SWordToAscii		convert a signed integer to ASCII
	EmitBuffer		write out an internal buffer
	ExtractElement		copy a gstring element into a separate buffer
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	6/91		Initial revision


DESCRIPTION:
	This file contains code to emit common sections of PostScript code.
		

	$Id: psbUtils.asm,v 1.1 97/04/18 11:52:04 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitPaperSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write some PostScript code to set the paper size

CALLED BY:	INTERNAL
		PrintSetPageTransform

PASS:		es	- points at locked PState
		di	- file handle to write to

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		put pseudo code here

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EmitPaperSize	proc	far
		uses	bx, cx, di, es, ds, si
scratchBuffer	local	60 dup(char)
		.enter

		; set up pointers to ASCII buffer for translation

		segmov	ds, es, di			; ds -> PState
		segmov	es, ss, di
		lea	di, scratchBuffer		; es:di -> buffer

		; change it to ascii, add SCT command and send it out

		mov	cx, ds:[PS_customWidth]	; get width and height
		mov	dx, ds:[PS_customHeight] 

		; cx = width, dx = height
haveSize:
		push	dx				; save height
		mov	bx, cx				; convert width
		call	UWordToAscii			; convert to ascii
		mov	al, ' '				; space separator
		stosb
		pop	bx				; restore height
		call	UWordToAscii			; convert that too
		push	ds				; save PState segment
		segmov	ds, cs, si
		mov	si, offset emitSPS
		mov	cx, length emitSPS
		rep	movsb
		segmov	ds, ss, si
		lea	si, scratchBuffer		; ds:si -> buffer
		sub	di, si				; di = #chars to write
		mov	cx, di
		pop	es				; es -> PState
		call	PrintStreamWrite		; send buffer content
		.leave
		ret
EmitPaperSize	endp

emitSPS		char	" SPS", NL


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UWordToAscii
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert an unsigned word to ascii

CALLED BY:	GLOBAL

PASS:		bx	- unsigned word
		es:di	- location to put string (must be at least 7 chars)

RETURN:		es:di	- points to byte after string

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		nothing earth-shattering

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	02/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UWordToAscii	proc	near
		uses	ax, bx, si, dx
		.enter

		; check for 0 and 1 since they are so popular...

		mov	{byte} es:[di], '0'	; always need at least one zero
		tst	bx			; if this is zero, all done
		jz	trivialDone
		cmp	bx, 1			; check for 1 too...
		jne	doInteger
		inc	{byte} es:[di]		; make it a '1'
trivialDone:
		inc	di			; bump past the one
		jmp	done

		; OK, no easy out.  Set up some translation regs
doInteger:
		mov	ax, 10000		; cx is kind of a divisor
		mov	si, 10
		clr	dx

		; skip leading zeroes
skipZeroes:
		cmp	bx, ax			; get down to where it matters
		jae	digitLoop
		div	si
		tst	ax			; if not zero yet, keep going
		jnz	skipZeroes
		jmp	done

		; convert the remaining integer part
digitLoop:
		sub	bx, ax			; do next digit
		jb	nextDigit		
		inc	{byte} es:[di]		; bump number
		jmp	digitLoop
nextDigit:
		inc	di			; onto next digit place
		add	bx, ax			; add it back in
		div	si
		tst	ax			; if zero
		jz	done			; done, do fraction part
		mov	{byte} es:[di], '0'	; init next digit
		jmp	digitLoop		; continue
done:		
		.leave
		ret
UWordToAscii	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcStringLength
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Caculate the number of characters in a string
CALLED BY:	INTERNAL
		various routines

PASS:		ds:dx	- ptr to string
RETURN:		cx	- number of characters in string (not including NULL)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
		guess.
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		carry is always returned clear

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	2/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalcStringLength	proc	near
	uses	ax, ds, es, di
	.enter

	segmov	es, ds, di
	mov	di, dx				; es:di <- ptr to string
	mov	cx, PATH_BUFFER_SIZE		; cx <- our largest string
	clr	al				; al <- looking for null
	repne	scasb				; find it 
	sub	di, dx				; di = #chars into string
	mov	cx, di
	dec	cx
						; carry always clear on exit
	.leave
	ret
CalcStringLength	endp

