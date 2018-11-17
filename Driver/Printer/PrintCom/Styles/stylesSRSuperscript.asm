
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Print Driver
FILE:		stylesSRSuperscript.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	5/92		Parsed from oki9Styles.asm


DC_ESCRIPTION:
		
	$Id: stylesSRSuperscript.asm,v 1.1 97/04/18 11:51:49 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetSuperscript	proc	near
	mov	si,offset cs:pr_codes_SetSuperscript
	jmp	SendCodeOut
SetSuperscript	endp
	
ResetSuperscript proc	near
	mov	si,offset cs:pr_codes_ResetSuperscript
	jmp	SendCodeOut
ResetSuperscript	endp
