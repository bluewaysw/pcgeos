COMMENT @----------------------------------------------------------------------

	Copyright (c) Geoworks 1992-1994 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		Studio
FILE:		Document/documentManager.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/92		Initial version

DESCRIPTION:
	This file contains the document class for the
	Studio application.

	$Id: documentManager.asm,v 1.1 97/04/04 14:39:26 newdeal Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			Common GEODE stuff
;------------------------------------------------------------------------------

include studioGeode.def
include studioConstant.def
include studioDocument.def
include studioApplication.def
include studioDisplay.def
include studioProcess.def

include system.def
include gstring.def
include library.def
include timedate.def	; for TimerGetDateAndTime

include Internal/grWinInt.def
UseLib Internal/convert.def

UseLib Objects/styles.def
UseLib Objects/vTextC.def
UseLib Objects/Text/tCtrlC.def
UseLib compress.def
UseLib helpFile.def

UseLib math.def			; Need definition for ssheet.def
UseLib cell.def			; Need definition for ssheet.def
UseLib parse.def		; Need definition for ssheet.def
UseLib ssheet.def		; Need definition of cell structure

include studioArticle.def
include studioGrObjHead.def
include studioGrObjBody.def
include studioHdrFtr.def

include flowRegion.def

;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------

include documentManager.rdef

; HACK HERE!
; Define the rest of the header for MasterPageTempUI since we can't define it
; in uic

MasterPageTempUI segment
	word	0		;MPBH_header
	word	0		;MPBH_footer
	MasterPageFlags	<>	;MPBH_flags
	byte	32 dup (?)	;MPBH_reserved
MasterPageTempUI ends

BodyRulerTempUI segment
	word	0		;GOBBH_mainGrObjBlock
BodyRulerTempUI ends

	ForceRef CharAttrElements
	ForceRef ParaAttrElements
	ForceRef MParaAttrElements
	ForceRef TextStyleArray
	ForceRef GraphicElements
	ForceRef TypeElements
	ForceRef NameElements

;------------------------------------------------------------------------------
;			Code
;------------------------------------------------------------------------------

include documentData.asm

include documentDocument.asm
include documentOpenClose.asm
include documentContent.asm		;must come before documentSection.asm
include documentArticle.asm
include documentSection.asm
include documentPage.asm
include documentDraw.asm
include documentManip.asm
include documentUtils.asm
include documentFlow.asm
include documentFrame.asm
include documentNotify.asm
include documentMisc.asm

include documentPrint.asm
include documentMerge.asm
include documentMergeScrap.asm

include documentHead.asm
include documentAttrMgr.asm
include documentBody.asm
include documentHdrFtr.asm
include documentUserSection.asm
include documentPageSetup.asm
include documentRegion.asm
include documentMasterPage.asm
include documentDisplay.asm
include documentScroll.asm
include documentImpex.asm
include documentVariable.asm
include documentConvert.asm
include documentHelp.asm
include documentSearchSp.asm
