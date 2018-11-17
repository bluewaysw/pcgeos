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

	$Id: keyboard.asm,v 1.1 97/04/18 11:47:04 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifndef	HARDWARE_TYPE
HARDWARE_TYPE		equ	<PC>
endif

include keyboardGeode.def
include keyboardConstant.def

idata	segment
_NUM_ACCENTABLES	equ	KBD_NUM_ACCENTABLES

if DBCS_PCGEOS
include	kmapUSDBCS.def
else
include	kmapUS.def
endif
idata	ends

include keyboardVariable.def
include keyboardStrings.asm

include keyboardHotkey.asm
include keyboardInit.asm
include keyboardProcess.asm
include keyboardUtils.asm

end
