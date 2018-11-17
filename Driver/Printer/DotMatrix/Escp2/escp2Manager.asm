COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Epson Escape P2 24-pin printer driver
FILE:		escp2Manager.asm

AUTHOR:		Dave Durran 7/91

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Dave 	7/91

DESCRIPTION:
	This file contains the source for the Escape P2 24-pin printer driver

	$Id: escp2Manager.asm,v 1.1 97/04/18 11:54:23 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

;--------------------------------------
;	Include files
;--------------------------------------

include printcomInclude.def
include timer.def
include epson24Include.def

UseLib		ui.def
UseLib		spool.def
;------------------------------------------------------------------------------
;		Constants and Macros
;------------------------------------------------------------------------------

include printcomConstant.def
include escp2Constant.def

include printcomMacro.def
include epson24Macro.def

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

idata ends

;------------------------------------------------------------------------------
;		Data Area
;------------------------------------------------------------------------------

udata	segment			; MODULE_FIXED

include	printcomVariable.def	; local buffer space
include	epson24Variable.def	; local buffer space

udata	ends

;------------------------------------------------------------------------------
;		Entry Code 
;------------------------------------------------------------------------------

Entry 	segment resource 	; MODULE_FIXED

include	printcomEntry.asm	; entry point, misc bookeeping routines
include	printcomTextRes.asm	; resident text routines
include	printcomInfo.asm	; various info getting/setting routines

include	epson24Admin.asm		; misc admin routines
include	epson24Tables.asm	; module jump table for other driver calls

Entry 	ends

;------------------------------------------------------------------------------
;		Driver code
;------------------------------------------------------------------------------

CommonCode segment resource	; MODULE_STANDARD

include	printcomText.asm	; common code to implement text routines
include	printcomGraphics.asm	; common code to implement graphics routines
include	printcomStream.asm	; code to talk with the stream driver

include	escp2Setup.asm		; misc setup/cleanup routines
include	epson24Text.asm		; code to implement text routines
include	epson24Styles.asm	; code to implement graphics routines
include	escp2ControlCodes.asm	;  Escape and control codes
include	escp2Graphics.asm	; code to implement graphics routines
include	escp2Cursor.asm	; code to implement Cursor routines
include	escp2Page.asm		; code to implement Page routines

CommonCode ends

;------------------------------------------------------------------------------
;		Device Info Resources (each in their own resource)
;------------------------------------------------------------------------------

include	escp2DriverInfo.asm		; overall driver info

include	escp2generInfo.asm		; specific info for narrow carriage
include	escp2generwInfo.asm		; specific info for wide carriage

	end
