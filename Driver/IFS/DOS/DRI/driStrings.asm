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
		

	$Id: driStrings.asm,v 1.1 97/04/10 11:54:53 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DriverExtendedInfo	segment	lmem LMEM_TYPE_GENERAL
DriverExtendedInfoTable	<
		{},			; lmem header added by Esp
		length fsNameTable,	; Number of supported "devices"
		offset fsNameTable,	; Names of supported "devices"
		offset fsInfoTable	; FSDFlags
>

fsNameTable	lptr.char	dri3_40,
				dri3_41,
				dri5_0,
				dri6_0
		lptr.char 	0	; terminate table
dri3_40	chunk.char	"DR DOS 3.40", 0
dri3_41	chunk.char	"DR DOS 3.41", 0
dri5_0	chunk.char	"DR DOS 5.0", 0
dri6_0	chunk.char	"DR DOS 6.0", 0

fsInfoTable	word	FSD_FLAGS,	; dri3_40
			FSD_FLAGS,	; dri3_41
			FSD_FLAGS,	; dri5_0
			FSD_FLAGS	; dri6_0
DriverExtendedInfo	ends

