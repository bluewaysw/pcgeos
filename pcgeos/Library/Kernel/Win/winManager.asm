COMMENT }-------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		Windowing system
FILE:		winManager.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	5/88...		Initial version
	Doug	10/12/88	Changed files to win* from user*

DESCRIPTION:
	This file assembles the windowing system code

	$Id: winManager.asm,v 1.1 97/04/05 01:16:21 newdeal Exp $

----------------------------------------------------------------------------}

include kernelGeode.def

;--------------------------------------
;	Include files
;--------------------------------------

include graphics.def
include win.def			;includes: graphics.def
include lmem.def
include timer.def
include sem.def
include timedate.def
include Objects/processC.def		;includes: object.def, metaClass.def
include Objects/winC.def

include Internal/gstate.def
include Internal/grWinInt.def
include Internal/window.def		;inclides: tmatrix.def
include Internal/interrup.def
include Internal/geodeStr.def		;includes: geode.def
include Internal/im.def
UseDriver Internal/videoDr.def

;--------------------------------------

include winMacro.def		;WIN macros
include winConstant.def		;WIN constants

;-------------------------------------

include winVariable.def

;-------------------------------------

kcode	segment
include	winCreDest.asm
include winWindows.asm
include winIndividual.asm
include winState.asm
include winUtils.asm
include winTrans.asm
include	winNotification.asm
include	winGeode.asm
kcode	ends

include	winC.asm

;-------------------------------------

kinit	segment
include winInit.asm
kinit	ends

end
