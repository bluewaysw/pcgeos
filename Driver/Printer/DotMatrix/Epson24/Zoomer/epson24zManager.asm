COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Epson 24-pin printer driver
FILE:		epson24zManager.asm

AUTHOR:		Dave Durran

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Jim	2/90	initial version
	Dave 	3/90	added 24-pin print resources.

DESCRIPTION:
	This file contains the source for the epson 24-pin printer driver

	$Id: epson24zManager.asm,v 1.1 97/04/18 11:53:19 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

;--------------------------------------
;	Include files
;--------------------------------------

include printcomInclude.def

;------------------------------------------------------------------------------
;		Constants and Macros
;------------------------------------------------------------------------------

include printcomConstant.def
include epson24Constant.def

include printcomMacro.def

include printcomEpsonFX.rdef

;------------------------------------------------------------------------------
;		Driver Info Table 
;------------------------------------------------------------------------------

idata segment 			; MODULE_FIXED

DriverTable DriverExtendedInfoStruct 	\
			< < Entry:DriverStrategy,      	; DIS_strategy
			    mask DA_HAS_EXTENDED_INFO, 	; DIS_driverAttributes 
			    DRIVER_TYPE_PRINTER 	; DIS_driverType
			  >,
			  handle DriverInfo		; DEIS_resource
			>

public	DriverTable

idata ends


;------------------------------------------------------------------------------
;		Entry Code 
;------------------------------------------------------------------------------

Entry 	segment resource 	; MODULE_FIXED

include	printcomEntry.asm	; entry point, misc bookeeping routines
include	printcomInfo.asm	; various info getting/setting routines
include printcomAdmin.asm       ; misc init routines
include	printcomTables.asm	; module jump table for driver calls
include printcomNoEscapes.asm	; module jump table for driver escape calls

Entry 	ends

;------------------------------------------------------------------------------
;		Driver code
;------------------------------------------------------------------------------

CommonCode segment resource	; MODULE_STANDARD

include printcomEpsonJob.asm  ; StartJob/EndJob/SetPaperpath routines
include	printcomCountryDialog.asm ; code to implement UI setting
include	printcomDotMatrixPage.asm ; code to implement Page routines
include	printcomEpsonLQText.asm	; common code to implement text routines
include printcomEpsonStyles.asm ; code to implement Style setting routines
include	printcomStream.asm	; code to talk with the stream driver
include	printcomDotMatrixBuffer.asm ; code to deal with graphic print buffers
include	printcomEpsonColor.asm	; code to implement Color routines
include printcomEpsonLQ1Graphics.asm ; common Epson specific graphics routines
include	printcomEpsonLQ1Cursor.asm ; code to implement Cursor routines

include	epson24ControlCodes.asm	;  Escape and control codes

CommonCode ends

;------------------------------------------------------------------------------
;		Device Info Resources (each in their own resource)
;------------------------------------------------------------------------------

include	epson24zDriverInfo.asm		; overall driver info

include	epson24lq800Info.asm		; specific info for LQ-800 printer
include	epson24lq1000Info.asm		; specific info for LQ-1000 printer
include	epson24lq2500Info.asm		; specific info for LQ-2500 printer
include Color/Correct/correctInk.asm    ; color correction table


	end
