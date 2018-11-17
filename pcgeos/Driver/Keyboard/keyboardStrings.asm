COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		keyboardStrings.asm

AUTHOR:		Gene Anderson, Jan  4, 1991

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	1/ 4/91		Initial revision

	$Id: keyboardStrings.asm,v 1.1 97/04/18 11:47:07 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

KbdExtendedInfoSeg	segment	lmem LMEM_TYPE_GENERAL

DriverExtendedInfoTable <
	{},
	length kbdNameTable,
	offset kbdNameTable,
	0
>

kbdNameTable	lptr.char	usKbdStr
		lptr.char	0

LocalDefString usKbdStr	<"U.S. Keyboard",0>

KbdExtendedInfoSeg	ends
