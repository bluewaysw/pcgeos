COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		DeskJet CMY printer driver
FILE:		dj500cManager.asm

AUTHOR:		Dave Durran

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Dave	2/90	initial version
	Dave	6/92	initial 2.0 version

DESCRIPTION:
	This file contains the source for the deskJet printer driver

	$Id: dj500cManager.asm,v 1.1 97/04/18 11:52:26 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

;--------------------------------------
;	Include files
;--------------------------------------

include printcomInclude.def

;------------------------------------------------------------------------------
;		Constants and Macros
;------------------------------------------------------------------------------

include printcomConstant.def
include dj500cConstant.def

include printcomMacro.def

include	printcomDeskjet.rdef

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
include printcomTables.asm      ; jump table for some driver calls
include printcomInfo.asm        ; various info getting/setting routines
include printcomAdmin.asm       ; misc init routines
include printcomNoEscapes.asm   ; module jump table for driver escape calls

Entry   ends


;------------------------------------------------------------------------------
;		Driver code
;------------------------------------------------------------------------------

CommonCode segment resource	; MODULE_STANDARD

include printcomPCLJob.asm	; StartJob/EndJob/SetPaperpath routines
include printcomDeskjetDialog.asm ; code to implement UI setting
include printcomPCLPage.asm	; code to implement Page routines
include printcomDeskjetCCursor.asm ; common Deskjet cursor routines
include printcomNoText.asm        ; dummy code to implement text routines
include printcomNoStyles.asm	; dummy code to implement Style setting routines
include printcomPCLStream.asm	; code to talk with the stream driver
include printcomPCLBuffer.asm ; code to deal with graphic print buffers
include printcomNoColor.asm	; dummy code to implement Color routines
include printcomDeskjetCMYGraphics.asm ; common Color deskjet graphics routines

include dj500cControlCodes.asm  ; Tables of printer commands

CommonCode ends

;------------------------------------------------------------------------------
;		Device Info Resources (each in their own resource)
;------------------------------------------------------------------------------

include	dj500cDriverInfo.asm		; overall driver info

include	dj500cInfo.asm
include Color/Correct/correctDJ500C.asm    ; color correction table

	end
