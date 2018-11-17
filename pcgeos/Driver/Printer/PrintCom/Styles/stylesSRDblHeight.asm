
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Print Drivers
FILE:		stylesSRDblHeight.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/21/92		Initial revision from epson24Styles.asm


DC_ESCRIPTION:
		
	$Id: stylesSRDblHeight.asm,v 1.1 97/04/18 11:51:46 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetDblHeight	proc	near
	mov	si,offset cs:pr_codes_SetDblHeight
	jmp	SendCodeOut
SetDblHeight	endp

ResetDblHeight	proc	near
	mov	si,offset cs:pr_codes_ResetDblHeight
	jmp	SendCodeOut
ResetDblHeight	endp
