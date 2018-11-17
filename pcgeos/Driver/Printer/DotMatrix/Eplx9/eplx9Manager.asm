COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Epson 9-pin printer driver
FILE:		eplx9Manager.asm

AUTHOR:		Jim DeFrisco, 26 Feb 1990

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Jim	2/90	initial version
	Dave 	3/90	added 9-pin print resources.
	Dave 	5/92	Initial 2.0 version

DESCRIPTION:
	This file contains the source for the eplx 9-pin printer driver

	$Id: eplx9Manager.asm,v 1.1 97/04/18 11:54:39 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

;--------------------------------------
;	Include files
;--------------------------------------

include printcomInclude.def

;------------------------------------------------------------------------------
;		Constants and Macros
;------------------------------------------------------------------------------

include printcomConstant.def
include eplx9Constant.def

include printcomMacro.def

include	eplx9.rdef

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

Entry 	segment resource 	; MODULE_FIXED

include	printcomEntry.asm	; entry point, misc bookeeping routines
include	printcomTables.asm	; jump table for some driver calls
include	printcomInfo.asm	; various info getting/setting routines
include	printcomAdmin.asm	; misc init routines
include	printcomNoEscapes.asm	; module jump table for driver escape calls

Entry 	ends

;------------------------------------------------------------------------------
;		Driver code
;------------------------------------------------------------------------------

CommonCode segment resource	; MODULE_STANDARD

include printcomEpsonJob.asm	; StartJob/EndJob/SetPaperpath routines
include printcomDotMatrixPage.asm	; code to implement Page routines
include printcomEpsonMXCursor.asm ; common Epson 9-pin cursor routines
include printcomEpsonFXText.asm	; common code to implement text routines
include printcomEpsonStyles.asm ; code to implement Style setting routines
include printcomStream.asm      ; code to talk with the stream driver
include printcomDotMatrixBuffer.asm ; code to deal with graphic print buffers
include printcomEpsonColor.asm  ; code to implement Color routines
include printcomEpsonFXGraphics.asm ; common Epson 9-pin graphics routines

include eplx9Dialog.asm ; code to implement UI setting
include	eplx9ControlCodes.asm	; Tables of printer commands

CommonCode ends

;------------------------------------------------------------------------------
;		Device Info Resources (each in their own resource)
;------------------------------------------------------------------------------

include	eplx9DriverInfo.asm		; overall driver info

include	eplx9fx80Info.asm		; specific info for FX-80 printer
include	eplx9fx100Info.asm		; specific info for FX-100 printer
include	eplx9jx80Info.asm		; specific info for JX-80 printer
include	eplx9lx80Info.asm		; specific info for LX-80 printer

; include	Color/Correct/correctGamma27.asm ; gamma correction factor of 2.7
include Color/Correct/correctInk.asm    ; color correction table
	end
