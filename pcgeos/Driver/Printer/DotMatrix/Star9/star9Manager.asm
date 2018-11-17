COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		star 9-pin printer driver
FILE:		star9Manager.asm

AUTHOR:		Dave Durran

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Dave	2/90	initial version
	Dave 	3/90	added 9-pin print resources.
	Dave	4/92	2.0 version

DESCRIPTION:
	This file contains the source for the star 9-pin printer driver

	$Id: star9Manager.asm,v 1.1 97/04/18 11:53:08 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

;--------------------------------------
;	Include files
;--------------------------------------

include printcomInclude.def

;------------------------------------------------------------------------------
;		Constants and Macros
;------------------------------------------------------------------------------

include printcomConstant.def
include star9Constant.def

include printcomMacro.def

include star9.rdef

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

include printcomEpsonJob.asm  ; StartJob/EndJob/SetPaperpath routines
include printcomDotMatrixPage.asm        ; code to implement Page routines
include printcomEpsonStyles.asm ; code to implement Style setting routines
include printcomStream.asm      ; code to talk with the stream driver
include printcomDotMatrixBuffer.asm ; code to deal with graphic print buffers
include printcomNoColor.asm  ; code to implement Color routines
include printcomStarSGGraphics.asm ; common Star SG 9-pin graphics routines

include	star9ControlCodes.asm	; Tables of printer commands
include star9Dialog.asm ; code to implement UI setting
include star9Text.asm        ; common code to implement text routines
include star9Cursor.asm		; common Star 9-pin cursor routines

CommonCode ends

;------------------------------------------------------------------------------
;		Device Info Resources (each in their own resource)
;------------------------------------------------------------------------------

include	star9DriverInfo.asm		; overall driver info

include	star9generInfo.asm		; specific info for generic printer
include	star9generwInfo.asm		; specific info for generic wide printer

	end
