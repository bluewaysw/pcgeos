COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Test Printer Driver
FILE:		testManager.asm

AUTHOR:		Don Reeves, Jul 10, 1994

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	don	7/10/94		Initial revision

DESCRIPTION:
	This file contains the source manager for the test printer driver

	$Id: testManager.asm,v 1.1 97/04/18 11:52:32 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;--------------------------------------
;	Include files
;--------------------------------------

include printcomInclude.def

;------------------------------------------------------------------------------
;		Constants and Macros
;------------------------------------------------------------------------------

include printcomConstant.def
include testConstant.def

include printcomMacro.def

include	test.rdef

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
include UI/uiGetMain.asm	; retrieve Main UI tree
include UI/uiGetOptions.asm	; retrieve Options UI tree
include testUI.asm		; evaluate/stuff UI
include printcomPCLPage.asm	; code to implement Page routines
include printcomDeskjetCursor.asm ; common Deskjet cursor routines
include printcomPCLText.asm	; common code to implement text routines
include printcomPCLStyles.asm	; code to implement Style setting routines
include printcomPCLStream.asm	; code to talk with the stream driver
include printcomPCLBuffer.asm	; code to deal with graphic print buffers
include printcomNoColor.asm	; code to implement Color routines
include printcomDeskjetGraphics.asm ; common deskjet graphics routines

include testControlCodes.asm	; Tables of printer commands

CommonCode ends

ForceRef BeginInit
ForceRef InitPageSize
ForceRef PrintEnterPJL
ForceRef PrintExitPJL
ForceRef SetFirstCMYK
ForceRef SetNextCMYK
ForceRef pr_codes_DuplexMode


;------------------------------------------------------------------------------
;		Device Info Resources (each in their own resource)
;------------------------------------------------------------------------------

include	testDriverInfo.asm	; overall driver info

include	testInfo.asm


	end
