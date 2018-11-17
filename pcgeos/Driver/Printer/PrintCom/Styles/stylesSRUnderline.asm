
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Print Drivers
FILE:		stylesSRUnderline.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/21/92		Initial revision from epson24Styles.asm


DC_ESCRIPTION:
		
	$Id: stylesSRUnderline.asm,v 1.1 97/04/18 11:51:49 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetUnderline	proc	near
	mov	si,offset cs:pr_codes_SetUnderline
	jmp	SendCodeOut
SetUnderline	endp

ResetUnderline	proc	near
	mov	si,offset cs:pr_codes_ResetUnderline
	jmp	SendCodeOut
ResetUnderline	endp
