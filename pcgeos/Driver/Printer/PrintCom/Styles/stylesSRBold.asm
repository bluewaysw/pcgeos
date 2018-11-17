
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Print Drivers
FILE:		stylesSRBold.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/21/92		Initial revision from epson24Styles.asm


DC_ESCRIPTION:
		
	$Id: stylesSRBold.asm,v 1.1 97/04/18 11:51:45 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetBold		proc	near
	mov	si,offset cs:pr_codes_SetBold
	jmp	SendCodeOut
SetBold		endp

ResetBold	proc	near
	mov	si,offset cs:pr_codes_ResetBold
	jmp	SendCodeOut
ResetBold	endp
