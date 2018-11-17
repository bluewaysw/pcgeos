COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		citoh 9-pin printer driver
FILE:		citoh9Manager.asm

AUTHOR:		Jim DeFrisco, 26 Feb 1990

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Jim	2/90	initial version
	Dave 	3/90	added 9-pin print resources.
	Dave	5/92	Initial 2.0 version

DESCRIPTION:
	This file contains the source for the citoh 9-pin printer driver

	$Id: citoh9Manager.asm,v 1.1 97/04/18 11:53:31 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

;--------------------------------------
;	Include files
;--------------------------------------

include printcomInclude.def

;------------------------------------------------------------------------------
;		Constants and Macros
;------------------------------------------------------------------------------

include printcomConstant.def
include citoh9Constant.def

include printcomMacro.def

include citoh9.rdef

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

include printcomEpsonJob.asm  ; StartJob/EndJob/SetPaperpath routines
include printcomDotMatrixPage.asm        ; code to implement Page routines
include printcomCitohCursor.asm ; common Epson 9-pin cursor routines
include printcomEpsonStyles.asm	; code to implement Style setting routines
include printcomHex0Stream.asm      ; code to talk with the stream driver
include printcomDotMatrixBuffer.asm ; code to deal with graphic print buffers
include printcomCitohColor.asm  ; code to implement Color routines
include printcomCitohGraphics.asm ; common Citoh 9-pin graphics routines

include citoh9ControlCodes.asm  ; Tables of printer commands
include citoh9Text.asm        ; common code to implement text routines
include citoh9Dialog.asm ; code to implement UI setting

CommonCode ends

;------------------------------------------------------------------------------
;		Device Info Resources (each in their own resource)
;------------------------------------------------------------------------------

include	citoh9DriverInfo.asm		; overall driver info

include	citoh9generInfo.asm		; specific info for generic printer
include	citoh9generwInfo.asm		; specific info for generic wide printer
include	citoh9DMPInfo.asm		; specific info for Apple DMP printer
include	citoh9IWriter2Info.asm		; specific info for Apple ImageWriter II

include Color/Correct/correctInk.asm    ; color correction table

	end
