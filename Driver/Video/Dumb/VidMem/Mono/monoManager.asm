COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		Mono module of vidmem video driver
FILE:		monoManager.asm

AUTHOR:		Jim DeFrisco


REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Jim	12/91	initial version

DESCRIPTION:
	This file contains the source for the Mono module of vidmem screen 
	driver.  

	$Id: monoManager.asm,v 1.1 97/04/18 11:42:41 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

;--------------------------------------
;		Include files
;--------------------------------------

_VideoDriver		=	1		; identify as video driver

MEM_MONO		=	1		; identify as VidMem mono mod

VIDEO_STACK_SIZE	equ	512		; size of local stack

include	vidmemGeode.def				; common includes
include vidmemResource.def

	; since we're going to have our own stack, we need some
	; ThreadPrivateData area to be well behaved.
monodata        segment
	ThreadPrivateData <>
monodata        ends

	; This will enable us to access the dgroup variables with
	; ss:[ ] in those cases.
MonoStack        segment word public 'BSS'
vidStackBot     label   byte
		byte    VIDEO_STACK_SIZE dup (?)
endVidStack     label   byte
MonoStack        ends

monogroup       group   monodata, Mono, MonoStack

assume  ss:monogroup, ds:nothing, es:nothing

;---------------------------------------------------------------------
;		Constants and Macros
;---------------------------------------------------------------------

include vidmemConstant.def
include monoConstant.def
include dumbcomConstant.def
include vidcomConstant.def

include monoMacro.def
include vidmemMacro.def
include dumbcomMacro.def
include vidcomMacro.def

;------------------------------------------------------------------------------
;			Variables
;------------------------------------------------------------------------------
Mono	segment	resource

include monoTables.asm		; Tables for Mono module of vidmem driver
include	dumbcomTables.asm		; important tabular information

Mono	ends


monodata	segment	

include vidcomVariable.def
include vidmemVariable.def
include	dumbcomVariable.def		; local buffer space
include	monoVariable.def		; variables local to this driver

monodata	ends


;------------------------------------------------------------------------------
;			Main module Code
;------------------------------------------------------------------------------

Mono segment 	resource

include	vidcomOutput.asm	; common output routines
include	vidcomChars.asm		; common character output routines
include	monoGenChar.asm		; routine for larger chars
include vidcomFont.asm		; routines for building, rotating chars
include	vidcomUtils.asm		; utility routines
include	vidcomRegion.asm	; region drawing routines
include	vidcomEscape.asm	; support for some escape codes
include vidcomPalette.asm		; support for VidGetPixel
include	dumbcomOutput.asm	; output routines
include dumbcomUtils.asm	; misc utility routines
include	dumbcomChars.asm	; character drawing routines
include dumbcomPalette.asm	; very small palette
include	monoEscTab.asm		; escape routine jump table
include	monoEntry.asm		; entry point for Mono module
include monoCluster.asm		; for cluster mode dithering
include monoUtils.asm		; misc utilities
include monoEscape.asm		; color transfer function
include vidmemUtils.asm		; HugeArray related utilities

Mono ends

;------------------------------------------------------------------------------
;			Other Modules
;------------------------------------------------------------------------------

include vidcomPolygon.asm	; polygon drawing routines
include	vidcomLine.asm		; line drawing routine
include	vidcomPutLine.asm	; line drawing routine
include vidcomRaster.asm	; raster routines
include dumbcomRaster.asm	; raster routines

	end
