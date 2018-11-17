COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoCalc
FILE:		rulerManager.asm

AUTHOR:		Gene Anderson, Jun 13, 1991

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	6/13/91		Initial revision

DESCRIPTION:
	

	$Id: rulerManager.asm,v 1.1 97/04/07 10:42:40 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;------------------------------------------------------------------------------
;			common include files
;------------------------------------------------------------------------------

include geos.def
include ec.def
include library.def
include lmem.def
include vm.def
include system.def
include resource.def
include	geode.def
include heap.def
include initfile.def

;------------------------------------------------------------------------------
;			stuff we need
;------------------------------------------------------------------------------

include char.def
include graphics.def
include geoworks.def
include Internal/prodFeatures.def

;------------------------------------------------------------------------------
;			library stuff
;------------------------------------------------------------------------------

UseLib	ui.def
DefLib	ruler.def

;------------------------------------------------------------------------------
;			Classes
;------------------------------------------------------------------------------

RulerClassStructures	segment resource

	VisRulerClass		;declare the class record
	RulerContentClass
	RulerViewClass
	RulerTypeControlClass
	GuideCreateControlClass
	RulerGuideControlClass
	RulerGridControlClass

RulerClassStructures	ends

;------------------------------------------------------------------------------
;			Definitions
;------------------------------------------------------------------------------

include	rulerConstant.def
include rulerMacro.def

;------------------------------------------------------------------------------
;			Code
;------------------------------------------------------------------------------

if not NO_CONTROLLERS
;
; if NO_CONTROLLERS, there is no resource left in ui files.
; -- kho, July 19. 1995
;
include ruler.rdef
endif

include rulerTables.asm
include rulerDraw.asm
include rulerUtils.asm
include rulerGrid.asm
include rulerGuide.asm
include rulerConstrain.asm
include	rulerMethods.asm
include rulerContent.asm
include rulerView.asm
include rulerSelect.asm
include rulerC.asm

;
;	Controller code
;
if not NO_CONTROLLERS
include uiControlCommon.asm
include uiRulerTypeControl.asm
include uiGuideCreateControl.asm
include uiRulerGuideControl.asm
include uiGridSpacingControl.asm
endif

include uiRulerShow.asm
