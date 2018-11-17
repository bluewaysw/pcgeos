COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		driStrings.asm

AUTHOR:		Adam de Boor, Mar 11, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	3/11/92		Initial revision


DESCRIPTION:
	Strings specific to the DR DOS IFS Driver.
		

	$Id: ms3Strings.asm,v 1.1 97/04/10 11:54:57 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DriverExtendedInfo	segment	lmem LMEM_TYPE_GENERAL
DriverExtendedInfoTable	<
		{},			; lmem header added by Esp
		length fsNameTable,	; Number of supported "devices"
		offset fsNameTable,	; Names of supported "devices"
		offset fsInfoTable	; FSDFlags
>

fsNameTable	lptr.char	ms3_30
		lptr.char 	0	; terminate table
ms3_30	chunk.char	"MS-DOS 3.3", 0

fsInfoTable	word	FSD_FLAGS	; ms3_30
DriverExtendedInfo	ends

