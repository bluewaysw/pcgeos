COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Epson late model 24-pin printer driver
FILE:		epshi24Manager.asm

AUTHOR:		Jim DeFrisco, 26 Feb 1990

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Jim	2/90	initial version
	Dave 	3/90	added 24-pin print resources.

DESCRIPTION:
	This file contains the source for the epshi 24-pin printer driver

	$Id: epshi24Manager.asm,v 1.1 97/04/18 11:54:14 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

;--------------------------------------
;	Include files
;--------------------------------------

include printcomInclude.def

;------------------------------------------------------------------------------
;		Constants and Macros
;------------------------------------------------------------------------------

include printcomConstant.def
include epshi24Constant.def

include printcomMacro.def

include printcomEpsonLQ.rdef

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
;		Entry Code 
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
include printcomCountryDialog.asm ; code to implement UI setting
include printcomDotMatrixPage.asm        ; code to implement Page routines
include	printcomEpsonLQ2Cursor.asm ; code for Epson 24 pin Cursor routines
include printcomEpsonLQText.asm        ; common code to implement text routines
include printcomEpsonStyles.asm ; code to implement Style setting routines
include printcomStream.asm      ; code to talk with the stream driver
include printcomDotMatrixBuffer.asm ; code to deal with graphic print buffers
include printcomEpsonColor.asm  ; code to implement Color routines
include	printcomEpsonLQ2Graphics.asm ; code for Epson 24 pin graphics routines

include	epshi24ControlCodes.asm	;  Escape and control codes

CommonCode ends

;------------------------------------------------------------------------------
;		Device Info Resources (each in their own resource)
;------------------------------------------------------------------------------

include	epshi24DriverInfo.asm		; overall driver info

include	epshi24lq510Info.asm		; specific info for LQ-500 printer
include	epshi24lq850Info.asm		; specific info for LQ-850 printer
include	epshi24lq860Info.asm		; specific info for LQ-860 printer
include	epshi24lq950Info.asm		; specific info for LQ-950 printer
include	epshi24lq1010Info.asm		; specific info for LQ-1010 printer
include	epshi24lq1050Info.asm		; specific info for LQ-1050 printer
include	epshi24lq2550Info.asm		; specific info for LQ-2550 printer
include Color/Correct/correctGamma30.asm ; gamma correction table
include Color/Correct/correctInk.asm	; color correction table
	end
