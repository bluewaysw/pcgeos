COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1988 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		Video driver
FILE:		att6300Manager.asm

AUTHOR:		Jim DeFrisco


REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Jim	7/90	initial version, mostly copied from HGC driver

DESCRIPTION:
	This file contains the source for the ATT6300 screen driver.  There
	are a number of actual files included in this one that actually 
	contain the actual source code.  They are located in the ATT6300
	directory.
		
	The complete specification for screen drivers can be found on the 
	system in the pcgeos spec directory (/staff/pcgeos/Spec).  

	$Id: att6300Manager.asm,v 1.1 97/04/18 11:42:39 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

;--------------------------------------
;	Include files
;--------------------------------------

_VideoDriver		=	1
VIDEO_STACK_SIZE	equ	512	; local stack space

include	vidcomGeode.def			; common include files

ifdef	WIN32
include		Objects/processC.def	; window update
include		timer.def		; window update
include		thread.def		; window update
endif ; WIN32

;---------------------------------------------------------------------
;		Constants and Macros
;---------------------------------------------------------------------

include att6300Constant.def
include dumbcomConstant.def
include vidcomConstant.def

include att6300Macro.def
include dumbcomMacro.def
include vidcomMacro.def

;------------------------------------------------------------------------------
;			Variables
;------------------------------------------------------------------------------
idata	segment

include	dumbcomDevInfo.asm		; device info block
include vidcomTables.asm
include att6300Tables.asm		; Tables for ATT6300 driver
include	dumbcomTables.asm		; important tabular information

idata	ends


udata	segment

include vidcomVariable.def
include	dumbcomVariable.def		; local buffer space
include	att6300Variable.def		; variables local to this driver

udata	ends

;------------------------------------------------------------------------------
;			Extended Driver Info Table
;------------------------------------------------------------------------------
VideoDevices	segment	lmem LMEM_TYPE_GENERAL
include	att6300StringTab.asm	; define device strings
VideoDevices	ends


;------------------------------------------------------------------------------
;			Fixed Code
;------------------------------------------------------------------------------
idata segment

include	vidcomEntry.asm			; entry point,jump tab
include	vidcomOutput.asm		; common output routines
include	vidcomChars.asm			; common character output routines
include	dumbcomGenChar.asm		; routines for bigger characters
include vidcomFont.asm			; special code for building fonts
include vidcomUnder.asm			; save under routines
include	vidcomUtils.asm			; utility routines
include vidcomRegion.asm		; common region routines
include vidcomXOR.asm			; xor region support
include	vidcomInfo.asm			; device checking/setting routines
include	vidcomEscape.asm		; support for some escape codes
include vidcomPalette.asm		; support for VidGetPixel
include	dumbcomOutput.asm		; output routines
include dumbcomUtils.asm		; misc utility routines
include	dumbcomChars.asm		; character drawing routines
include dumbcomPointer.asm		; pointer support
include dumbcomPalette.asm		; color tables
include	att6300EscTab.asm		; define the escape function jump table

idata ends

include	vidcomPolygon.asm		; polygon drawing code
include	vidcomLine.asm			; line drawing routine
include	vidcomPutLine.asm		; line drawing routine
include vidcomRaster.asm		; raster routines
include	vidcomExclBounds.asm		; bounds accumulation
include dumbcomRaster.asm		; raster routines
include	att6300Admin.asm		; misc admin routines

	end
