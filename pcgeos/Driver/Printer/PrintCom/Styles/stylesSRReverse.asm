
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Print Driver
FILE:		stylesSRReverse.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave 	6/92		Initial revision


DESCRIPTION:
		
	$Id: stylesSRReverse.asm,v 1.1 97/04/18 11:51:50 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetReverse	proc	near
	mov	si,offset cs:pr_codes_SetReverse
	jmp	SendCodeOut
SetReverse	endp

ResetReverse	proc	near
	mov	si,offset cs:pr_codes_ResetReverse
	jmp	SendCodeOut
ResetReverse	endp
