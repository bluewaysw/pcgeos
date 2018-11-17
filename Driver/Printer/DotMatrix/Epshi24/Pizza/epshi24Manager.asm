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

	$Id: epshi24Manager.asm,v 1.1 97/04/18 11:54:09 newdeal Exp $

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

include epshi24dynaInfo.asm		; specific info for DynaPrinter
include epshi24dual2Info.asm		; specific info for DM-2V printer
include epshi24dual34MInfo.asm		; specific info for DM-3V printer
include epshi24dual34Info.asm		; specific info for DM-4VE printer
include epshi24dual5Info.asm		; specific info for DM-5V printer
include epshi24fb2HInfo.asm		; specific info for FB-2H printer
include epshi24fb5HInfo.asm		; specific info for FB-5H printer

include epshi24lbpInfo.asm		; specific info for LBP printer
include epshi24lbp2Info.asm		; specific info for LBP 2 printer
include epshi24lbpHInfo.asm		; specific info for LBP-H printer
include epshi24lbpA3Info.asm		; specific info for A3 page printer
include epshi24lbpA4Info.asm		; specific info for A4 page printer

include Color/Correct/correctGamma30.asm ; gamma correction table
include Color/Correct/correctInk.asm	; color correction table
	end
