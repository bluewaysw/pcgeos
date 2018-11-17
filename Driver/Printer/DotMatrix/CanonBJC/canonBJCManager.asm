COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GlobalPC 1999 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Canon BJC Printer Driver
FILE:		canonBJCManager.asm

AUTHOR:		Joon Song, Jan 8, 1999

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Joon	1/99	Initial version

DESCRIPTION:
	This file contains the source for the canon bjc printer driver

	$Id$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;--------------------------------------
;	Include files
;--------------------------------------

include printcomInclude.def

;------------------------------------------------------------------------------
;		Constants and Macros
;------------------------------------------------------------------------------

include printcomConstant.def
include printcomMacro.def
include canonBJCConstant.def
include canonBJC.rdef

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

include printcomCanonBJCJob.asm		; StartJob/EndJob/SetPaperpath routines
include printcomASFOnlyPage.asm		; code to implement Page routines
include printcomCanonBJCCursor.asm	; code for CanonBJC Cursor routines
include printcomStream.asm		; code to talk with the stream driver

include printcomCanonBJCColor.asm	; code to implement Color routines
include printcomCanonBJCGraphics.asm	; code for Canon BJ graphics routines

include canonBJCDialog.asm		; code to implement UI setting
include canonBJCControlCodes.asm	; escape and control codes

include printcomNoStyles.asm		; code to implement Style routines
include printcomNoText.asm		; code to implement Text routines

include	Buffer/bufferCreate.asm		; PrCreatePrintBuffers routine
include	Buffer/bufferDestroy.asm	; PrDestroyPrintBuffers routine

CommonCode ends

;------------------------------------------------------------------------------
;		Device Info Resources (each in their own resource)
;------------------------------------------------------------------------------

include	canonBJCDriverInfo.asm		; overall driver info
include	canonBJCmonoInfo.asm		; specific info for B/W printer
include	canonBJCcmyInfo.asm		; specific info for CMY printer
include	canonBJCcmykInfo.asm		; specific info for CMYK printer

	end
