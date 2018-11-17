COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Epson 48-jet printer driver for Pizza
FILE:		epson48Manager.asm

AUTHOR:		Dave Durran

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Dave 	9/92	Initial version

DESCRIPTION:
	This file contains the source for the epson 48-jet printer driver

	$Id: epson48Manager.asm,v 1.1 97/04/18 11:54:44 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

;--------------------------------------
;	Include files
;--------------------------------------

include printcomInclude.def

;------------------------------------------------------------------------------
;		Constants and Macros
;------------------------------------------------------------------------------

include printcomConstant.def
include epson48PConstant.def

include printcomMacro.def

include epson48.rdef

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
include printcomDotMatrixPage.asm        ; code to implement Page routines
include	printcomEpsonLQ2Cursor.asm ; code for Epson 24 pin Cursor routines
include printcomEpsonLQText.asm        ; common code to implement text routines
include printcomEpsonStyles.asm ; code to implement Style setting routines
include printcomStream.asm      ; code to talk with the stream driver
include printcomDotMatrixBuffer.asm ; code to deal with graphic print buffers
include printcomEpsonColor.asm  ; code to implement Color routines
include	printcomEpsonLQ4Graphics.asm ; code for Epson 48 pin graphics routines

include epson48Dialog.asm ; code to implement UI setting
include	epson48PControlCodes.asm	;  Escape and control codes

CommonCode ends

;------------------------------------------------------------------------------
;		Device Info Resources (each in their own resource)
;------------------------------------------------------------------------------

include	epson48DriverInfo.asm		; overall driver info

include epson48bj10vInfo.asm		; specific info for BJ-10v printer
include epson48bj220Info.asm		; specific info for BJ-220 printer

include epson48bjc400jMInfo.asm		; specific info for BJC-400J printer
include epson48bjc400jInfo.asm		; specific info for BJC-400J printer

include epson48bjc600jInfo.asm		; specific info for BJC-600J printer
include epson48bjc600jMInfo.asm		; specific info for BJC-600J printer

include epson48ap700Info.asm		; specific info for AP-700 printer
include epson48ap700MInfo.asm		; specific info for AP-700 printer
include epson48mj500v2Info.asm		; specific info for MJ-500v2 printer
include epson48mj1000v2Info.asm		; specific info for MJ-1000v2 printer

include epson48dyna48Info.asm		; specific info for PR-48 printer

include	Color/Correct/correctInk.asm	; color correction table
include Color/Correct/correctGamma20.asm ;B/W Gamma correction table
include Color/Correct/correctGamma175.asm ;B/W Gamma correction table

	end
