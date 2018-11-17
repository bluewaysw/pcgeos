COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		rfsdStrings.asm

AUTHOR:		In Sik Rhee, Apr 23, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	4/23/92		Initial revision


DESCRIPTION:
	Strings for RFS Driver
		

	$Id: rfsdStrings.asm,v 1.1 97/04/18 11:46:14 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DriverExtendedInfo	segment	lmem LMEM_TYPE_GENERAL
DriverExtendedInfoTable	<
		{},			; lmem header added by Esp
		length fsNameTable,	; Number of supported "devices"
		offset fsNameTable,	; Names of supported "devices"
		offset fsInfoTable	; FSDFlags
>

fsNameTable	lptr.char	rfsd_10
		lptr.char 	0	; terminate table
rfsd_10	chunk.char	"Remote File Server v1.0", 0

fsInfoTable	word	FSD_FLAGS	; rfsd_10
DriverExtendedInfo	ends

Strings	segment	lmem	LMEM_TYPE_GENERAL
LostConnectionError	chunk.char "The connection to the remote machine was broken.",0
Strings	ends
