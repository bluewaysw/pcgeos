
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Print Drivers
FILE:		stylesSRStrikeThru.asm

AUTHOR:		Dave Durran, 1 March 1990

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/1/90		Initial revision


DC_ESCRIPTION:
		
	$Id: stylesSRStrikeThru.asm,v 1.1 97/04/18 11:51:48 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetStrikeThru	proc	near
	mov	si,offset cs:pr_codes_SetStrikeThru
	jmp	SendCodeOut
SetStrikeThru	endp

ResetStrikeThru	proc	near
	mov	si,offset cs:pr_codes_ResetStrikeThru
	jmp	SendCodeOut
ResetStrikeThru	endp
