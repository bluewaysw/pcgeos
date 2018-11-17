COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		toshiba 24-pin printer driver
FILE:		toshiba24Manager.asm

AUTHOR:		Jim DeFrisco, 26 Feb 1990

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Jim	2/90	initial version
	Dave 	3/90	added 24-pin print resources.
	Dave	5/92		Initial 2.0 version

DESCRIPTION:
	This file contains the source for the toshiba 24-pin printer driver

	$Id: toshiba24Manager.asm,v 1.1 97/04/18 11:53:36 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

;--------------------------------------
;	Include files
;--------------------------------------

include printcomInclude.def

;------------------------------------------------------------------------------
;		Constants and Macros
;------------------------------------------------------------------------------

include printcomConstant.def
include toshiba24Constant.def

include printcomMacro.def

include toshiba24.rdef

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

CommonCode segment resource     ; MODULE_STANDARD

include printcomEpsonJob.asm  ; StartJob/EndJob/SetPaperpath routines
include printcomDotMatrixPage.asm        ; code to implement Page routines
include printcomHex0Stream.asm      ; code to talk with the stream driver
include printcomDotMatrixBuffer.asm ; code to deal with graphic print buffers
include printcomNoColor.asm  ; code to implement Color routines
include printcomToshibaGraphics.asm ; common Epson specific graphics routines
include printcomToshibaCursor.asm ; code to implement Cursor routines

include toshiba24Styles.asm	; code to implement Style setting routines
include toshiba24Text.asm        ; common code to implement text routines
include toshiba24Dialog.asm ; code to implement UI setting
include toshiba24ControlCodes.asm ;  Escape and control codes

CommonCode ends


;------------------------------------------------------------------------------
;		Device Info Resources (each in their own resource)
;------------------------------------------------------------------------------

include	toshiba24DriverInfo.asm		; overall driver info

include	toshiba24p321Info.asm		; specific info for p321 printer
include	toshiba24p351Info.asm		; specific info for p351 printer

	end
