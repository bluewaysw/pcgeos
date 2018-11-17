COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		genpcMain.asm

AUTHOR:		Todd Stumpf, Apr 30, 1996

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	4/30/96   	Initial revision


DESCRIPTION:
	
		

	$Id: genpcMain.asm,v 1.1 97/04/04 18:04:02 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

		.186

include	geos.def
include	geode.def
include	library.def
include	resource.def
include	object.def
include Internal/interrup.def
include initfile.def
include Internal/powerDr.def

UseLib Internal/kbdMap.def

DefLib	gdi.def

include	genpcConstant.def
if DBCS_PCGEOS
include	genpcConfigDBCS.def
else
include	genpcConfig.def
endif
include	genpcVariable.def
include genpcMacro.def

include ../Common/gdiConstant.def
include ../Common/gdiVariable.def

include	../Common/gdiPointer.asm
include ../Common/gdiKeyboard.asm
include ../Common/gdiPower.asm
include ../Common/gdiExt.asm
include ../Common/gdiUtils.asm

include genpcMouse.asm
include	genpcKbd.asm
include genpcPwr.asm




