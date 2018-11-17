COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		iwriter 9-pin printer driver
FILE:		iwriter9Manager.asm

AUTHOR:		Dave Durran

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Dave	3/90	initial version

DESCRIPTION:
	This file contains the source for the iwriter 9-pin printer driver

	$Id: iwriter9Manager.asm,v 1.1 97/04/18 11:53:40 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

;--------------------------------------
;	Include files
;--------------------------------------

include printcomInclude.def
include coreBlock.def
include timer.def
include citoh9Include.def

UseLib		ui.def
UseLib		spool.def
;------------------------------------------------------------------------------
;		Constants and Macros
;------------------------------------------------------------------------------

include printcomConstant.def
include citoh9Constant.def

include printcomMacro.def
include citoh9Macro.def

;------------------------------------------------------------------------------
;		Driver Info Table 
;------------------------------------------------------------------------------

idata segment 			; MODULE_FIXED

DriverTable DriverInfoStruct <Entry:DriverStrategy, <0,0,0>, DRIVER_TYPE_PRINTER >

idata ends

;------------------------------------------------------------------------------
;		Data Area
;------------------------------------------------------------------------------

udata	segment			; MODULE_FIXED

include	printcomVariable.def	; local buffer space
include	citoh9Variable.def	; local buffer space

udata	ends

;------------------------------------------------------------------------------
;		Entry Code 
;------------------------------------------------------------------------------

Entry 	segment resource 	; MODULE_FIXED

include	printcomEntry.asm	; entry point, misc bookeeping routines
include	printcomTables.asm	; jump table for some driver calls
include	printcomCursor.asm	; a few cursor (current position) setting routs
include	printcomTextRes.asm	; resident text routines
include	printcomInfo.asm	; various info getting/setting routines

include	citoh9Admin.asm		; misc admin routines
include	citoh9Tables.asm	; module jump table for other driver calls

Entry 	ends

;------------------------------------------------------------------------------
;		Driver code
;------------------------------------------------------------------------------

CommonCode segment resource	; MODULE_STANDARD

include	printcomText.asm	; common code to implement text routines
include	printcomGraphics.asm	; common code to implement graphics routines
include	printcomStream.asm	; code to talk with the stream driver
include	printcomSetup.asm	; misc setup/cleanup routines

include	citoh9Text.asm		; code to implement text routines
include	iwriter9Styles.asm	; code to implement Style routines
include	iwriter9ControlCodes.asm	; Tables of printer commands
include	citoh9Graphics.asm	; code to implement graphics routines
include	citoh9Cursor.asm	; code to implement Cursor routines
include	citoh9Page.asm		; code to implement Page routines

CommonCode ends

;------------------------------------------------------------------------------
;		Device Info Resources (each in their own resource)
;------------------------------------------------------------------------------

include	iwriter9DriverInfo.asm		; overall driver info

include	iwriter9generInfo.asm		; specific info for generic printer

	end
