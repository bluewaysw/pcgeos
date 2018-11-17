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
		

	$Id: netwareStrings.asm,v 1.1 97/04/10 11:55:16 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DriverExtendedInfo	segment	lmem LMEM_TYPE_GENERAL
DriverExtendedInfoTable	<
		{},			; lmem header added by Esp
		length fsNameTable,	; Number of supported "devices"
		offset fsNameTable,	; Names of supported "devices"
		offset fsInfoTable	; FSDFlags
>

fsNameTable	lptr.char	netware3_11,
				netware3_12
		lptr.char 	0	; terminate table
netware3_11	chunk.char	"Novell NetWare 3.11", 0
netware3_12	chunk.char	"Novell NetWare 3.12", 0

fsInfoTable	word	FSD_FLAGS,	; netware3_11
			FSD_FLAGS	; netware3_12


attachedAsGuest	chunk.char	"Now attached as GUEST to server", 0
DriverExtendedInfo	ends

