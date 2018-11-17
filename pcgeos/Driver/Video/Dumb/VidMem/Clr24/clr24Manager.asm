
COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		Video driver
FILE:		clr24Manager.asm

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

	$Id: clr24Manager.asm,v 1.1 97/04/18 11:43:02 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

;--------------------------------------
;		Include files
;--------------------------------------

_VideoDriver		=	1

IS_CLR24		=	1
MEM_CLR24		=	1
IS_BITMAP		=	1

VIDEO_STACK_SIZE	equ	512	; set size of local stack

include	vidmemGeode.def				; common includes
include vidmemConstant.def			; common includes

if _24BIT
	; since we're going to have our own stack, we need some
	; ThreadPrivateData area to be well behaved.
clr24data        segment
	ThreadPrivateData <>
clr24data        ends

	; This will enable us to access the dgroup variables with
	; ss:[ ] in those cases.
VidStack        segment word public 'BSS'
vidStackBot     label   byte
		byte    VIDEO_STACK_SIZE dup (?)
endVidStack     label   byte
VidStack        ends

ForceRef	endVidStack
ForceRef	vidStackBot
endif		; if _24BIT


clr24group       group   clr24data, Clr24, VidStack

assume  ss:clr24group, ds:nothing, es:nothing

;---------------------------------------------------------------------
;			Constants and Macros
;---------------------------------------------------------------------

include clr24Constant.def
include vidcomConstant.def
include	vidmemResource.def

include clr24Macro.def
include vidmemMacro.def
include	dumbcomMacro.def
include vidcomMacro.def


if _24BIT
;------------------------------------------------------------------------------
;			Variables
;------------------------------------------------------------------------------

Clr24	segment	resource

include	clr24Tables.asm			; important tabular information

Clr24	ends


clr24data	segment	resource

include vidcomVariable.def
include vidmemVariable.def
include clr24Variable.def

clr24data	ends

;------------------------------------------------------------------------------
;			Fixed Code
;------------------------------------------------------------------------------

Clr24 segment 	resource

include	vidcomOutput.asm		; common output routines
include	vidcomChars.asm			; common character output routines
include vidcomFont.asm			; routines for building, rotating chars
include	vidcomUtils.asm			; utility routines
include	vidcomRegion.asm		; region drawing routine
include	vidcomEscape.asm		; support for some escape codes
include vidcomPalette.asm		; support for VidGetPixel
include	clr24Output.asm			; output routines
include	clr24GenChar.asm		; routines for larger characters
include	clr24Chars.asm			; character drawing routines
include	clr24EscTab.asm			; escape code jump table
include clr24Entry.asm			; color palette table
include clr24Palette.asm		; color palette table
include vidmemUtils.asm			; HugeArray related utilities

Clr24 ends

;------------------------------------------------------------------------------
;			Moveable Code
;------------------------------------------------------------------------------

include vidcomPolygon.asm	 	; polygon drawing
include	vidcomLine.asm			; line drawing routine
include	vidcomPutLine.asm		; line drawing routine
include vidcomRaster.asm		; raster primitive support
include clr24Raster.asm			; low level bitmap routines

endif		; if _24BIT

end
