COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoWrite
FILE:		Document/documentManager.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/92		Initial version

DESCRIPTION:
	This file contains the document class for the
	GeoWrite application.

	$Id: documentManager.asm,v 1.1 97/04/04 15:56:09 newdeal Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			Common GEODE stuff
;------------------------------------------------------------------------------

include writeGeode.def
include writeConstant.def
include writeDocument.def
include writeApplication.def
include writeDisplay.def

include system.def
include gstring.def
include library.def
include timedate.def		; for TimerGetDateAndTime
include initfile.def

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

include writeArticle.def
include writeGrObjHead.def
include writeGrObjBody.def
include writeHdrFtr.def

include flowRegion.def

include pageInfo.def

include assert.def

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
	ForceRef TCharAttrElements
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
