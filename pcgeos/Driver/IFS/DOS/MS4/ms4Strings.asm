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
		

	$Id: ms4Strings.asm,v 1.1 97/04/10 11:54:55 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DriverExtendedInfo	segment	lmem LMEM_TYPE_GENERAL
DriverExtendedInfoTable	<
		{},			; lmem header added by Esp
		length fsNameTable,	; Number of supported "devices"
		offset fsNameTable,	; Names of supported "devices"
		offset fsInfoTable	; FSDFlags
>

fsNameTable	lptr.char	ms4_00,
				ms4_01,
				pc4_00,
				pc4_01
		lptr.char 	0	; terminate table
LocalDefString ms4_00	<"MS-DOS 4.0", 0>
LocalDefString ms4_01	<"MS-DOS 4.01", 0>
LocalDefString pc4_00	<"PC-DOS 4.0", 0>
LocalDefString pc4_01	<"PC-DOS 4.01", 0>

fsInfoTable	word	FSD_FLAGS,	; ms4_00
			FSD_FLAGS,	; ms4_01
			FSD_FLAGS,	; pc4_00
			FSD_FLAGS	; pc4_01
DriverExtendedInfo	ends

