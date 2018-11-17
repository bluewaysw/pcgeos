
COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1988 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		SVGA screen driver
FILE:		svga.asm

AUTHOR:		Jim DeFrisco


REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Jim	9/90	initial version

DESCRIPTION:
	This driver is for all of the Super VGA 800x600 16-color modes.

	$Id: svgaManager.asm,v 1.1 97/04/18 11:42:25 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

;--------------------------------------
;		Include files
;--------------------------------------

_VideoDriver		=	1
VIDEO_STACK_SIZE	equ	512	; set size of local stack

include		vidcomGeode.def		; common includes

;---------------------------------------------------------------------
;		Constants and Macros
;---------------------------------------------------------------------

include svgaConstant.def
include vgacomConstant.def
include vidcomConstant.def

include vgacomMacro.def
include vidcomMacro.def

;------------------------------------------------------------------------------
;			Variables
;------------------------------------------------------------------------------
idata	segment

include	svgaDevInfo.asm			; device info block
include	vidcomTables.asm			; common tables
include	svgaTables.asm			; important tabular information

idata	ends


udata	segment

include vidcomVariable.def
include	vgacomVariable.def			; local buffer space

udata	ends


;------------------------------------------------------------------------------
;			Extended Device Info
;------------------------------------------------------------------------------

VideoDevices	segment	lmem LMEM_TYPE_GENERAL
include	svgaStringTab.asm		; device names
VideoDevices	ends

;------------------------------------------------------------------------------
;			Fixed Code
;------------------------------------------------------------------------------

idata 		segment 

include	vidcomEntry.asm			; entry point,jump tab
include	vidcomOutput.asm		; common output routines
include	vidcomChars.asm			; common character output routines
include	vgacomGenChar.asm		; routines for larger characters
include vidcomFont.asm			; routines for building, rotating chars
include vidcomUnder.asm			; save under routines
include	vidcomUtils.asm			; utility routines
include	vidcomRegion.asm		; region drawing routine
include vidcomXOR.asm			; xor region support
include vidcomInfo.asm			; device naming/setting
include	vidcomEscape.asm		; support for some escape codes
include	vidcomDither.asm		; dither patterns
include vidcomPalette.asm		; support for VidGetPixel
include	vgacomOutput.asm		; output routines
include vgacomUtils.asm			; misc utility routines
include	vgacomChars.asm			; character drawing routines
include vgacomPointer.asm		; pointer support
include vgacomPalette.asm		; color palette table
include	svgaEscTab.asm			; escape code jump table
include svgaPalette.asm			; color escape support

idata		ends

;------------------------------------------------------------------------------
;			Movable Code
;------------------------------------------------------------------------------

include vidcomPolygon.asm		; polygon drawing
include	vidcomLine.asm			; line drawing routine
include	vidcomPutLine.asm		; line drawing routine
include vidcomRaster.asm		; raster primitive support
include vidcomExclBounds.asm		; bounds accumulation	
include vgacomRaster.asm		; raster primitive support
include vgacomTables.asm		; common tables
include	svgaAdmin.asm			; misc admin routines

	end
