COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1988 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		MCGA screen driver
FILE:		mcgaManager.asm

AUTHOR:		Jim DeFrisco


REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Jim	6/90	initial version

DESCRIPTION:
	This file contains the source for the MCGA screen driver.  There
	are a number of actual files included in this one that actually 
	contain the actual source code.  They are located in the MCGA
	directory.
		
	The complete specification for screen drivers can be found on the 
	system in the pcgeos spec directory (/staff/pcgeos/Spec).  

	$Id: mcgaManager.asm,v 1.1 97/04/18 11:42:34 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}


;------------------------------------------------------------------------------
;			Constants
;------------------------------------------------------------------------------

_VideoDriver		=	1

;--------------------------------------
;	Include files
;--------------------------------------

VIDEO_STACK_SIZE	equ	512		; size of local stack
include	vidcomGeode.def				; common include files

;---------------------------------------------------------------------
;		Constants and Macros
;---------------------------------------------------------------------

include mcgaConstant.def
include dumbcomConstant.def
include vidcomConstant.def

include mcgaMacro.def
include dumbcomMacro.def
include vidcomMacro.def

;------------------------------------------------------------------------------
;			Variables
;------------------------------------------------------------------------------
idata	segment

include	dumbcomDevInfo.asm		; device info block
include vidcomTables.asm
include mcgaTables.asm		; Tables for MCGA driver
include	dumbcomTables.asm		; important tabular information

idata	ends


udata	segment

include vidcomVariable.def
include	dumbcomVariable.def		; local buffer space
include	mcgaVariable.def		; variables local to this driver

udata	ends

;------------------------------------------------------------------------------
;			Extended Device Info
;------------------------------------------------------------------------------
VideoDevices	segment	lmem LMEM_TYPE_GENERAL
include	mcgaStringTab.asm		; device names
VideoDevices	ends


;------------------------------------------------------------------------------
;			Fixed Code
;------------------------------------------------------------------------------
idata segment 

include	vidcomEntry.asm			; entry point,jump tab
include	vidcomOutput.asm		; common output routines
include	vidcomChars.asm			; common character output routines
include	dumbcomGenChar.asm		; routines for larger characters
include vidcomFont.asm			; routines for building, rotating chars
include vidcomUnder.asm			; save under routines
include	vidcomUtils.asm			; utility routines
include	vidcomRegion.asm		; region drawing routines
include vidcomXOR.asm			; xor region support
include vidcomInfo.asm			; device naming/setting
include	vidcomEscape.asm		; support for some escape codes
include vidcomPalette.asm		; support for VidGetPixel
include	dumbcomOutput.asm		; output routines
include dumbcomUtils.asm		; misc utility routines
include	dumbcomChars.asm		; character drawing routines
include dumbcomPointer.asm		; pointer support
include dumbcomPalette.asm		; color tables
include	mcgaEscTab.asm			; escape routine jump table

idata	ends

;------------------------------------------------------------------------------
;			Movable Code
;------------------------------------------------------------------------------

include vidcomPolygon.asm		; polygon drawing
include	vidcomLine.asm			; line drawing routine
include	vidcomPutLine.asm		; line drawing routine
include vidcomRaster.asm		; raster routines
include vidcomExclBounds.asm	; bounds accumulation
include dumbcomRaster.asm		; raster routines
include	mcgaAdmin.asm			; misc admin routines

	end
