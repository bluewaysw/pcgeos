COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer Drivers
FILE:		textSetFont.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------
	PrintSetFont		Set a new text mode font

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	3/1/90		Initial revision
	Dave	3/92		Moved in a bunch of common test routines
	Dave	5/92		Parsed up printcomText.asm


DESCRIPTION:

	$Id: textSetFont.asm,v 1.1 97/04/18 11:49:58 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintSetFont
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a new font for text mode

CALLED BY: 	GLOBAL

PASS: 		bp	- Segment of PSTATE	
		bl	- desired pitch value (0 for proportional)
		cx	- desired font ID
		dx	- desired font size (points)

RETURN: 	nothing

DESTROYED: 	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	02/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintSetFont	proc	far
	uses	ax,bx,cx,dx,si,di,es,ds
	.enter
	mov	es,bp			; get the PSTATE segment to es.
	call	PrintClearStyles
	jc	exit
	push	bx			; save the pitch
	mov	bx,es:[PS_deviceInfo] 	; handle to info for this printer.
	call	MemLock
	mov	ds,ax			; ds points at device info segment.
	mov	al,es:[PS_mode]		; index into device table for this mode.
	clr	ah
	mov	si, ax
	cmp	si, PM_FIRST_TEXT_MODE 	;  must be a text mode
	jae	weAreInTextMode		
	mov	si, PM_TEXT_NLQ 	;  must force a text mode.....
					; use one that all drivers possess.
					; IMPORTANT FOR END OF PAGE STUFF
					; (PrintSetCursor is called)
weAreInTextMode:
	pop	bx			;get back the pitch in bl
	call	SpoolMapToPrinterFont
	mov	si,ds:[PI_firstMode][si] ; get pointer to group of font entries.
	tst	si			;  check for mode not supported
	jz	done
	push	bx			;save pitch
	mov	bx,handle printerFontInfo ;get the handle of the font block
	call	MemLock
	mov	ds,ax			;get segment into ds
	pop	bx
	mov	di, si			; keep the table pointer in di
	mov	ax, si			; save it here too for default font

fontLoop:
	mov	si,ds:[di]		; si -> FontEntry
	tst	si			; check for end of table
	jz	loadFirstFont
	cmp	ds:[si].FE_fontID, cx	; see if fontID matches
	jne	tryNextEntry
	cmp	ds:[si].FE_pitch, bl	; see if pitch matches
	jne	tryNextEntry
	cmp	ds:[si].FE_size, dx	; see if point size matches
	je	loadFont		;  yes, use it

tryNextEntry:
	add	di,2
	jmp	fontLoop

	; we didn't find any fonts that matched, so use the default font.  It
	; is (by definition) the first font in the table.
loadFirstFont:
	mov	si, ax
	mov	si,ds:[si] 	; get pointer to group of font entries.

	; we have a font.  si points to it.  So move it to the pstate.
loadFont: 				
	mov	dx,es:[PS_curFont].FE_symbolSet	;save old char set enum
	mov	di,offset PS_curFont	 ;point at destination in PSTATE.
if ((SIZE FontEntry)and 1)
	mov	cx, SIZE FontEntry
	rep	movsb
else
	mov	cx, (SIZE FontEntry)/2
	rep	movsw
endif

	mov	bx,handle printerFontInfo ;get the handle of the font block
	call	MemUnlock

	call	PrintSetSymbolSet	;set the symbol set in hi ASCII space
					;based on the job paramenters setting
					;from the UI dialogs.

		;see if the symbol set changed with the last change in fonts.
	cmp	dx,es:[PS_curFont].FE_symbolSet
	je	haveSymbolSet		;if not, then don't bother
					;re-loading it into the PState.
	call	PrintLoadSymbolSet	;call printer specific ASCII table
	jc	exitErr			;and country setting routine.
haveSymbolSet:

	; now REALLY set the font by letting the printer know...
	mov	si,es:[PS_curFont].[FE_command] ;load the offset to the 
						;font setting command string
	call	SendCodeOut		; set the font at the printer
	jc	exitErr
	mov	dx,0			;make sure that mandatory styles get
	call	PrintSetStyles		;set
	jc	exitErr

	; all done, unlock the block and leave
done:
	mov	bx,es:[PS_deviceInfo] 	; handle to info for this printer.
	call	MemUnlock	; unlock the puppy
	clc

exit:
	.leave
	ret

	; exit if there was some communications error
exitErr:
	mov	bx,es:[PS_deviceInfo] 	; handle to info for this printer.
	call	MemUnlock	; unlock the puppy
	stc			; indicate error
	jmp	exit
PrintSetFont	endp
