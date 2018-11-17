
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Print Drivers
FILE:		stylesSRItalic.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/21/92		Initial revision from epson24Styles.asm


DC_ESCRIPTION:
		
	$Id: stylesSRItalic.asm,v 1.1 97/04/18 11:51:47 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetItalic	proc	near
	mov	si,offset cs:pr_codes_SetItalic
	jmp	SendCodeOut
SetItalic	endp

ResetItalic	proc	near
	mov	si,offset cs:pr_codes_ResetItalic
	jmp	SendCodeOut
ResetItalic	endp
