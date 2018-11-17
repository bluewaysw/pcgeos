
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		iwriter 9-pin Print Driver
FILE:		iwriter9Styles.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dave	3/1/90		Initial revision


DC_ESCRIPTION:
	This file contains all the style setting routines for the iwriter 9-pin
	driver.
		
	$Id: iwriter9Styles.asm,v 1.1 97/04/18 11:53:39 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintSendFont
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send the right stuff to set the font in the printer

CALLED BY:	INTERNAL
		PrintSetFont

PASS:		es,bp	- PState segment

RETURN:		carry	- set if some communications error

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	01/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintSendFont	proc	near
		uses	si
		.enter

		mov	si, offset cs:pr_codes_SetProportional 
		cmp	es:[PS_curFont].FE_fontID, FONT_PRINTER_PROP_SERIF
		je	sendTheFont
		mov	si, offset cs:pr_codes_Set12Pitch ; check the next one
		cmp	es:[PS_curFont].FE_fontID, FONT_PRINTER_12CPI ;
		je	sendTheFont
		mov	si, offset cs:pr_codes_Set10Pitch ; assume it's 10CPI
		cmp	es:[PS_curFont].FE_fontID, FONT_PRINTER_10CPI ;
		je	sendTheFont

		; must be one of the condensed fonts.  First set the font, then
		; the condensed bit

		mov	si, offset cs:pr_codes_Set10Pitch ; assume it's 17cpi
		cmp	es:[PS_curFont].FE_fontID, FONT_PRINTER_17CPI ;
		je	setCondensedFont		; 17 = 10cpi condensed
		mov	si, offset cs:pr_codes_Set12Pitch ; it must 20
setCondensedFont:
		call	SendCodeOut			; set it at printer
		jc	exit
		or	es:[PS_xtraStyleInfo], mask PMF_FORCE_CONDENSED
		or	es:[PS_asciiStyle], mask TS_CONDENSED ; set condensed
		call	SetCondensed
		jmp	exit				; exit if comm error
sendTheFont:
		call	SendCodeOut			; set it at printer
exit:
		.leave
		ret
PrintSendFont	endp


;-----------------------------------------------------------------------
;               Jump Tables for setting text styles
;-----------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetXXXXXX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a text style

CALLED BY:	INTERNAL
		SetStyle

PASS:		--

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetCondensed	proc	near
	mov	si, offset cs:pr_codes_SetCondensed
	jmp	SendCodeOut
SetCondensed	endp

SetSubscript	proc	near
	mov	si,offset cs:pr_codes_SetSubscript
	jmp	SendCodeOut
SetSubscript	endp

SetSuperscript	proc	near
	mov	si,offset cs:pr_codes_SetSuperscript
	jmp	SendCodeOut
SetSuperscript	endp

SetNLQ		proc	near
	mov	si,offset cs:pr_codes_SetNLQ
	jmp	SendCodeOut
SetNLQ		endp

SetBold		proc	near
	mov	si,offset cs:pr_codes_SetBold
	jmp	SendCodeOut
SetBold		endp

SetUnderline	proc	near
	mov	si,offset cs:pr_codes_SetUnderline
	jmp	SendCodeOut
SetUnderline	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResetXXXX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset print sylte routines

CALLED BY:	GLOBAL

PASS:		bp,ds,es = PState segment

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ResetCondensed	proc	near

	; the set condensed printer code on the CItoh9 is a pitch setting
	; code (ie, we switch fonts).  So we need to check the font in
	; the pstate and set the font back to what it was before we set
	; condensed mode.

	; OK, we need to set the printer back to what it was.  We will test
	; either the serif font or the 12CPI font

	mov	si, offset cs:pr_codes_SetProportional 
	cmp	es:[PS_curFont].FE_fontID, FONT_PRINTER_PROP_SERIF
	je	sendTheFont
	mov	si, offset cs:pr_codes_Set12Pitch ; check the next one
	cmp	es:[PS_curFont].FE_fontID, FONT_PRINTER_12CPI ;chk ass
	je	sendTheFont

	; If here, then it must be either 10pitch, 17pitch, or some unsupported
	; pitch which we will set to 10-pitch anyway.

	mov	si, offset cs:pr_codes_Set10Pitch ; check the next one
	;cmp	ds:[PS_curFont].FE_fontID, FONT_PRINTER_10CPI ; ok ?
	;je	sendTheFont
	;cmp	ds:[PS_curFont].FE_fontID, FONT_PRINTER_17CPI ; this needs 10cpi
	;je	sendTheFont
	;cmp	es:[PS_curFont].FE_fontID, FONT_PRINTER_20CPI ;chk ass

sendTheFont:
	call	SendCodeOut
exit:
	ret

ResetCondensed	endp

ResetSubscript	proc	near
ResetSuperscript label	near
	mov	ds, bp		;obtain the PSTATE segment.
	test	ds:[PS_asciiStyle],(mask TS_SUBSCRIPT) or (mask TS_SUPERSCRIPT)
	jne	Skip		;skip cancellation, if one is present in new 
				;ASCII Style word.
	mov	si,offset cs:pr_codes_ResetScript
	jmp	SendCodeOut
Skip:
	ret
ResetSubscript	endp


ResetNLQ	proc	near
	mov	si,offset cs:pr_codes_ResetNLQ
	jmp	SendCodeOut
ResetNLQ	endp

ResetBold	proc	near
	mov	si,offset cs:pr_codes_ResetBold
	jmp	SendCodeOut
ResetBold	endp

ResetUnderline	proc	near
	mov	si,offset cs:pr_codes_ResetUnderline
	jmp	SendCodeOut
ResetUnderline	endp


SetStrikeThru	proc	near
SetItalic	label	near
SetShadow	label	near
SetOutline	label	near
SetReverse	label	near
SetDblWidth	label	near
SetDblHeight	label	near
SetQuadHeight	label	near
SetFuture	label	near
ResetStrikeThru	label	near
ResetItalic	label	near
ResetShadow	label	near
ResetOutline	label	near
ResetReverse	label	near
ResetDblWidth	label	near
ResetDblHeight	label	near
ResetQuadHeight	label	near
ResetFuture	label	near
	clc			;screen off any bogus errors.
	ret
SetStrikeThru	endp

