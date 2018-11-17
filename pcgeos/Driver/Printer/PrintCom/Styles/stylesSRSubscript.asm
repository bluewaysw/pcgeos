
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Print Driver
FILE:		stylesSRSubscript.asm

AUTHOR:		Jim DeFrisco, 1 March 1990

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	3/1/90		Initial revision
	Dave	5/21/92		Parsed from oki9Styles.asm


DC_ESCRIPTION:
		
	$Id: stylesSRSubscript.asm,v 1.1 97/04/18 11:51:48 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetSubscript	proc	near
	mov	si,offset cs:pr_codes_SetSubscript
	jmp	SendCodeOut
SetSubscript	endp

ResetSubscript	proc	near
	mov	si,offset cs:pr_codes_ResetSubscript
	jmp	SendCodeOut
ResetSubscript	endp
