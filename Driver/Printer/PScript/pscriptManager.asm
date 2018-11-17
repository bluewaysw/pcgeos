COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		PostScript printer driver
FILE:		pscriptManager.asm

AUTHOR:		Jim DeFrisco, 15 May 1990

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Jim	5/90	initial version
   Falk	2015	added host printer (PS 2 PDF) and fileStDr.def

DESCRIPTION:
	This file contains the source for the PostScript printer driver

	$Id: pscriptManager.asm,v 1.1 97/04/18 11:56:04 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

;--------------------------------------
;	Include files
;--------------------------------------

include printcomInclude.def
include pscriptInclude.def
UseLib	Internal/xlatLib.def
UseLib	xlatPS.def
include Internal/fileStDr.def


;------------------------------------------------------------------------------
;		Constants and Macros
;------------------------------------------------------------------------------

include printcomConstant.def
include pscriptConstant.def

include printcomMacro.def
include pscriptMacro.def

include printcomPScript.rdef

;------------------------------------------------------------------------------
;		Driver Info Table 
;------------------------------------------------------------------------------

idata segment 			; MODULE_FIXED

DriverTable DriverExtendedInfoStruct \
		< <Entry:DriverStrategy, 	; DIS_strategy
		   mask DA_HAS_EXTENDED_INFO,	; DIS_driverAttributes
		   DRIVER_TYPE_PRINTER		; DIS_driverType
		   >,
		   handle DriverInfo		; DEIS_resource
		>
public DriverTable

idata ends

;------------------------------------------------------------------------------
;		Data Area
;------------------------------------------------------------------------------

udata	segment			; MODULE_FIXED

include	pscriptVariable.def	; local buffer space

udata	ends

;------------------------------------------------------------------------------
;		Entry Code 
;------------------------------------------------------------------------------

Entry 	segment resource 	; MODULE_FIXED

include	printcomEntry.asm	; entry point, misc bookeeping routines
include	printcomTables.asm	; jump table for some driver calls
include	printcomInfo.asm	; various info getting/setting routines

include	pscriptAdmin.asm		; misc admin routines
include	pscriptTables.asm	; module jump table for other driver calls

Entry 	ends

;------------------------------------------------------------------------------
;		Driver code
;------------------------------------------------------------------------------

CommonCode segment resource	; MODULE_STANDARD

include printcomNoText.asm
include	printcomNoStyles.asm
include	printcomStream.asm	; code to talk with the stream driver
include	printcomPScriptJob.asm	; StartJob and EndJob
include	printcomPScriptDialog.asm	; UI evaluation routines
include	Color/colorGetFormat.asm ; get color format info
include	Color/colorSetNone.asm 	; get color format info
include	pscriptGraphics.asm	; code to implement graphics routines
include	pscriptCursor.asm	; code to implement Cursor routines
include	pscriptPage.asm		; code to implement Page routines
include	pscriptPDL.asm		; code to implement PDL-specific routines
include	pscriptUtils.asm	; PostScript generating utilities
include pscriptControlCodes.asm

CommonCode ends

;------------------------------------------------------------------------------
;		Device Info Resources (each in their own resource)
;------------------------------------------------------------------------------

include	pscriptProlog.asm		; PostScript prolog

include	pscriptDriverInfo.asm		; overall driver info

include	appleLW2NTf35Info.asm		; Device info for Apple LaserWriters
include appleLWf13Info.asm
include	necColor40f17Info.asm		; Device info for NEC printers
include necColorf35Info.asm
include	adobeLJ2cartf35Info.asm		; Device info for Adobe LJ2 Carts
include adobeLJ2cartfTC1Info.asm
include adobeLJ2cartfTC2Info.asm
include hpLJ4psInfo.asm			; device info for LaserJet 4s
include hpLJColorf35Info.asm		; for laserjet color.
include	ibm4019f17Info.asm		; Device info for IBM printers
include ibm4019f39Info.asm
include ibm4079f35Info.asm
include ibm4216f43Info.asm
include qmsPS410f43Info.asm		; Device info for QMS printers
include qmsColorScriptf35Info.asm
include pscriptgenerf13Info.asm		; Device info for everything else
include pscriptgenerf17Info.asm
include pscriptgenerf35Info.asm
include pscriptgenerf39cartInfo.asm
include pscriptgenerCf35Info.asm
include SoftRIPInfo.asm			; device for GhostScript printing
include hostPrinterInfo.asm

; Not currently used, so removed - Don 7/11/00
;include Color/Correct/correctInk.asm    ; color correction table

	end



