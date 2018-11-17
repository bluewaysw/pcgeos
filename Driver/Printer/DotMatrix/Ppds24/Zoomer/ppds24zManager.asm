COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		IBM late model 24-pin printer driver for Zoomer
FILE:		ppds24zManager.asm

AUTHOR:		Dave Durran

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Dave	2/90	initial version
	Dave 	3/90	added 24-pin print resources.
	Dave 	9/90	added IBM 24-pin print resources.
	Dave	5/92	Initial 2.0 version

DESCRIPTION:
	This file contains the source for the ppds 24-pin printer driver

	$Id: ppds24zManager.asm,v 1.1 97/04/18 11:54:24 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

;--------------------------------------
;	Include files
;--------------------------------------

include printcomInclude.def

;------------------------------------------------------------------------------
;		Constants and Macros
;------------------------------------------------------------------------------

include printcomConstant.def
include ppds24Constant.def

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
include Job/Custom/customPPDS24.asm
include printcomIBMPropDialog.asm ; code to implement UI setting
include printcomIBMPPDS24Cursor.asm ; code for PPDS 24 pin Cursor routines
include printcomIBMPPDS24Styles.asm ; code to implement Style setting routines
include printcomStream.asm      ; code to talk with the stream driver
include printcomDotMatrixBuffer.asm ; code to deal with graphic print buffers
include printcomNoColor.asm  ; code to implement Color routines
include printcomIBMPPDS24Graphics.asm ; code for PPDS 24 pin graphics routines

include ppds24ControlCodes.asm	;  Escape and control codes
include ppds24Text.asm        ; common code to implement text routines
include ppds24Page.asm        ; code to implement Page routines

CommonCode ends

;------------------------------------------------------------------------------
;		Device Info Resources (each in their own resource)
;------------------------------------------------------------------------------

include	ppds24zDriverInfo.asm		; overall driver info

include	ppds24generInfo.asm		; specific info for narrow printer
include	ppds24generwInfo.asm		; specific info for wide carr. printer

	end
