COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		PostScript printer driver
FILE:		pscriptzManager.asm

AUTHOR:		Jim DeFrisco, 15 May 1990

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Jim	5/90	initial version

DESCRIPTION:
	This file contains the source for the PostScript printer driver

	$Id: pscriptzManager.asm,v 1.1 97/04/18 11:55:47 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

;--------------------------------------
;	Include files
;--------------------------------------

include printcomInclude.def
include pscriptInclude.def
UseLib	Internal/xlatLib.def
UseLib	xlatPS.def


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

include	pscriptzDriverInfo.asm		; overall driver info

include	appleLW2NTf35Info.asm		; Device info for Apple LaserWriters
include appleLWf13Info.asm
include	necColor40f17Info.asm		; Device info for NEC printers
include hpLJ4psInfo.asm			; device info for LaserJet 4s
include	ibm4019f17Info.asm		; Device info for IBM printers
include ibm4019f39Info.asm
include pscriptgenerf13Info.asm		; Device info for everything else
include pscriptgenerf35Info.asm

include Color/Correct/correctInk.asm    ; color correction table

	end



