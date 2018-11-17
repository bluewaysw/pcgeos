COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Brother NIKE 56-jet printer driver
FILE:		nike56Manager.asm

AUTHOR:		Dave Durran

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Dave	10/94	Initial version

DESCRIPTION:
	This file contains the source for the Brother 56-pin printer driver

	$Id: nike56Manager.asm,v 1.1 97/04/18 11:55:36 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;--------------------------------------
;	Include files
;--------------------------------------

include printcomInclude.def
include initfile.def
include timedate.def
include thread.def
include	Internal/dwpPrint.def


;------------------------------------------------------------------------------
;		Constants and Macros
;------------------------------------------------------------------------------

include nike56Constant.def

include printcomMacro.def

include nike56.rdef

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
include nike56Admin.asm         ; misc init routines
include printcomTables.asm      ; module jump table for driver calls
include nike56EscapeTab.asm	; module jump table for driver escape calls

Entry   ends

;------------------------------------------------------------------------------
;               Driver code
;------------------------------------------------------------------------------

CommonCode segment resource     ; MODULE_STANDARD

include printcomNoStyles.asm	; code to implement Style setting routines
include printcomNoColor.asm	; code to implement Color routines
include printcomNoTextNoRaw.asm	; Dummy Text setting routines

include nike56Cursor.asm	; code for NIKE Cursor routines
include nike56Job.asm		; StartJob/EndJob/SetPaperpath routines
include nike56Page.asm		; code to implement Page routines
include nike56Graphics.asm	; code for NIKE graphics routines
include nike56Buffer.asm	; code to deal with graphic print buffers
include	nike56Escapes.asm	; routines to do the escape calls
include	nike56Errors.asm	; routine to do the error callback
include	nike56Stream.asm	; routine to do data transmission
include nike56Dialog.asm	; code to implement UI setting

CommonCode ends

;------------------------------------------------------------------------------
;		Device Info Resources (each in their own resource)
;------------------------------------------------------------------------------

include	nike56DriverInfo.asm		; overall driver info

include	nike56BaseInfo.asm		; specific info for base printer
include	nike56BaseTranInfo.asm		; specific info transparencies
include nike56ColorInfo.asm		; specific info for color printer
include nike56ColorTranInfo.asm		; specific info color transparencies

include	Color/Correct/correctGamma21.asm
include	Color/Correct/correctGamma20.asm
include Color/Correct/correctNIKETran.asm	; color correction table
include Color/Correct/correctNIKE.asm		; color correction table

;------------------------------------------------------------------------------
;		Text Resources (each in their own resource)
;------------------------------------------------------------------------------
include	nike56Strings.asm		;dialog box strings.

	end
