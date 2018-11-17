
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Print Driver
FILE:		stylesSROutline.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	6/92		Initial revision


DESCRIPTION:
		
	$Id: stylesSROutline.asm,v 1.1 97/04/18 11:51:50 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetOutline	proc	near
	mov	si,offset cs:pr_codes_SetOutline
	jmp	SendCodeOut
SetOutline	endp

ResetOutline	proc	near
	mov	si,offset cs:pr_codes_ResetOutline
	jmp	SendCodeOut
ResetOutline	endp
