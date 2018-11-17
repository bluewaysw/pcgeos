
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		laserjet print driver
FILE:		textPrintTextPCL4.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	PrintText		Print a text string
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	1/22/92		Initial revision from laserdwnText.asm


DESCRIPTION:
	This file contains most of the code to implement the PCL 4
	print driver ascii text support

	$Id: textPrintTextPCL4.asm,v 1.1 97/04/18 11:50:02 newdeal Exp $

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
	CAUTION: the only legal non printable character to pass this routine
	is a CR.
	Space characters are converted into horizontal cursor moves.
	Two fonts need to be on the disk for this routine to work:
	URW Mono, and URW Sans get used to approximate unwanted bitmap
	and printer fonts.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	02/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintText	proc	far
	uses	bx,cx,dx,si,ds,es,di
curJob  local   FontDriverInfo
        push    ax
        mov     ax,bp           ;save PState address
	.enter
        mov     curJob.FDI_pstate,ax

	mov	es,ax				;es--->Pstate.
	cmp	es:PS_printerSmart,PS_DUMB_RASTER ;see if we can download font
	je	fontInPrinter			;if not, skip.

	push	dx
	push	cx
		;load the VM file handle into the locals.
	mov	bx,es:PS_expansionInfo
	call	MemLock				;lock font block.
	mov	ds,ax				;ds--> font info segment.
	mov	ax,ds:HPFI_bmFileHandle		;get bitmap file handle.
	mov	curJob.FDI_fileHandle,ax	;store in locals.
	call	MemUnlock

;check for AOL Printing, if it is force, the font to URW Mono 12.
	cmp	es:PS_curFont.FE_fontID,FID_PRINTER_10CPI
	jne	afterFontForce			;because the bright boys force
	call	PrintSetURWMono12
afterFontForce:

	mov	cx,es:PS_curFont.FE_fontID	;get GEOS font ID.
	mov	dl,mask FEF_OUTLINES		;check for outline fonts,
	call	GrCheckFontAvail		;check to see if on disk.
	test	cx,cx				;if the font is here, then
	jnz	afterPresentTest
	mov	cx,FID_DTC_URW_ROMAN		;set it to roman for a guess.
	mov	es:PS_curFont.FE_fontID,cx	;set it in PState,
	mov	es:PS_curFont.FE_size,12	;12 point font.
afterPresentTest:
	mov	dx,cx				;get into dx for FontAddFace
	call	FontAddFace			;select the new font (add it

	pop	cx
	pop	dx
						;if necessary)
fontInPrinter:
	; first set up the pointers right

	mov	ds, dx		; ds -> string

	; if null terminated, skip the character count

	tst	cx		; see if null terminated
	jnz	textCounted

	; null terminated, count the characters

	push	si		; save pointer to text
	mov	es, dx		; es -> string
	mov	di,si		; load the destination reg.
	mov	al,cl		;  and the target for scanning.
	dec	cx		; max count = 0xffff
	repne 	scasb		; look for zero.
	neg	cx		; cx how has count
	sub	cx, 2
	pop	si
	jz	done		; have a valid count, send it

	; now we have a character count, so do it
textCounted:
	mov	es,curJob.FDI_pstate		; es -> PState
	cmp	es:PS_printerSmart,PS_DUMB_RASTER ;see if we can download font
	je	charLoop			;if not, skip.
	mov	dx,es:PS_curFont.FE_fontID	;get GEOS font ID.
	call	FontAddChars	;add the characters that we need for this
				;string if they aren't already there.
	jc	exit		;pass any transmission error out.
charLoop:
	push	cx		; save count
	lodsb			; pick up a byte.

        cmp     es:PS_printerSmart,PS_DUMB_RASTER ;see if we can download font
        jne	xlatted		;bypass xlat for download fonts.
                ;need to do some translation in case we're on a foreign printer
        mov     bx,offset PS_asciiTrans ; get offset to trans table
        xlatb   es:
xlatted:
	cmp	al, C_LF	; see if its a line feed.
	je	handleLF
	cmp	al, C_SPACE	; see if its a space.
	je	heresASpace
	jb	nextByte	; print no control codes in the $0X, $1X area.
	cmp	al, C_NONBRKSPACE ; see if its a non break space.
	jne	afterSpace
heresASpace:
	call	FontSendSpace
	jc	exitErr
	jmp	nextByte
afterSpace:
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
	pop	ax
	ret

	; found a line feed, send it differently
handleLF:
	call	SendLineFeed	; send our line feed distance.
	jnc	nextByte	; if no error....
exitErr:
	pop	cx		; restore stack
	jmp	exit		; all done
PrintText	endp

