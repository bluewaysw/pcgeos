COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:         VGA24 screen driver
FILE:           vga24Manager.asm

AUTHOR:		Jim DeFrisco


REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Jim	10/92	initial version
        FR       9/97   Initial 24-bit version        

DESCRIPTION:
        This driver is for the 24-bit super VGA modes

        $Id: vga24Manager.asm,v 1.2 96/08/05 03:51:35 canavese Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

;--------------------------------------
;		Include files
;--------------------------------------

_VideoDriver		=	1
VIDEO_STACK_SIZE	equ	512	; set size of local stack

include         vidcomGeode.def         ; common includes


;---------------------------------------------------------------------
;		Constants and Macros
;---------------------------------------------------------------------

include vga24Constant.def
include vidcomConstant.def

include vga24Macro.def
include vidcomMacro.def

;------------------------------------------------------------------------------
;			Variables
;------------------------------------------------------------------------------
idata	segment

include vga24DevInfo.asm                ; device info block
include vidcomTables.asm                ; common tables
include vga24Table.asm                  ; important tabular information

idata	ends


udata	segment

include vidcomVariable.def
include vga24Variable.def                ; local buffer space

udata	ends


;------------------------------------------------------------------------------
;			Extended Device Info
;------------------------------------------------------------------------------

VideoDevices	segment	lmem LMEM_TYPE_GENERAL
include vga24StringTab.asm                    ; device names
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
include vga24Under.asm                  ; null save under set
include vidcomUtils.asm                 ; utility routines
include vidcomRegion.asm                ; region drawing routine
include vidcomXOR.asm                   ; xor region support
include vidcomEscape.asm                ; support for some escape codes
include vidcomPalette.asm               ; support for VidGetPixel
include vga24Output.asm                 ; output routines
include vga24GenChar.asm                ; routines for larger characters
include vga24Utils.asm                  ; misc utility routines
include vga24Chars.asm                  ; character drawing routines
include vga24Pointer.asm                ; pointer support
include vga24EscTab.asm                 ; escape code jump table
include vga24Palette.asm                ; color palette table
include vga24Dither.asm                 ; dither cutoff matrix
include vidcomInfo.asm                  ; device naming/setting

idata		ends

;------------------------------------------------------------------------------
;			Movable Code
;------------------------------------------------------------------------------

include vidcomPolygon.asm               ; polygon drawing
include vidcomLine.asm                  ; line drawing routine
include vidcomPutLine.asm               ; line drawing routine
include vidcomRaster.asm                ; raster primitive support
include vga24Raster.asm                 ; raster primitive support
include vga24Admin.asm                  ; misc admin routines
include vidcomExclBounds.asm            ; bounds calculating code

	end
