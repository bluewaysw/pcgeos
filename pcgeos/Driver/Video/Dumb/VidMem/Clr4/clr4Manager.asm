
COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		Video driver
FILE:		clr4Manager.asm

AUTHOR:		Jim DeFrisco


REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Jim	12/91	initial version

DESCRIPTION:

	$Id: clr4Manager.asm,v 1.1 97/04/18 11:42:46 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

;--------------------------------------
;		Include files
;--------------------------------------

_VideoDriver		=	1

IS_CLR4			=	1
MEM_CLR4		=	1
IS_BITMAP		=	1
BIT_CLR4		=	1

MASK_FOR_RIGHTMOST_PIXEL_IN_BYTE	=	0x0f
MASK_FOR_LEFTMOST_PIXEL_IN_BYTE		=	0xf0

VIDEO_STACK_SIZE	equ	512	; set size of local stack

include	vidmemGeode.def				; common includes
include vidmemConstant.def			; common constants

if _4BIT
	; since we're going to have our own stack, we need some
	; ThreadPrivateData area to be well behaved.
clr4data        segment
	ThreadPrivateData <>
clr4data        ends

	; This will enable us to access the dgroup variables with
	; ss:[ ] in those cases.
Clr4Stack        segment word public 'BSS'
vidStackBot     label   byte
		byte    VIDEO_STACK_SIZE dup (?)
endVidStack     label   byte
Clr4Stack        ends
endif		; if _4BIT


clr4group       group   clr4data, Clr4, Clr4Stack

assume  ss:clr4group, ds:nothing, es:nothing

;---------------------------------------------------------------------
;			Constants and Macros
;---------------------------------------------------------------------

include clr4Constant.def
include vidcomConstant.def
include	vidmemResource.def

include clr4Macro.def
include vidmemMacro.def
include	dumbcomMacro.def
include vidcomMacro.def

if _4BIT
;------------------------------------------------------------------------------
;			Variables
;------------------------------------------------------------------------------

Clr4	segment	resource

include	clr4Tables.asm			; important tabular information

Clr4	ends


clr4data	segment	resource

include vidcomVariable.def
include vidmemVariable.def
include dumbcomVariable.def
include clr4Variable.def

clr4data	ends

;------------------------------------------------------------------------------
;			Fixed Code
;------------------------------------------------------------------------------

Clr4 segment 	resource

include	vidcomOutput.asm		; common output routines
include	vidcomChars.asm			; common character output routines
include	clr4GenChar.asm			; routines for larger chars
include vidcomFont.asm			; routines for building, rotating chars
include	vidcomUtils.asm			; utility routines
include	vidcomRegion.asm		; region drawing routine
include	vidcomEscape.asm		; support for some escape codes
include	vidcomDither.asm		; 4-bit color dither tables
include vidcomPalette.asm		; support for VidGetPixel
include	clr4EscTab.asm			; escape code jump table
include clr4Palette.asm			; color palette table
include clr4Entry.asm			; color palette table
include clr4Utils.asm			; misc utilities
include clr4Output.asm			; basic output routines
include clr4Chars.asm			; low level char drawing
include vidmemUtils.asm		; HugeArray related utilities

Clr4 ends

;------------------------------------------------------------------------------
;			Moveable Code
;------------------------------------------------------------------------------

include vidcomPolygon.asm	 	; polygon drawing
include	vidcomLine.asm			; line drawing routine
include	vidcomPutLine.asm		; line drawing routine
include vidcomRaster.asm		; raster primitive support
include clr4Raster.asm			; low level bitmap routines
endif		; if _4BIT

end



