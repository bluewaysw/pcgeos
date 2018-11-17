
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Print Driver
FILE:		stylesSRShadow.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/1/90		Initial revision


DC_ESCRIPTION:
		
	$Id: stylesSRShadow.asm,v 1.1 97/04/18 11:51:48 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetShadow	proc	near
	mov	si,offset cs:pr_codes_SetShadow
	jmp	SendCodeOut
SetShadow	endp

ResetShadow	proc	near
	mov	si,offset cs:pr_codes_ResetShadow
	jmp	SendCodeOut
ResetShadow	endp
