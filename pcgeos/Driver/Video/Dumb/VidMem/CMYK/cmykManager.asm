
COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		Video driver
FILE:		cmykManager.asm

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

	$Id: cmykManager.asm,v 1.1 97/04/18 11:43:07 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

;--------------------------------------
;		Include files
;--------------------------------------

_VideoDriver		=	1

IS_CMYK			=	1
MEM_CMYK		=	1
IS_BITMAP		=	1

VIDEO_STACK_SIZE	equ	512	; set size of local stack

include	vidmemGeode.def				; common includes
include vidmemConstant.def			; common constants

if _CMYK
	; since we're going to have our own stack, we need some
	; ThreadPrivateData area to be well behaved.
cmykdata        segment
	ThreadPrivateData <>
cmykdata        ends

	; This will enable us to access the dgroup variables with
	; ss:[ ] in those cases.
CMYKStack        segment word public 'BSS'
vidStackBot     label   byte
		byte    VIDEO_STACK_SIZE dup (?)
endVidStack     label   byte
CMYKStack        ends
endif	; if _CMYK

cmykgroup       group   cmykdata, cmykcode, CMYKStack

assume  ss:cmykgroup, ds:nothing, es:nothing

;---------------------------------------------------------------------
;			Constants and Macros
;---------------------------------------------------------------------

include cmykConstant.def
include vidcomConstant.def
include vidmemResource.def

include cmykMacro.def
include	dumbcomMacro.def
include	vidmemMacro.def
include vidcomMacro.def


if _CMYK
;------------------------------------------------------------------------------
;			Variables
;------------------------------------------------------------------------------

cmykcode	segment	resource

include	cmykTables.asm			; important tabular information

cmykcode	ends


cmykdata	segment	resource

include vidcomVariable.def
include vidmemVariable.def
;include dumbcolorVariable.def
include dumbcomVariable.def
include cmykVariable.def

cmykdata	ends

;------------------------------------------------------------------------------
;			Fixed Code
;------------------------------------------------------------------------------

cmykcode segment 	resource

include	vidcomOutput.asm		; common output routines
include	vidcomChars.asm			; common character output routines
include	cmykGenChar.asm			; routines for larger chars
include vidcomFont.asm			; routines for building, rotating chars
include	vidcomUtils.asm			; utility routines
include	vidcomRegion.asm		; region drawing routine
include	vidcomEscape.asm		; support for some escape codes
include vidcomPalette.asm		; support for VidGetPixel
include cmykCluster.asm			; rectangle and char low-level drawing
include	cmykEscTab.asm			; escape code jump table
include cmykPalette.asm			; color palette table
include cmykEntry.asm			; color palette table
include cmykUtils.asm			; dither setting routine
include cmykColor.asm			; color escape support
include vidmemUtils.asm			; HugeArray related utilities

cmykcode ends

;------------------------------------------------------------------------------
;			Moveable Code
;------------------------------------------------------------------------------

include vidcomPolygon.asm	 	; polygon drawing
include	vidcomLine.asm			; line drawing routine
include	vidcomPutLine.asm		; line drawing routine
include vidcomRaster.asm		; raster primitive support
include cmykDither.asm			; dither matrices
include cmykColorRaster.asm		; 4-,8-,24-bit/pixel color bitmaps
include	cmykRaster.asm			; monochrome bitmap drawing

else	; files included for the mono VidMem

include	cmykDither.asm			; dither matrices

endif	; if _CMYK

end

