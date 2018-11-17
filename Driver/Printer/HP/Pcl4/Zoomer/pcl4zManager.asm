COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		LaserJet printer driver for Zoomer
FILE:		pcl4zManager.asm

AUTHOR:		Dave Durran

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Dave	1/92	initial version

DESCRIPTION:
	This file contains the source for the Lasdwn5 printer driver

	$Id: pcl4zManager.asm,v 1.1 97/04/18 11:52:16 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

;--------------------------------------
;	Include files
;--------------------------------------

include printcomInclude.def
include lmem.def
include	system.def

;------------------------------------------------------------------------------
;		Constants and Macros
;------------------------------------------------------------------------------

include printcomConstant.def
include pcl4Constant.def

include printcomMacro.def

include printcomPCL4.rdef

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
;		Entry Code 
;------------------------------------------------------------------------------

Entry 	segment resource 	; MODULE_FIXED

include	printcomEntry.asm	; entry point, misc bookeeping routines
include	printcomInfo.asm	; various info getting/setting routines
include	printcomTables.asm	; module jump table for all driver calls
include	printcomAdmin.asm		; misc admin routines

include	pcl4Tables.asm		; module jump table for all driver escape calls

Entry 	ends

;------------------------------------------------------------------------------
;		Driver code
;------------------------------------------------------------------------------

CommonCode segment resource	; MODULE_STANDARD

include	Graphics/graphicsCommon.asm ; common code to implement graphics routines
include	printcomPCLStream.asm	; code to talk with the stream driver
include	printcomPCL4Job.asm	; misc setup/cleanup routines
include	printcomPCL4Styles.asm	; code to implement Style routines
include	printcomPCL4Graphics.asm ; code to implement graphics routines
include	printcomPCL4Cursor.asm	; code to implement Cursor routines
include	printcomPCL4Page.asm	; code to implement Page routines
include printcomPCL4Text.asm	; text & font manager routines.
include printcomPCL4Dialog.asm	; Dialog Box service routines.
include printcomNoColor.asm	; Monochrome printers, all of them....

include	pcl4ControlCodes.asm	; Tables of printer commands

CommonCode ends

;------------------------------------------------------------------------------
;		Device Info Resources (each in their own resource)
;------------------------------------------------------------------------------

include	pcl4zDriverInfo.asm		; overall driver info

include	laserjet2Info.asm
include	downloadInfo.asm
include	internalInfo.asm
include	downloadDuplexInfo.asm
;below are resources that need to eventually be in the PCL 5 driver.
include	laserjet4Info.asm
include	internalDuplexInfo.asm

	end
