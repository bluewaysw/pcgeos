COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Memory video driver
FILE:		mainManager.asm

AUTHOR:		Jim DeFrisco, 25 August 1989

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Jim	8/89	initial version

DESCRIPTION:
	This file contains the source for the main module of the memory 
	video driver. 

	$Id: mainManager.asm,v 1.1 97/04/18 11:42:43 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

;--------------------------------------
;	Declare what module this is
;--------------------------------------

_Main 		= 1

;--------------------------------------
;	Include files
;--------------------------------------

include vidmemInclude.def

;------------------------------------------------------------------------------
;		Driver Info Table 
;------------------------------------------------------------------------------

idata segment ;MODULE_FIXED

DriverTable DriverInfoStruct <Main:DriverStrategy, <0,0,0>, DRIVER_TYPE_VIDEO >

ForceRef	DriverTable

maskInfoSem	Semaphore <>		; to protect the following shared vars
maskType	BMType			; type used for following
maskWidth	word			; width used for following
maskMaskSize	word			; size of mask part
maskScanSize	word			; calculated scan size
idata ends

;------------------------------------------------------------------------------
;		Code 
;------------------------------------------------------------------------------

Main segment resource 		; FIXED

include	mainMain.asm		; entry point, misc bookeeping routines
include	mainTables.asm		; jump table for some video driver calls
include	mainVariable.def	; local buffer space
include vidcomEscape.asm	; support for some escape codes

Main ends

	end
