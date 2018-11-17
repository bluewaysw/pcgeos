COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Bluechip 9-pin printer driver
FILE:		gemini9Manager.asm

AUTHOR:		Dave Durran

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Dave 	3/90	initial version

DESCRIPTION:
	This file contains the source for the bchip 9-pin printer driver

	$Id: gemini9Manager.asm,v 1.1 97/04/18 11:54:34 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

;--------------------------------------
;	Include files
;--------------------------------------

include printcomInclude.def

;------------------------------------------------------------------------------
;		Constants and Macros
;------------------------------------------------------------------------------

include printcomConstant.def
include gemini9Constant.def

include printcomMacro.def

include printcomDotMatrix.rdef

;------------------------------------------------------------------------------
;		Driver Info Table 
;------------------------------------------------------------------------------

idata segment 			; MODULE_FIXED

DriverTable DriverExtendedInfoStruct \
	<	<Entry:DriverStrategy,
		mask DA_HAS_EXTENDED_INFO,
		DRIVER_TYPE_PRINTER >,
		handle DriverInfo
	>

public  DriverTable

idata ends

;------------------------------------------------------------------------------
;		Entry Code 
;------------------------------------------------------------------------------

Entry   segment resource        ; MODULE_FIXED

include printcomEntry.asm       ; entry point, misc bookeeping routines
include printcomTables.asm      ; jump table for some driver calls
include printcomInfo.asm        ; various info getting/setting routines
include printcomAdmin.asm       ; misc init routines
include printcomNoEscapes.asm   ; module jump table for driver escape calls

Entry   ends

;------------------------------------------------------------------------------
;		Driver code
;------------------------------------------------------------------------------

CommonCode segment resource	; MODULE_STANDARD

include printcomIBMJob.asm    ; StartJob/EndJob/SetPaperpath routines
include printcomDotMatrixDialog.asm ; code to implement UI setting
include printcomDotMatrixPage.asm       ; code to implement Page routines
include printcomEpsonMXText.asm ; common code to implement text routines
include printcomEpsonStyles.asm ; code to implement Style setting routines
include printcomStream.asm      ; code to talk with the stream driver
include printcomDotMatrixBuffer.asm ; code to deal with graphic print buffers
include printcomNoColor.asm  ; code to implement Color routines
include printcomStarSGGraphics.asm ; common Star 9-pin graphics routines
include printcomStarSGCursor.asm ; common Epson 9-pin cursor routines

include	gemini9ControlCodes.asm	; Tables of printer commands

CommonCode ends

;------------------------------------------------------------------------------
;		Device Info Resources (each in their own resource)
;------------------------------------------------------------------------------

include	gemini9DriverInfo.asm		; overall driver info

include	gemini9Info.asm		; specific info for generic printer
include	gemini9wInfo.asm	; specific info for generic wide printer

	end
