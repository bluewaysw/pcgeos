COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		os2Strings.asm

AUTHOR:		Adam de Boor, Mar 11, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	3/11/92		Initial revision


DESCRIPTION:
	Strings specific to the OS/2 IFS Driver.
		

	$Id: os2Strings.asm,v 1.1 97/04/10 11:55:19 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DriverExtendedInfo	segment	lmem LMEM_TYPE_GENERAL
DriverExtendedInfoTable	<
		{},			; lmem header added by Esp
		length fsNameTable,	; Number of supported "devices"
		offset fsNameTable,	; Names of supported "devices"
		offset fsInfoTable	; FSDFlags
>

fsNameTable	lptr.char	os2
		lptr.char 	0	; terminate table
os2	chunk.char	"OS/2 2.0", 0

fsInfoTable	word	FSD_FLAGS	; os2
DriverExtendedInfo	ends

