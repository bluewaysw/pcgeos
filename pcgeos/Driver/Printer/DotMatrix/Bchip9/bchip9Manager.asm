COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Bluechip 9-pin printer driver
FILE:		bchip9Manager.asm

AUTHOR:		Jim DeFrisco, 26 Feb 1990

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Jim	2/90	initial version
	Dave 	3/90	added 9-pin print resources.
	Dave	5/92	Initial 2.0 version

DESCRIPTION:
	This file contains the source for the bchip 9-pin printer driver

	$Id: bchip9Manager.asm,v 1.1 97/04/18 11:53:36 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

;--------------------------------------
;	Include files
;--------------------------------------

include printcomInclude.def

;------------------------------------------------------------------------------
;		Constants and Macros
;------------------------------------------------------------------------------

include printcomConstant.def
include bchip9Constant.def

include printcomMacro.def

include printcomEpsonMX.rdef

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

public	DriverTable

idata ends


;------------------------------------------------------------------------------
;               Entry Code
;------------------------------------------------------------------------------

Entry   segment resource        ; MODULE_FIXED

include printcomEntry.asm       ; entry point, misc bookeeping routines
include printcomTables.asm      ; jump table for some driver calls
include printcomInfo.asm        ; various info getting/setting routines
include printcomAdmin.asm       ; misc init routines
include printcomNoEscapes.asm   ; module jump table for driver escape calls

Entry   ends

;------------------------------------------------------------------------------
;               Driver code
;------------------------------------------------------------------------------

CommonCode segment resource     ; MODULE_STANDARD

include printcomEpsonJob.asm  ; StartJob/EndJob/SetPaperpath routines
include printcomCountryDialog.asm ; code to implement UI setting
include printcomDotMatrixPage.asm        ; code to implement Page routines
include printcomEpsonMXCursor.asm ; code to implement 9-pin Cursor routines
include printcomEpsonStyles.asm ; code to implement Style setting routines
include printcomStream.asm      ; code to talk with the stream driver
include printcomDotMatrixBuffer.asm ; code to deal with graphic print buffers
include printcomNoColor.asm  ; code to implement Color routines
include printcomEpsonMXGraphics.asm ; code to implement MX graphics routines

include bchip9ControlCodes.asm	; Tables of printer commands
include bchip9Text.asm		; common code to implement text routines

CommonCode ends

;------------------------------------------------------------------------------
;		Device Info Resources (each in their own resource)
;------------------------------------------------------------------------------

include	bchip9DriverInfo.asm		; overall driver info

include	bchip9generInfo.asm		; specific info for generic printer
include	bchip9generwInfo.asm		; specific info for generic wide printer
include Color/Correct/correctGamma20.asm ; gamma correction table

	end
