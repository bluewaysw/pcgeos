COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Epson 9-pin printer driver
FILE:		prop9Manager.asm

AUTHOR:		Dave Durran

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Dave	2/90	initial version
	Dave 	3/90	added 9-pin print resources.
	Dave	5/92	Initial 2.0 version

DESCRIPTION:
	This file contains the source for the prop 9-pin printer driver

	$Id: prop9Manager.asm,v 1.1 97/04/18 11:53:58 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

;--------------------------------------
;	Include files
;--------------------------------------

include printcomInclude.def

;------------------------------------------------------------------------------
;		Constants and Macros
;------------------------------------------------------------------------------

include printcomConstant.def
include prop9Constant.def

include printcomMacro.def

include printcomIBMProp.rdef

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
;               Driver code
;------------------------------------------------------------------------------

CommonCode segment resource     ; MODULE_STANDARD

include printcomIBMJob.asm	; StartJob/EndJob/SetPaperpath routines
include printcomIBMPropDialog.asm ; code to implement UI setting
include printcomDotMatrixPage.asm        ; code to implement Page routines
include printcomEpsonMXCursor.asm ; common Epson 9-pin cursor routines
include printcomIBM9Text.asm        ; common code to implement text routines
include printcomIBMStyles.asm	; code to implement Style setting routines
include printcomStream.asm      ; code to talk with the stream driver
include printcomDotMatrixBuffer.asm ; code to deal with graphic print buffers
include printcomEpsonColor.asm  ; code to implement Color routines
include printcomEpsonFXGraphics.asm ; common Epson 9-pin graphics routines

include prop9ControlCodes.asm	; Tables of printer commands

CommonCode ends

;------------------------------------------------------------------------------
;		Device Info Resources (each in their own resource)
;------------------------------------------------------------------------------

include	prop9DriverInfo.asm		; overall driver info

include	prop9pp2Info.asm	; specific info for Proprinter II
include	prop9xlInfo.asm		; specific info for Proprinter XL wide carriage
include	prop9bj130Info.asm	; specific info for Canon BJ-130 wide carriage
include	prop92380Info.asm	; specific info for pers.prt II narrow carriage
include	prop92381Info.asm	; specific info for pers.prt II wide carriage

	end
