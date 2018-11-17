COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	(c) Copyright Geoworks 1996.  All rights reserved.
			GEOWORKS CONFIDENTIAL

PROJECT:	
MODULE:		
FILE:		ms7Strings.asm

AUTHOR:		Jim Wood, Dec 17, 1996

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimw	12/17/96   	Initial revision


DESCRIPTION:
		
	

	$Id: ms7Strings.asm,v 1.1 97/04/10 11:55:41 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DriverExtendedInfo	segment	lmem LMEM_TYPE_GENERAL
DriverExtendedInfoTable	<
		{},			; lmem header added by Esp
		length fsNameTable,	; Number of supported "devices"
		offset fsNameTable,	; Names of supported "devices"
		offset fsInfoTable	; FSDFlags
>

fsNameTable	lptr.char	ms7_00
		lptr.char 	0	; terminate table
LocalDefString ms7_00	<"MS-DOS 7.0", 0>

fsInfoTable	word	FSD_FLAGS	; ms7b_00
DriverExtendedInfo	ends
