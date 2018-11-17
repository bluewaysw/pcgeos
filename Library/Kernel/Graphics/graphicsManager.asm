COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		Kernel/Graphics
FILE:		graphicsManager.asm

AUTHOR:		Jim DeFrisco

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	4/88...		Initial version

DESCRIPTION:
	This file assembles the graphics code.

	$Id: graphicsManager.asm,v 1.1 97/04/05 01:12:53 newdeal Exp $

----------------------------------------------------------------------------@

include kernelGeode.def

;--------------------------------------
;	Include files
;--------------------------------------

include graphics.def

BUILD_KERNEL_GSTRING_TABLES	equ	TRUE
DEBUG_CONIC_SECTION_CODE	equ	FALSE

include gstring.def
include win.def
include lmem.def
include sem.def
include localize.def
include char.def
include text.def
include hugearr.def
include chunkarr.def			;for ArrayQuickSort

include Internal/geodeStr.def
include Internal/grWinInt.def
include Internal/gstate.def
include Internal/window.def		;includes: tmatrix.def
include Internal/dos.def
include Internal/interrup.def
UseDriver Internal/fontDr.def
UseDriver Internal/videoDr.def

include gcnlist.def
include	geoworks.def
include Objects/metaC.def


;--------------------------------------

include graphicsMacro.def		;GRAPHICS macros
include graphicsConstant.def		;GRAPHICS constants

;-------------------------------------

include graphicsVariable.def		;GRAPHICS variables
include graphicsTables.asm		; GRAPHICS data tables

;-------------------------------------

kcode	segment

include 	graphicsChars.asm
include 	graphicsLine.asm
include 	graphicsMath.asm
include 	graphicsRaster.asm
include 	graphicsRegion.asm
include 	graphicsState.asm
include 	graphicsText.asm
include 	graphicsTextMetrics.asm
include 	graphicsTextObject.asm
include 	graphicsTransform.asm

kcode	ends

;-------------------------------------

kinit	segment
include 	graphicsInit.asm
kinit	ends

;---------------------------------------------------------------------
;	Graphics Modules (segments defined in individual source files)
;---------------------------------------------------------------------

include 	graphicsEllipse.asm
include 	graphicsArc.asm
include         graphicsArcLow.asm
include         graphicsBitmapCreate.asm
include         graphicsBitmapString.asm
include         graphicsCalcConic.asm
include         graphicsCalcEllipse.asm
include 	graphicsColor.asm
include         graphicsEllipseLow.asm
include         graphicsFatLine.asm
include		graphicsFont.asm
include		graphicsFontDriver.asm
include 	graphicsGetState.asm
include         graphicsLineStyles.asm
include 	graphicsMathObscure.asm
include 	graphicsOutput.asm		
include		graphicsPath.asm
include		graphicsPathLow.asm
include		graphicsPattern.asm
include		graphicsPatternBitmap.asm
include		graphicsPatternHatch.asm
include 	graphicsPolygon.asm
include 	graphicsPolyline.asm
include         graphicsRasterDraw.asm
include         graphicsRasterRotate.asm
include         graphicsRasterScale.asm
include         graphicsRasterUtils.asm
include		graphicsBitmapHuge.asm
include         graphicsRegionPath.asm
include         graphicsRegionRaster.asm
include         graphicsRegionAppl.asm
include 	graphicsRoundedRect.asm
include         graphicsSpline.asm
include 	graphicsString.asm
include         graphicsStringUtils.asm
include         graphicsStringStore.asm
include         graphicsStringMisc.asm
include         graphicsSubString.asm
include         graphicsTextObscure.asm
include         graphicsTransformSimple.asm
include         graphicsTransformUtils.asm
include 	graphicsUtils.asm
include 	graphicsWin.asm
include 	graphicsImage.asm

;-----

;	C Interface files

include		graphicsGStringC.asm
include		graphicsFontC.asm
include		graphicsC.asm

end
