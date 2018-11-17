COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		VGA8 screen driver
FILE:		vga8.asm

AUTHOR:		Jim DeFrisco


REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Jim	10/92	initial version

DESCRIPTION:
	This driver is for the 8-bit super VGA modes

	$Id: vga8Manager.asm,v 1.1 97/04/18 11:42:01 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

;--------------------------------------
;		Include files
;--------------------------------------

_VideoDriver		=	1
VIDEO_STACK_SIZE	equ	512	; set size of local stack

include	vidcomGeode.def			; common includes
include	initfile.def

;---------------------------------------------------------------------
;		Constants and Macros
;---------------------------------------------------------------------

include vga8Constant.def
include vidcomConstant.def

include vga8Macro.def
include vidcomMacro.def

;------------------------------------------------------------------------------
;			Variables
;------------------------------------------------------------------------------
idata	segment

include	vga8DevInfo.asm			; device info block
include	vidcomTables.asm		; common tables
include	vga8Tables.asm			; important tabular information

idata	ends


udata	segment

include vidcomVariable.def
include	vga8Variable.def		; local buffer space

udata	ends


;------------------------------------------------------------------------------
;			Extended Device Info
;------------------------------------------------------------------------------

VideoDevices	segment	lmem LMEM_TYPE_GENERAL
include	vga8StringTab.asm		; device names
VideoDevices	ends

;------------------------------------------------------------------------------
;			Fixed Code
;------------------------------------------------------------------------------

idata 		segment 

include	vidcomEntry.asm			; entry point,jump tab
include	vidcomOutput.asm		; common output routines
include	vidcomChars.asm			; common character output routines
include vidcomFont.asm			; routines for building, rotating chars
;include vidcomUnder.asm		; save under routines
include vga8Under.asm			; null save under set
include	vidcomUtils.asm			; utility routines
include	vidcomRegion.asm		; region drawing routine
include vidcomXOR.asm			; xor region support
include vidcomInfo.asm			; device naming/setting
include	vidcomEscape.asm		; support for some escape codes
include vidcomPalette.asm		; support for VidGetPixel
include	vga8Output.asm			; output routines
include	vga8GenChar.asm			; routines for larger characters
include vga8Utils.asm			; misc utility routines
include	vga8Chars.asm			; character drawing routines
include vga8Pointer.asm			; pointer support
include	vga8EscTab.asm			; escape code jump table
include vga8Palette.asm			; color palette table
include vga8Dither.asm			; dither generation tables

idata		ends

;------------------------------------------------------------------------------
;			Movable Code
;------------------------------------------------------------------------------

include vidcomPolygon.asm		; polygon drawing
include	vidcomLine.asm			; line drawing routine
include	vidcomPutLine.asm		; line drawing routine
include vidcomRaster.asm		; raster primitive support
include vga8Raster.asm			; raster primitive support
include	vga8Admin.asm			; misc admin routines
include	vidcomExclBounds.asm		; bounds calculating code

	end
