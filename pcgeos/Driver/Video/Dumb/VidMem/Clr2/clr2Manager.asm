COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	PC GEOS
MODULE:		VidMem/Clr2
FILE:		clr2Manager.asm

AUTHOR:		Joon Song, Oct 7, 1996

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	10/7/96   	Initial revision


DESCRIPTION:
	

	$Id: clr2Manager.asm,v 1.1 97/04/18 11:43:11 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;--------------------------------------
;		Include files
;--------------------------------------

_VideoDriver		=	1

IS_CLR2			=	1
MEM_CLR2		=	1
IS_BITMAP		=	1
BIT_CLR2		=	1

VIDEO_STACK_SIZE	equ	512	; set size of local stack

include	vidmemGeode.def				; common includes
include vidmemConstant.def			; common constants

if _2BIT
	; since we're going to have our own stack, we need some
	; ThreadPrivateData area to be well behaved.
clr2data        segment
	ThreadPrivateData <>
clr2data        ends

	; This will enable us to access the dgroup variables with
	; ss:[ ] in those cases.
Clr2Stack        segment word public 'BSS'
vidStackBot     label   byte
		byte    VIDEO_STACK_SIZE dup (?)
endVidStack     label   byte
Clr2Stack        ends
endif		; if _2BIT


clr2group       group   clr2data, Clr2, Clr2Stack

assume  ss:clr2group, ds:nothing, es:nothing

;---------------------------------------------------------------------
;			Constants and Macros
;---------------------------------------------------------------------

include clr2Constant.def
include vidcomConstant.def
include	vidmemResource.def

include clr2Macro.def
include vidmemMacro.def
include	dumbcomMacro.def
include vidcomMacro.def

if _2BIT
;------------------------------------------------------------------------------
;			Variables
;------------------------------------------------------------------------------

Clr2	segment	resource

include	clr2Tables.asm			; important tabular information

Clr2	ends


clr2data	segment	resource

include vidcomVariable.def
include vidmemVariable.def
include dumbcomVariable.def
include clr2Variable.def

clr2data	ends

;------------------------------------------------------------------------------
;			Fixed Code
;------------------------------------------------------------------------------

Clr2 segment 	resource

include	vidcomOutput.asm		; common output routines
include	vidcomChars.asm			; common character output routines
include	clr2GenChar.asm			; routines for larger chars
include vidcomFont.asm			; routines for building, rotating chars
include	vidcomUtils.asm			; utility routines
include	vidcomRegion.asm		; region drawing routine
include	vidcomEscape.asm		; support for some escape codes
include	vidcomDither.asm		; 4-bit color dither tables
include vidcomPalette.asm		; support for VidGetPixel
include	clr2EscTab.asm			; escape code jump table
include clr2Palette.asm			; color palette table
include clr2Entry.asm			; color palette table
include clr2Utils.asm			; misc utilities
include clr2Output.asm			; basic output routines
include clr2Chars.asm			; low level char drawing
include vidmemUtils.asm		; HugeArray related utilities

Clr2 ends

;------------------------------------------------------------------------------
;			Moveable Code
;------------------------------------------------------------------------------

include vidcomPolygon.asm	 	; polygon drawing
include	vidcomLine.asm			; line drawing routine
include	vidcomPutLine.asm		; line drawing routine
include vidcomRaster.asm		; raster primitive support
include clr2Raster.asm			; low level bitmap routines
endif		; if _2BIT

end
