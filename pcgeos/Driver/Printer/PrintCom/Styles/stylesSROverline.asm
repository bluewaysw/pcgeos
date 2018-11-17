
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Print Drivers
FILE:		stylesSROverline.asm

AUTHOR:		Dave Durran, 1 March 1990

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	8/18/92		Initial revision


DC_ESCRIPTION:
		
	$Id: stylesSROverline.asm,v 1.1 97/04/18 11:51:45 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetOverline	proc	near
	mov	si,offset cs:pr_codes_SetOverline
	jmp	SendCodeOut
SetOverline	endp

ResetOverline	proc	near
	mov	si,offset cs:pr_codes_ResetOverline
	jmp	SendCodeOut
ResetOverline	endp
