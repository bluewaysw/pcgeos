COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer Drivers
FILE:		textPrintText.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------
	PrintText		Print a text string

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	3/1/90		Initial revision
	Dave	3/92		Moved in a bunch of common test routines
	Dave	5/92		Parsed up printcomText.asm


DESCRIPTION:

	$Id: textPrintText.asm,v 1.1 97/04/18 11:50:02 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	PrintText prints a text string pointed at by es:si

CALLED BY: 	GLOBAL

PASS: 		bp	- Segment of PSTATE
		dx:si	- start of null terminated string.
		cx	- character count, or 0 for NULL-terminated text

RETURN: 	carry	- set if some error sending string to printer

DESTROYED: 	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	02/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintText	proc	far
	uses	ax,bx,cx,dx,si,ds,es,di
	.enter

		; first set up the pointers right

	mov	ds, dx		; ds -> string

		; if null terminated, skip the character count

	tst	cx		; see if null terminated
	jnz	textCounted

		; null terminated, count the characters

	push	si		; save pointer to text
	mov	es, dx		; es -> string
	mov	di,si		; load the destination reg.
SBCS <	mov	al,cl		;  and the target for scanning.		>
DBCS <	mov	ax,cx		;  and the target for scanning.		>
	dec	cx		; max count = 0xffff
SBCS <	repne 	scasb		; look for zero.			>
DBCS <	repne 	scasw		; look for zero.			>
	neg	cx		; cx how has count
	sub	cx, 2
	pop	si
	jz	done		; have a valid count, send it

		; now we have a character count, so do it
textCounted:
	mov	es,bp		; es -> PState

charLoop:
	push	cx		; save count
SBCS <	lodsb			; pick up a byte.			>
DBCS <	lodsw			; pick up a byte.			>

		; need to do some translation in case we're on a foreign printer
if	not PZ_PCGEOS
	mov	bx,offset PS_asciiTrans ; get offset to trans table
	xlatb	es:
else
	cmp	ax, C_NON_BREAKING_SPACE
	jne	notNBS
	mov	ax, C_SPACE
notNBS:
endif

SBCS <	cmp	al, C_LF	; see if its a line feed.		>
DBCS <	cmp	ax, C_LF	; see if its a line feed.		>
	je	handleLF
SBCS <	tst	al		; if zero, don't send it		>
DBCS <	tst	ax		; if zero, don't send it		>
	jz	nextByte	;  it's probably the NULL terminator

if	PZ_PCGEOS

	;; Checking for Kanji.
	clr	dx
	mov	bx, CODE_PAGE_JIS
	call	LocalGeosToDosChar
	jc	exitErr
	tst	ah
	jz	notKanji

	;; Okay, let's print in Kanji mode.

	call	PrintStreamKanji
	jc	exitErr
	jmp	nextByte

notKanji:
endif
	mov	cl,al		; get byte to send into cl.	
	call	PrintStreamWriteByte	; write out a byte
	jc	exitErr		; exit early with some error. 

nextByte:
	pop	cx
	loop	charLoop

done:
	clc			; make sure carry clear

exit:
	.leave
	ret

		; found a line feed, send it differently
handleLF:
	call	SendLineFeed	; send our line feed distance.
	jnc	nextByte	; if no error....

exitErr:
	pop	cx		; restore stack
	jmp	exit		; all done
PrintText	endp


if PZ_PCGEOS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintStreamKanji
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Print out Kanji in Esc P mode.

CALLED BY:	PrintText
PASS:		es	= segment of PState
		ax	= char to print.
RETURN:		CF	= 1 iff error
DESTROYED:	cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	VM	4/24/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintStreamKanji	proc	near
	uses	ds,si
	.enter
	;; Set Kanji on.
		segmov	ds, cs
		mov	si, offset cs:pr_codes_SetKanji
		call	SendCodeOut
		jc	done
		
	;; Send the double byte character.
		mov	cl, ah
		call	PrintStreamWriteByte
		jc	done
		mov	cl, al
		call	PrintStreamWriteByte
		jc	done

	;; Turn Kanji off.
		mov	si, offset cs:pr_codes_ResetKanji
		call	SendCodeOut
done:
	.leave
	ret
PrintStreamKanji	endp

endif




