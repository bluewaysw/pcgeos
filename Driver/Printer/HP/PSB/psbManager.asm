COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		PostScript printer driver
FILE:		psbManager.asm

AUTHOR:		Jim DeFrisco

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Jim	6/91	initial version

DESCRIPTION:
	This file contains the source for the PostScript printer driver

	$Id: psbManager.asm,v 1.1 97/04/18 11:52:12 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

;--------------------------------------
;	Include files
;--------------------------------------

include printcomInclude.def
include timer.def
include psbInclude.def

UseLib		ui.def
UseLib		spool.def
;------------------------------------------------------------------------------
;		Constants and Macros
;------------------------------------------------------------------------------

include printcomConstant.def
include psbConstant.def

include printcomMacro.def
include psbMacro.def

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
include	psbVariable.def		; local buffer space

udata	ends

;------------------------------------------------------------------------------
;		Entry Code 
;------------------------------------------------------------------------------

Entry 	segment resource 	; MODULE_FIXED

include	printcomEntry.asm	; entry point, misc bookeeping routines
include	printcomTables.asm	; jump table for some driver calls
include	printcomCursor.asm	; a few cursor (current position) setting routs
include	printcomInfo.asm	; various info getting/setting routines

include	psbAdmin.asm		; misc admin routines
include	psbTables.asm		; module jump table for other driver calls
include	psbTextRes.asm		; misc useless routines

Entry 	ends

;------------------------------------------------------------------------------
;		Driver code
;------------------------------------------------------------------------------

CommonCode segment resource	; MODULE_STANDARD

include	printcomGraphics.asm	; common code to implement graphics routines
include	printcomStream.asm	; code to talk with the stream driver

include	psbSetup.asm		; misc setup/cleanup routines
include	psbText.asm		; code to implement text routines
include	psbStyles.asm		; code to implement Style routines
include	psbGraphics.asm		; code to implement graphics routines
include	psbBitmap.asm		; code to write out bitmap header
include	psbStream.asm		; code to talk with the stream driver
include	psbCursor.asm		; code to implement Cursor routines
include	psbPage.asm		; code to implement Page routines
include	psbHeader.asm		; code to implement Page routines
include	psbUtils.asm		; code to implement Page routines

CommonCode ends

;------------------------------------------------------------------------------
;		Device Info Resources (each in their own resource)
;------------------------------------------------------------------------------

include	psbDriverInfo.asm		; overall driver info
include	psbInfo.asm
include	psbProlog.asm
include	psbPSCode.asm
include	psbComments.asm

	end
