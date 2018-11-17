COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Kernel/Initfile
FILE:		initfileEC.asm

AUTHOR:		Cheng, 11/89

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	11/89		Initial revision

DESCRIPTION:
	Entire file contains error checking code.
		
	$Id: initfileEC.asm,v 1.1 97/04/05 01:17:59 newdeal Exp $

-------------------------------------------------------------------------------@

if	ERROR_CHECK
InitfileRead	segment	resource

IFCheckDgroupRegs	proc	far
	push	ax, bx
	mov	ax, dgroup
	cmp	ax, bp
	ERROR_NZ	INIT_FILE_BAD_BP
	mov	bx, es
	cmp	ax, bx
	ERROR_NZ	INIT_FILE_BAD_ES
	pop	ax, bx
	ret
IFCheckDgroupRegs	endp

IFCheckDgroupDS	proc	far
	push	ax, bx
	mov	ax, dgroup
	mov	bx, ds
	cmp	ax, bx
	ERROR_NE	INIT_FILE_BAD_DS
	pop	ax, bx
	ret
IFCheckDgroupDS	endp

InitfileRead	ends
endif
