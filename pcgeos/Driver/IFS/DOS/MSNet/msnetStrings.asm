COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		netwareStrings.asm

AUTHOR:		Adam de Boor, Mar 29, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	3/29/92		Initial revision


DESCRIPTION:
	Strings specific to the Novell NetWare IFS Driver.
		

	$Id: msnetStrings.asm,v 1.1 97/04/10 11:55:26 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DriverExtendedInfo	segment	lmem LMEM_TYPE_GENERAL
DriverExtendedInfoTable	<
		{},			; lmem header added by Esp
		length fsNameTable,	; Number of supported "devices"
		offset fsNameTable,	; Names of supported "devices"
		offset fsInfoTable	; FSDFlags
>

fsNameTable	lptr.char	lantast40,
				nwlite1x,
				lantast41,
				msnetCompat
		lptr.char 	0	; terminate table
lantast40	chunk.char	"LANtastic 4.0", 0
lantast41	chunk.char	"LANtastic 4.1", 0
nwlite1x	chunk.char	"NetWare Lite 1.x", 0
msnetCompat	chunk.char	"MS-Net Compatible", 0

fsInfoTable	word	FSD_FLAGS,	; lantast40
			FSD_FLAGS,	; nwlite1x
			FSD_FLAGS,	; lantast41
			FSD_FLAGS	; msnetCompat
DriverExtendedInfo	ends

