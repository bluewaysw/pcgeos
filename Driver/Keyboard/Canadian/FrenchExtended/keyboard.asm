COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC/GEOS
FILE:		keyboard.asm

AUTHOR:		Gene Anderson, Jul  8, 1991

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	7/ 8/91		Initial revision

DESCRIPTION:
	Manager file for keyboard driver

	$Id: keyboard.asm,v 1.1 97/04/18 11:47:22 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include keyboardGeode.def
include keyboardConstant.def

idata	segment
;
; number of accentables (1 extra for Candians)
;
_NUM_ACCENTABLES	equ	KBD_NUM_ACCENTABLES+1
include	kmapCanadianExt.def
idata	ends

include keyboardVariable.def

include keyboardHotkey.asm
include keyboardInit.asm
include keyboardProcess.asm
include keyboardUtils.asm


KbdExtendedInfoSeg	segment	lmem LMEM_TYPE_GENERAL

DriverExtendedInfoTable <
	{},
	length kbdNameTable,
	offset kbdNameTable,
	0
>

kbdNameTable	lptr.char	kbdStr
		lptr.char	0

kbdStr	chunk.char "French Canadian Keyboard",0

KbdExtendedInfoSeg	ends


end
