COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Epson 24-pin printer driver
FILE:		epson24Manager.asm

AUTHOR:		Jim DeFrisco, 26 Feb 1990

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Jim	2/90	initial version
	Dave 	3/90	added 24-pin print resources.
	VM	5/94	DBCS version

DESCRIPTION:
	This file contains the source for the epson 24-pin printer driver

	$Id: epson24Manager.asm,v 1.1 97/04/18 11:53:22 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

;--------------------------------------
;	Include files
;--------------------------------------

include printcomInclude.def

;------------------------------------------------------------------------------
;		Constants and Macros
;------------------------------------------------------------------------------

include printcomConstant.def
include epson24PConstant.def

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

include	epson24PControlCodes.asm	;  Escape and control codes

CommonCode ends

;------------------------------------------------------------------------------
;		Device Info Resources (each in their own resource)
;------------------------------------------------------------------------------

include	epson24DriverInfo.asm		; overall driver info

include epson24inkjetInfo.asm           ; specific info for Toshiba Inkjet
include epson24dj300JInfo.asm           ; specific info for DJ-300J printer
include epson24dj505JMInfo.asm          ; specific info for DJ-505J mono printer

	end
