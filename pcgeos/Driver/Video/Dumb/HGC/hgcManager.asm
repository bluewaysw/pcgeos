COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1988 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		HGC screen driver
FILE:		hgcManager.asm

AUTHOR:		Tony Requist


REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Tony	10/88	initial version

DESCRIPTION:
	This file contains the source for the HGC screen driver.  There
	are a number of actual files included in this one that actually 
	contain the actual source code.  They are located in the HGC
	directory.
		
	The complete specification for screen drivers can be found on the 
	system in the pcgeos spec directory (/staff/pcgeos/Spec).  

	$Id: hgcManager.asm,v 1.1 97/04/18 11:42:35 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

;--------------------------------------
;		Include files
;--------------------------------------

_VideoDriver		=	1
VIDEO_STACK_SIZE	equ	512		; local stack size

include	vidcomGeode.def				; common include files

;---------------------------------------------------------------------
;		Constants and Macros
;---------------------------------------------------------------------

include hgcConstant.def
include dumbcomConstant.def
include vidcomConstant.def

include hgcMacro.def
include dumbcomMacro.def
include vidcomMacro.def

;------------------------------------------------------------------------------
;			Variables
;------------------------------------------------------------------------------
idata	segment

include	dumbcomDevInfo.asm		; device info block
include vidcomTables.asm
include hgcTables.asm			; Tables for HGC driver
include	dumbcomTables.asm		; important tabular information

idata	ends


udata	segment

include vidcomVariable.def
include	dumbcomVariable.def		; local buffer space
include	hgcVariable.def			; variables local to this driver

udata	ends


;------------------------------------------------------------------------------
;			Extended Device Info
;------------------------------------------------------------------------------
VideoDevices	segment	lmem LMEM_TYPE_GENERAL
include	hgcStringTab.asm	; device names
VideoDevices	ends


;------------------------------------------------------------------------------
;			Fixed Code
;------------------------------------------------------------------------------

idata segment

include	vidcomEntry.asm			; entry point,jump tab
include	vidcomOutput.asm		; common output routines
include	vidcomChars.asm			; common character output routines
include	dumbcomGenChar.asm		; routines for larger characters
include vidcomFont.asm			; special code for chars
include vidcomUnder.asm			; save under routines
include	vidcomUtils.asm			; utility routines
include vidcomRegion.asm		; common region routines
include vidcomXOR.asm			; xor region support
include vidcomInfo.asm			; device naming/setting
include	vidcomEscape.asm		; support for some escape codes
include vidcomPalette.asm		; support for VidGetPixel
include	dumbcomOutput.asm		; output routines
include dumbcomUtils.asm		; misc utility routines
include	dumbcomChars.asm		; character drawing routines
include dumbcomPointer.asm		; pointer support
include dumbcomPalette.asm		; color tables
include	hgcEscTab.asm			; define the escape function jump table

idata	ends

;------------------------------------------------------------------------------
;			Movable Code
;------------------------------------------------------------------------------

include vidcomPolygon.asm		; polygon drawing
include	vidcomLine.asm			; line drawing routine
include	vidcomPutLine.asm		; rotated bitmap support
include vidcomRaster.asm		; raster routines
include vidcomExclBounds.asm	; bounds accumulation
include dumbcomRaster.asm		; raster routines
include	hgcAdmin.asm			; misc admin routines

	end
