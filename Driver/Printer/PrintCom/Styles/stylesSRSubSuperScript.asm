
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Print Drivers
FILE:		stylesSRSubSuperScript.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/21/92		Initial revision from epson24Styles.asm


DC_ESCRIPTION:
		
	$Id: stylesSRSubSuperScript.asm,v 1.1 97/04/18 11:51:48 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetSubscript	proc	near
	mov	si,offset cs:pr_codes_SetSubscript
	jmp	SendCodeOut
SetSubscript	endp

SetSuperscript	proc	near
	mov	si,offset cs:pr_codes_SetSuperscript
	jmp	SendCodeOut
SetSuperscript	endp

ResetSubscript	proc	near
ResetSuperscript label	near
	test	es:[PS_asciiStyle],(mask TS_SUBSCRIPT) or (mask TS_SUPERSCRIPT)
	jne	Skip		;skip cancellation, if one is present in new 
				;ASCII Style word.
	mov	si,offset cs:pr_codes_ResetScript
	jmp	SendCodeOut
Skip:
	ret
ResetSubscript	endp
