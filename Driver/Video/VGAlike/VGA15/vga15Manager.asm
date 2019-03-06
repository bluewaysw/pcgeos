COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:         VGA15 screen driver
FILE:           vga15Manager.asm

AUTHOR:		Jim DeFrisco


REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Jim	10/92	initial version
        FR       9/97   Initial 16-bit version        

DESCRIPTION:
        This driver is for the 15-bit super VGA modes

	$Id: vga15Manager.asm,v 1.2 96/08/05 03:51:35 canavese Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

;--------------------------------------
;		Include files
;--------------------------------------

_VideoDriver		=	1
VIDEO_STACK_SIZE	equ	512	; set size of local stack

include         vidcomGeode.def             ; common includes


;---------------------------------------------------------------------
;		Constants and Macros
;---------------------------------------------------------------------

include vga15Constant.def
include vidcomConstant.def

include vga15Macro.def
include vidcomMacro.def

;------------------------------------------------------------------------------
;			Variables
;------------------------------------------------------------------------------
idata	segment

include vga15DevInfo.asm                ; device info block
include vidcomTables.asm                ; common tables
include vga15Table.asm                  ; important tabular information

idata	ends


udata	segment

include vidcomVariable.def
include vga15Variable.def               ; local buffer space

udata	ends


;------------------------------------------------------------------------------
;			Extended Device Info
;------------------------------------------------------------------------------

VideoDevices	segment	lmem LMEM_TYPE_GENERAL
include vga15StringTab.asm               ; device names
VideoDevices	ends

;------------------------------------------------------------------------------
;			Fixed Code
;------------------------------------------------------------------------------

idata 		segment 

include vidcomEntry.asm                 ; entry point,jump tab
include vidcomOutput.asm                ; common output routines
include vidcomChars.asm                 ; common character output routines
include vidcomFont.asm                  ; routines for building, rotating chars
;include vidcomUnder.asm                ; save under routines
include vga15Under.asm                  ; null save under set
include vidcomUtils.asm                 ; utility routines
include vidcomRegion.asm                ; region drawing routine
include vidcomXOR.asm                   ; xor region support
include vidcomInfo.asm                  ; device naming/setting
include vidcomEscape.asm                ; support for some escape codes
include vidcomPalette.asm               ; support for VidGetPixel
include vga15Output.asm                 ; output routines
include vga15GenChar.asm                ; routines for larger characters
include vga15Utils.asm                  ; misc utility routines
include vga15Chars.asm                  ; character drawing routines
include vga15Pointer.asm                ; pointer support
include vga15EscTab.asm                 ; escape code jump table
include vga15Palette.asm                ; color palette table
include vga15Dither.asm                 ; dither cutoff matrix

idata		ends

;------------------------------------------------------------------------------
;			Movable Code
;------------------------------------------------------------------------------

include vidcomPolygon.asm               ; polygon drawing
include vidcomLine.asm                  ; line drawing routine
include vidcomPutLine.asm               ; line drawing routine
include vidcomRaster.asm                ; raster primitive support
include vga15Raster.asm                 ; raster primitive support
include vga15Admin.asm                  ; misc admin routines
include vidcomExclBounds.asm            ; bounds calculating code

	end
