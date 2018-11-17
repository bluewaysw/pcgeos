COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		Video driver
FILE:		clr8Manager.asm

AUTHOR:		Jim DeFrisco


REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Jim	12/91	initial version

DESCRIPTION:
	This file contains the source for the VGA screen driver.  There
	are a number of actual files included in this one that actually 
	contain the actual source code.  They are located in the VGA and EGA
	directories.
		
	The complete specification for screen drivers can be found on the 
	system in the pcgeos spec directory (/staff/pcgeos/Spec).  

	$Id: clr8Manager.asm,v 1.1 97/04/18 11:43:00 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;--------------------------------------
;		Include files
;--------------------------------------

_VideoDriver		=	1

IS_CLR8			=	1
MEM_CLR8		=	1
IS_BITMAP		=	1

VIDEO_STACK_SIZE	equ	512	; set size of local stack

include	vidmemGeode.def				; common includes
include vidmemConstant.def			; common constants

if _8BIT
	; since we're going to have our own stack, we need some
	; ThreadPrivateData area to be well behaved.
clr8data        segment
	ThreadPrivateData <>
clr8data        ends

	; This will enable us to access the dgroup variables with
	; ss:[ ] in those cases.
Clr8Stack        segment word public 'BSS'
vidStackBot     label   byte
		byte    VIDEO_STACK_SIZE dup (?)
endVidStack     label   byte
Clr8Stack        ends
endif		; if _8BIT


clr8group       group   clr8data, Clr8, Clr8Stack

assume  ss:clr8group, ds:nothing, es:nothing

;---------------------------------------------------------------------
;			Constants and Macros
;---------------------------------------------------------------------

include clr8Constant.def
include vidcomConstant.def
include	vidmemResource.def

include clr8Macro.def
include vidmemMacro.def
include	dumbcomMacro.def
include vidcomMacro.def

if _8BIT
;------------------------------------------------------------------------------
;			Variables
;------------------------------------------------------------------------------

Clr8	segment	resource

include	clr8Tables.asm			; important tabular information

Clr8	ends


clr8data	segment	resource

include vidcomVariable.def
include vidmemVariable.def
include clr8Variable.def

clr8data	ends

;------------------------------------------------------------------------------
;			Fixed Code
;------------------------------------------------------------------------------

Clr8 segment 	resource

include	vidcomOutput.asm		; common output routines
include	vidcomChars.asm			; common character output routines
include vidcomFont.asm			; routines for building, rotating chars
include	vidcomUtils.asm			; utility routines
include	vidcomRegion.asm		; region drawing routine
include	vidcomEscape.asm		; support for some escape codes
include vidcomPalette.asm		; support for VidGetPixel
include	clr8Output.asm			; output routines
include	clr8GenChar.asm			; routines for larger characters
include	clr8Chars.asm			; character drawing routines
include clr8Dither.asm			; dither generation tables
include	clr8EscTab.asm			; escape code jump table
include clr8Palette.asm			; color palette table
include clr8Entry.asm			; color palette table
include clr8Utils.asm			; misc utilities
include vidmemUtils.asm			; HugeArray related utilities

Clr8 ends

;------------------------------------------------------------------------------
;			Moveable Code
;------------------------------------------------------------------------------

include vidcomPolygon.asm	 	; polygon drawing
include	vidcomLine.asm			; line drawing routine
include	vidcomPutLine.asm		; line drawing routine
include vidcomRaster.asm		; raster primitive support
include clr8Raster.asm			; low level bitmap routines
endif	; if _8BIT

end
