COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Text Library
FILE:		Ruler/rulerManager.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/91		Initial version

DESCRIPTION:

	$Id: rulerManager.asm,v 1.1 97/04/07 11:19:47 newdeal Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			Common GEODE stuff
;------------------------------------------------------------------------------

include textGeode.def

;---

DefLib Objects/Text/tCtrlC.def

include Internal/im.def
include win.def

include rulerConstant.def

;------------------------------------------------------------------------------
;		Resource definitions
;------------------------------------------------------------------------------

include rulerManager.rdef

	ForceRef LeftMarginCursor
	ForceRef ParaMarginCursor
	ForceRef LeftParaMarginCursor
	ForceRef RightMarginCursor
	ForceRef LeftTabCursor
	ForceRef CenterTabCursor
	ForceRef RightTabCursor
	ForceRef AnchoredTabCursor
	ForceRef DeleteTabCursor

;------------------------------------------------------------------------------
;			Code
;------------------------------------------------------------------------------

include rulerClass.asm
include rulerDraw.asm
include rulerMouse.asm
