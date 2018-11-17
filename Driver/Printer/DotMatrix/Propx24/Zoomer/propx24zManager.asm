COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		IBM Proprinter X24 24-pin printer driver for Zoomer
FILE:		propx24Manager.asm

AUTHOR:		Dave Durran

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Jim	2/90	initial version
	Dave 	3/90	added 24-pin print resources.
	Dave	5/92		Initial 2.0 version

DESCRIPTION:
	This file contains the source for the propx 24-pin printer driver

	$Id: propx24zManager.asm,v 1.1 97/04/18 11:53:44 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

;--------------------------------------
;	Include files
;--------------------------------------

include printcomInclude.def

;------------------------------------------------------------------------------
;		Constants and Macros
;------------------------------------------------------------------------------

include printcomConstant.def
include propx24Constant.def

include printcomMacro.def

include printcomIBMX24.rdef

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
include printcomAdmin.asm       ; misc init routines
include printcomTables.asm      ; module jump table for driver calls
include printcomNoEscapes.asm   ; module jump table for driver escape calls

Entry   ends

;------------------------------------------------------------------------------
;               Driver code
;------------------------------------------------------------------------------

CommonCode segment resource     ; MODULE_STANDARD

include printcomIBMJob.asm	; StartJob/EndJob/SetPaperpath routines
include printcomIBMX24Dialog.asm ; code to implement UI setting
include printcomDotMatrixPage.asm        ; code to implement Page routines
include printcomIBM24Text.asm        ; common code to implement text routines
include printcomIBMStyles.asm	; code to implement Style setting routines
include printcomStream.asm      ; code to talk with the stream driver
include printcomDotMatrixBuffer.asm ; code to deal with graphic print buffers
include printcomEpsonColor.asm  ; code to implement Color routines
include printcomIBMX24Graphics.asm ; common IBMX24 specific graphics routines
include printcomIBMX24Cursor.asm ; code to implement Cursor routines

include	propx24ControlCodes.asm	; control codes to be used.

CommonCode ends


;------------------------------------------------------------------------------
;		Device Info Resources (each in their own resource)
;------------------------------------------------------------------------------

include	propx24zDriverInfo.asm		; overall driver info

include	propx24generInfo.asm		; specific info for generic printer
include	propx24generwInfo.asm		; specific info for gen. wide printer
include	propx24ps1Info.asm		; specific info for PS/1 printer
include propx24bjIBMInfo.asm            ; specific info for BJs in IBM Mode

	end
