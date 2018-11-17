
COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		PostScript printer driver
FILE:		psbPage.asm

AUTHOR:		Jim DeFrisco

ROUTINES:
	Name		Description
	----		-----------
	PrintStartPage	initialize the page-related variables, called once/page
			by EXTERNAL at start of page.
	PrintEndPage	Tidy up the page-related variables, called once/page
			by EXTERNAL at end of page.

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Jim	6/90	initial version

DESCRIPTION:

	$Id: psbPage.asm,v 1.1 97/04/18 11:52:10 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintStartPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the page

CALLED BY:	GLOBAL

PASS:		bp	- PSTATE segment address.

RETURN:		carry	- set if some transmission error

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

PrintStartPage	proc	far
		uses	ax, bx, es, ds
		.enter

		mov	es, bp			; es -> PState

		; first lock down the things we'll need

		mov	bx, handle PSCode	; get ps code resource
		call	GeodeLockResource	; lock it down
		mov	ds, ax			; ds -> ps code

		; start off the page

		call	EmitPageSetup		; carry set from this routine

		mov	bx, handle PSCode	; release resource
		call	MemUnlock
done:
		.leave
		ret
PrintStartPage	endp


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintEndPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the page

CALLED BY:	GLOBAL

PASS:		bp	- PSTATE segment address.

RETURN:		carry	-set if some communications error

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

PrintEndPage	proc	far
		uses	ax, bx, cx, dx, si, es, ds
		.enter

		mov	es, bp			; es -> PState
		
		; just need to write out end page stuff.  but also check to
		; see if the interpreter is expecting any more scan lines.
		; if it is, write out the appropriate number of hex digits.

		cmp     es:[PS_asciiSpacing+2], 0 ; any more scan lines left ?
		jne     moreToWrite             ; more scans to write

		; first lock down the things we'll need
writeTrailer:
		mov	bx, handle PSCode	; get ps code resource
		call	GeodeLockResource	; lock it down
		mov	ds, ax			; ds -> ps code

		; do some bookeeping

		EmitPS	emitEO			; write out EndObject
		jc	unlockResource
		inc	es:[PS_asciiStyle]	; bump the page number
		EmitPS	emitEP			; write out EndPage
		jc	unlockResource
		EmitPS	emitEndDict		; write out EndPage
		jc	unlockResource
		EmitPS	emitRestore		; write out EndPage
		jc	unlockResource
		EmitPS	pageTrailer		; write out %%PageTrailer
unlockResource:
		mov	bx, handle PSCode	; release resource
		call	MemUnlock
done:
		.leave
		ret

moreToWrite:
		mov     cx, {word} es:[PS_asciiSpacing+2] ; #scans to write
		mov     ax, {word} es:[PS_asciiSpacing]   ; #bytes per scan
		mul     cx                         ; ax = total #
		mov     cx, ax                  ; cx = total
		mov     dx, 0                   ; #bytes written on curr line
byteLoop:
		push    cx                      ; save byte count
		mov     cl, '0'                 ; write out zeroes
		call    PrintStreamWriteByte    ; write a byte
		jc      errorWriting
		call    PrintStreamWriteByte    ; write a byte
		jc      errorWriting
		add     dx, 2                   ; see if we should stop now
		cmp     dx, 80                  ; only do 80/line
		jb      doNextByte
		mov     cl, C_CR                ; write out CRLF
		call    PrintStreamWriteByte    ; write a byte
		jc      errorWriting
		mov     cl, C_LF                ; write out CRLF
		call    PrintStreamWriteByte    ; write a byte
		jc      errorWriting
doNextByte:
		pop     cx
		loop    byteLoop
		jmp     writeTrailer

errorWriting:
		pop     cx                      ; restore register
		jmp     done

PrintEndPage	endp
