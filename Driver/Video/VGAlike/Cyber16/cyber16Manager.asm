COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GlobalPC 1998 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		Cyber16 Video Driver
FILE:		cyber16Manager.asm

AUTHOR:		Jim DeFrisco


REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Jim	10/92	initial version
	FR	9/97	Initial 16-bit version	

DESCRIPTION:
	This driver is for the 16-bit CyberPro modes

	$Id: cyber16Manager.asm,v 1.2$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;--------------------------------------
;		Include files
;--------------------------------------

_VideoDriver		=	1
VIDEO_STACK_SIZE	equ	512	; set size of local stack

include vidcomGeode.def			; common includes
include	assert.def
include initfile.def

;---------------------------------------------------------------------
;		Constants and Macros
;---------------------------------------------------------------------

include cyber16Constant.def
include vidcomConstant.def

include cyber16Macro.def
include vidcomMacro.def

;------------------------------------------------------------------------------
;			Variables
;------------------------------------------------------------------------------
idata	segment

include cyber16DevInfo.asm		; device info block
include vidcomTables.asm		; common tables
include cyber16Tables.asm		; important tabular information

idata	ends


udata	segment

include vidcomVariable.def
include cyber16Variable.def		; local buffer space

udata	ends


;------------------------------------------------------------------------------
;			Extended Device Info
;------------------------------------------------------------------------------

VideoDevices	segment	lmem LMEM_TYPE_GENERAL
include cyber16StringTab.asm		; device names
VideoDevices	ends

;------------------------------------------------------------------------------
;			Fixed Code
;------------------------------------------------------------------------------

idata 		segment 

include vidcomEntry.asm			; entry point,jump tab
include vidcomOutput.asm		; common output routines
include vidcomChars.asm			; common character output routines
include vidcomFont.asm			; routines for building, rotating chars
include vidcomUnder.asm			; save under routines
;include vga16Under.asm			; null save under set
include vidcomUtils.asm			; utility routines
include vidcomRegion.asm		; region drawing routine
include vidcomXOR.asm			; xor region support
include vidcomInfo.asm			; device naming/setting
include vidcomEscape.asm		; support for some escape codes
include	cyber16Escape.asm		; local escapes
include vidcomPalette.asm		; support for VidGetPixel
include vga16Output.asm			; output routines
include vga16GenChar.asm		; routines for larger characters
include cyber16Utils.asm		; misc utility routines
include vga16Chars.asm			; character drawing routines
include cyber16Pointer.asm		; pointer support
include cyber16EscTab.asm		; escape code jump table
include cyber16Palette.asm		; color palette table
include vga16Dither.asm			; dither cutoff matrix

idata		ends

;------------------------------------------------------------------------------
;			Movable Code
;------------------------------------------------------------------------------

include vidcomPolygon.asm		; polygon drawing
include vidcomLine.asm			; line drawing routine
include vidcomPutLine.asm		; line drawing routine
include vidcomRaster.asm		; raster primitive support
include vga16Raster.asm			; raster primitive support
include cyber16Admin.asm		; misc admin routines
include vidcomExclBounds.asm		; bounds calculating code

	end
