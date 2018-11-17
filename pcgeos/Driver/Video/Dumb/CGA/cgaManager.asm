COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1988 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		CGA video driver
FILE:		cgaManager.asm

AUTHOR:		Tony Requist


REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Tony	10/88	initial version

DESCRIPTION:
	This file contains the source for the CGA screen driver.  There
	are a number of actual files included in this one that actually 
	contain the actual source code.  They are located in the CGA
	directory.
		
	The complete specification for screen drivers can be found on the 
	system in the pcgeos spec directory (/staff/pcgeos/Spec).  

	$Id: cgaManager.asm,v 1.1 97/04/18 11:42:30 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

;--------------------------------------
;		Include files
;--------------------------------------

_VideoDriver		=	1
VIDEO_STACK_SIZE	equ	512		; size of local stack

include	vidcomGeode.def				; common includes

;---------------------------------------------------------------------
;		Constants and Macros
;---------------------------------------------------------------------

include cgaConstant.def
include dumbcomConstant.def
include vidcomConstant.def

include cgaMacro.def
include dumbcomMacro.def
include vidcomMacro.def

;------------------------------------------------------------------------------
;			Variables
;------------------------------------------------------------------------------
idata	segment

include	dumbcomDevInfo.asm		; device info block
include vidcomTables.asm
include cgaTables.asm		; Tables for CGA driver
include	dumbcomTables.asm		; important tabular information

idata	ends


udata	segment

include vidcomVariable.def
include	dumbcomVariable.def		; local buffer space
include	cgaVariable.def		; variables local to this driver

udata	ends


;------------------------------------------------------------------------------
;			Extended Driver Info
;------------------------------------------------------------------------------
VideoDevices	segment	lmem LMEM_TYPE_GENERAL
include	cgaStringTab.asm	; device names
VideoDevices	ends


;------------------------------------------------------------------------------
;			Fixed Code
;------------------------------------------------------------------------------

idata segment 

include	vidcomEntry.asm		; entry point,jump tab
include	vidcomOutput.asm	; common output routines
include	vidcomChars.asm		; common character output routines
include	dumbcomGenChar.asm	; routines for larger characters
include vidcomFont.asm		; routines for building, rotating chars
include vidcomUnder.asm		; save under routines
include	vidcomUtils.asm		; utility routines
include	vidcomRegion.asm	; region drawing routines
include vidcomXOR.asm		; xor region support
include vidcomInfo.asm		; device info routines
include	vidcomEscape.asm	; support for some escape codes
include vidcomPalette.asm	; support for VidGetPixel
include	dumbcomOutput.asm	; output routines
include dumbcomUtils.asm	; misc utility routines
include	dumbcomChars.asm	; character drawing routines
include dumbcomPointer.asm	; pointer support
include dumbcomPalette.asm	; color tables
include	cgaEscTab.asm		; escape routine jump table

idata ends

;------------------------------------------------------------------------------
;			Movable Code
;------------------------------------------------------------------------------

include vidcomPolygon.asm	; polygon drawing routines
include	vidcomLine.asm		; line drawing routine
include	vidcomPutLine.asm	; line drawing routine
include vidcomRaster.asm	; raster routines
include vidcomExclBounds.asm	; bounds accumulation
include dumbcomRaster.asm	; raster routines
include	cgaAdmin.asm		; misc admin routines
	end
