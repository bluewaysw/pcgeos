COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	PC GEOS
MODULE:		Simp2Bit video driver
FILE:		simp2bitManager.asm

AUTHOR:		Joon Song, Oct 7, 1996

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	10/7/96   	Initial revision


DESCRIPTION:
	

	$Id: simp2bitManager.asm,v 1.1 97/04/18 11:43:53 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;--------------------------------------
;		Include files
;--------------------------------------

_VideoDriver		=	1

IS_CLR2			=	1
BIT_CLR2		=	1
IS_BITMAP		=	1
USE_186			= 	1

.386					; This driver uses 386 instructions



VIDEO_STACK_SIZE	equ	512	; set size of local stack

include	vidcomGeode.def			; common includes

;---------------------------------------------------------------------
;			Constants and Macros
;---------------------------------------------------------------------

include simp2bitConstant.def
include clr2Constant.def
include vidcomConstant.def

include clr2Macro.def
include simp2bitMacro.def
include	dumbcomMacro.def
include vidcomMacro.def


;------------------------------------------------------------------------------
;			Variables
;------------------------------------------------------------------------------

idata	segment	

include	simp2bitDevInfo.asm		; device info block
include vidcomTables.asm
include simp2bitTables.asm

idata	ends


udata	segment	

include vidcomVariable.def
include dumbcomVariable.def
include simp2bitVariable.def

udata	ends

VideoDevices	segment	lmem LMEM_TYPE_GENERAL
include simp2bitStringTab.asm	;define device strings	
VideoDevices	ends

;------------------------------------------------------------------------------
;			Fixed Code
;------------------------------------------------------------------------------

idata segment 	

include vidcomEntry.asm			; entry point, jump table
include	vidcomOutput.asm		; common output routines
include	vidcomChars.asm			; common character output routines
include	clr2GenChar.asm			; routines for larger chars
include vidcomFont.asm			; routines for building, rotating chars
include vidcomUnder.asm			; save under routines ***	
include	vidcomUtils.asm			; utility routines
include	vidcomRegion.asm		; region drawing routine ***
include vidcomXOR.asm			; xor region support   ***
include vidcomInfo.asm			; device info routines ***
include	vidcomEscape.asm		; support for some escape codes
include	vidcomDither.asm		; 4-bit color dither tables
include vidcomPalette.asm		; support for VidGetPixel
include	simp2bitEscTab.asm		; escape code jump table
include clr2Palette.asm			; color palette table
include simp2bitPalette.asm		; sets the palette for the device
include clr2Utils.asm			; misc utilities
include clr2Output.asm			; basic output routines
include clr2Chars.asm			; low level char drawing
include simp2bitPointer.asm		; pointer support
include simp2bitEscape.asm		; local escapes

idata ends

;------------------------------------------------------------------------------
;			Moveable Code
;------------------------------------------------------------------------------

include vidcomPolygon.asm	 	; polygon drawing
include	vidcomLine.asm			; line drawing routine
include	vidcomPutLine.asm		; line drawing routine
include vidcomRaster.asm		; raster primitive support
include vidcomExclBounds.asm		; bounds accumulation
include clr2Raster.asm
include simp2bitAdmin.asm
end
