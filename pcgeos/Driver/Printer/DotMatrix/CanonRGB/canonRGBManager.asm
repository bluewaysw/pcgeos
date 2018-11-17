COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GlobalPC 1999 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Canon RGB Printer Driver
FILE:		canonRGBManager.asm

AUTHOR:		Joon Song, Jan 8, 1999

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Joon	1/99	Initial version

DESCRIPTION:
	This file contains the source for the canon rgb printer driver

	$Id$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;--------------------------------------
;	Include files
;--------------------------------------

include printcomInclude.def

;------------------------------------------------------------------------------
;		Constants and Macros
;------------------------------------------------------------------------------

include rgb2cmyk.def
include printcomConstant.def
include printcomMacro.def
include canonRGBConstant.def
include canonRGB.rdef

;------------------------------------------------------------------------------
;		Driver Info Table 
;------------------------------------------------------------------------------

idata segment 			; MODULE_FIXED

DriverTable DriverExtendedInfoStruct \
		< <Entry:DriverStrategy, 	; DIS_strategy
		  mask DA_HAS_EXTENDED_INFO,	; DIS_driverAttributes
		  DRIVER_TYPE_PRINTER >,	; DIS_driverType
		  handle DriverInfo		; DEIS_resource
		>

public	DriverTable

idata ends

;------------------------------------------------------------------------------
;               Entry Code
;------------------------------------------------------------------------------

Entry   segment resource        ; MODULE_FIXED

include printcomEntry.asm       ; entry point, misc bookeeping routines
include printcomInfo.asm        ; various info getting/setting routines
include printcomAdmin.asm       ; misc init routines
include printcomTables.asm      ; module jump table for driver calls
include printcomNoEscapes.asm   ; module jump table for driver escape calls

Entry   ends

;------------------------------------------------------------------------------
;               Driver code
;------------------------------------------------------------------------------

CommonCode segment resource		; MODULE_STANDARD

include Job/jobStartCanonRGB.asm
include Job/jobEndCanonRGB.asm
include Job/jobPaperPathNoASFControl.asm
include Job/jobPaperInfo.asm
include Job/jobResetPrinterAndWait.asm

include canonRGBColor.asm

include printcomCanonRGBPage.asm	; code to implement Page routines
include printcomCanonBJCCursor.asm	; code for CanonBJC Cursor routines
include printcomStream.asm		; code to talk with the stream driver

include printcomCanonBJCColor.asm	; code to implement Color routines

include	Graphics/graphicsCommon.asm	; common graphic print routines
include Graphics/graphicsCanonRGB.asm	; code for Canon RGB graphics routines

include canonRGBDialog.asm		; code to implement UI setting
include canonRGBControlCodes.asm	; escape and control codes

include printcomNoStyles.asm		; code to implement Style routines
include printcomNoText.asm		; code to implement Text routines

include	Buffer/bufferCreateCanonRGB.asm	; PrCreatePrintBuffers routine
include	Buffer/bufferDestroy.asm	; PrDestroyPrintBuffers routine

; To remove unecessary warnings
;
ForceRef PrintSetSymbolSet
ForceRef PrintLoadSymbolSet
ForceRef PrintClearStyles

CommonCode ends

;------------------------------------------------------------------------------
;		Device Info Resources (each in their own resource)
;------------------------------------------------------------------------------

include	canonRGBDriverInfo.asm		; overall driver info
include	canonRGBInfo.asm		; specific info RGB printer
include	canonRGBmonoInfo.asm		; specific info RGB mono printer
include canonRGBmono2Info.asm		; specific info RGB mono GPC printer

	end
