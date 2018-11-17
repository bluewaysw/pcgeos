COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Epson 9-pin printer driver
FILE:		epson9Manager.asm

AUTHOR:		Jim DeFrisco, 26 Feb 1990

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Jim	2/90	initial version
	Dave 	3/90	added 9-pin print resources.
	Dave 	5/92	Initial 2.0 version

DESCRIPTION:
	This file contains the source for the epson 9-pin printer driver

	$Id: epson9Manager.asm,v 1.1 97/04/18 11:53:16 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

;--------------------------------------
;	Include files
;--------------------------------------

include printcomInclude.def

;------------------------------------------------------------------------------
;		Constants and Macros
;------------------------------------------------------------------------------

include printcomConstant.def
include epson9Constant.def

include printcomMacro.def

include	printcomEpsonFX.rdef

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
include printcomCountryDialog.asm ; code to implement UI setting
include printcomDotMatrixPage.asm	; code to implement Page routines
include printcomEpsonFXCursor.asm ; common Epson 9-pin cursor routines
include printcomEpsonFXText.asm	; common code to implement text routines
include printcomEpsonStyles.asm ; code to implement Style setting routines
include printcomStream.asm      ; code to talk with the stream driver
include printcomDotMatrixBuffer.asm ; code to deal with graphic print buffers
include printcomEpsonColor.asm  ; code to implement Color routines
include printcomEpsonFXGraphics.asm ; common Epson 9-pin graphics routines

include	epson9ControlCodes.asm	; Tables of printer commands

CommonCode ends

;------------------------------------------------------------------------------
;		Device Info Resources (each in their own resource)
;------------------------------------------------------------------------------

include	epson9DriverInfo.asm		; overall driver info

include	epson9fx85Info.asm		; specific info for FX-85 printer
include	epson9fx185Info.asm		; specific info for FX-185 printer
include	epson9fx86eInfo.asm		; specific info for FX-86e printer
include	epson9fx286eInfo.asm		; specific info for FX-286e printer
include	epson9ex800Info.asm		; specific info for EX-800 printer
include	epson9ex1000Info.asm		; specific info for EX-1000 printer
include	epson9dfx5000Info.asm		; specific info for DF-5000 printer
include	epson9m1809Info.asm		; specific info for M-1809 printer
include	epson9generInfo.asm		; specific info for generic printer
include	epson9generwInfo.asm		; specific info for generic wide printer

include	Color/Correct/correctGamma30.asm ; gamma correction table
include Color/Correct/correctInk.asm    ; color correction table
	end
