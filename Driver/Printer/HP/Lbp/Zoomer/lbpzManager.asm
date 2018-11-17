COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Lbp printer driver for Zoomer
FILE:		lbpzManager.asm

AUTHOR:		Dave Durran

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Dave	2/90	initial version
	Dave	6/92	initial 2.0 version

DESCRIPTION:
	This file contains the source for the Lbp printer driver

	$Id: lbpzManager.asm,v 1.1 97/04/18 11:51:58 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

;--------------------------------------
;	Include files
;--------------------------------------

include printcomInclude.def

;------------------------------------------------------------------------------
;		Constants and Macros
;------------------------------------------------------------------------------

include printcomConstant.def
include lbpConstant.def

include printcomMacro.def

include	printcomCapsl.rdef

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

include	printcomCapslJob.asm	; misc setup/cleanup routines
include	printcomHexStream.asm	; code to talk with the stream driver

include	printcomCapslDialog.asm	; code to implement dialog box routines
include	printcomDotMatrixBuffer.asm	; code to implement Buffer routines
include	printcomCapslText.asm	; code to implement text routines
include	printcomCapslStyles.asm		; code to implement Style routines
include	printcomCapslGraphics.asm	; code to implement graphics routines
include	printcomCapslCursor.asm		; code to implement Cursor routines
include	printcomASFOnlyPage.asm		; code to implement Page routines
include printcomNoColor.asm		;dummy color routines.

include	lbpControlCodes.asm	; Tables of printer commands

CommonCode ends

;------------------------------------------------------------------------------
;		Device Info Resources (each in their own resource)
;------------------------------------------------------------------------------

include	lbpzDriverInfo.asm		; overall driver info

include	capsl3Info.asm

	end
