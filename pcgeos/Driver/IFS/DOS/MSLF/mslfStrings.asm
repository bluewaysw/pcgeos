COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GlobalPC 1999.  All rights reserved.
	GLOBALPC CONFIDENTIAL

PROJECT:	Global PC
MODULE:		MS DOS Longname IFS Driver
FILE:		mslfStrings.asm

AUTHOR:		Allen Yuen, Jan 21, 1999

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	1/21/99   	Initial revision


DESCRIPTION:
		
	Strings specific to the MS DOS Longname IFS Driver.

	$Id$

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

fsInfoTable	word	FSD_FLAGS	; ms7_00
DriverExtendedInfo	ends

