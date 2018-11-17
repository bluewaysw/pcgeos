
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Print Drivers
FILE:		stylesSRCondensed.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/21/92		Initial revision from epson24Styles.asm


DC_ESCRIPTION:
		
	$Id: stylesSRCondensed.asm,v 1.1 97/04/18 11:51:46 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetCondensed	proc	near
	mov	si, offset cs:pr_codes_SetCondensed
	jmp	SendCodeOut
SetCondensed	endp

ResetCondensed	proc	near
	mov	si,offset cs:pr_codes_ResetCondensed
	jmp	SendCodeOut
ResetCondensed	endp

