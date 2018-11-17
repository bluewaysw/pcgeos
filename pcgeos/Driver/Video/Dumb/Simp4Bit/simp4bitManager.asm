
COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		Video driver
FILE:		simp4bitManager.asm

AUTHOR:		Jim DeFrisco


REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Jim	12/91	initial version

DESCRIPTION:

	$Id: simp4bitManager.asm,v 1.1 97/04/18 11:43:47 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

;--------------------------------------
;		Include files
;--------------------------------------

_VideoDriver		=	1

IS_CLR4			=	1
BIT_CLR4		=	1
IS_BITMAP		=	1

ifidn	PRODUCT, <BOR1>
USE_186			= 	1
LEFT_PIXEL_IN_LOW_NIBBLE	=	TRUE
INVERTED_CLR4		=	1	;If BLACK = 0xf, and WHITE = 0x0
.186

endif

ifdef	WIN32
.386
endif
;
; Set if your video controller is some ass-backward device that has its
; leftmost pixels in the low nibble of each byte in the frame buffer.
;

ifdef	LEFT_PIXEL_IN_LOW_NIBBLE
MASK_FOR_RIGHTMOST_PIXEL_IN_BYTE	=	0xf0
MASK_FOR_LEFTMOST_PIXEL_IN_BYTE		=	0x0f
else
MASK_FOR_RIGHTMOST_PIXEL_IN_BYTE	=	0x0f
MASK_FOR_LEFTMOST_PIXEL_IN_BYTE		=	0xf0
endif

VIDEO_STACK_SIZE	equ	512	; set size of local stack

include	vidcomGeode.def				; common includes

;---------------------------------------------------------------------
;			Constants and Macros
;---------------------------------------------------------------------

include simp4bitConstant.def
include clr4Constant.def
include vidcomConstant.def

include clr4Macro.def
include simp4bitMacro.def
include	dumbcomMacro.def
include vidcomMacro.def

if	_BOR1
include	Internal/E3G.def
endif

;------------------------------------------------------------------------------
;			Variables
;------------------------------------------------------------------------------

idata	segment	

include	simp4bitDevInfo.asm			; device info block
include vidcomTables.asm
include simp4bitTables.asm

idata	ends


udata	segment	

include vidcomVariable.def
include dumbcomVariable.def
include clr4Variable.def
include simp4bitVariable.def

udata	ends

VideoDevices	segment	lmem LMEM_TYPE_GENERAL
include simp4bitStringTab.asm	;define device strings	
VideoDevices	ends

;------------------------------------------------------------------------------
;			Fixed Code
;------------------------------------------------------------------------------

idata segment 	

include vidcomEntry.asm			; entry point, jump table
include	vidcomOutput.asm		; common output routines
include	vidcomChars.asm			; common character output routines
include	clr4GenChar.asm			; routines for larger chars
include vidcomFont.asm			; routines for building, rotating chars
include vidcomUnder.asm			; save under routines ***	
include	vidcomUtils.asm			; utility routines
include	vidcomRegion.asm		; region drawing routine ***
include vidcomXOR.asm			; xor region support   ***
include vidcomInfo.asm			; device info routines ***
include	vidcomEscape.asm		; support for some escape codes
include	vidcomDither.asm		; 4-bit color dither tables
include vidcomPalette.asm		; support for VidGetPixel
include	simp4bitEscTab.asm		; escape code jump table
include clr4Palette.asm			; color palette table
include simp4bitPalette.asm		; sets the palette for the device
include clr4Utils.asm			; misc utilities
include clr4Output.asm			; basic output routines
include clr4Chars.asm			; low level char drawing
include dumbcomPointer.asm		; pointer support
include simp4bitPointer.asm		; pointer support

idata ends

;------------------------------------------------------------------------------
;			Moveable Code
;------------------------------------------------------------------------------

include vidcomPolygon.asm	 	; polygon drawing
include	vidcomLine.asm			; line drawing routine
include	vidcomPutLine.asm		; line drawing routine
include vidcomRaster.asm		; raster primitive support
include vidcomExclBounds.asm		; bounds accumulation
include simp4bitRaster.asm		; low level bitmap routines
include simp4bitAdmin.asm
end
