
COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1988 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		Video driver
FILE:		vgaManager.asm

AUTHOR:		Jim DeFrisco


REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Jim	12/88	initial version

DESCRIPTION:
	This file contains the source for the VGA screen driver.  There
	are a number of actual files included in this one that actually 
	contain the actual source code.  They are located in the VGA and EGA
	directories.
		
	The complete specification for screen drivers can be found on the 
	system in the pcgeos spec directory (/staff/pcgeos/Spec).  

	$Id: vgaManager.asm,v 1.1 97/04/18 11:41:58 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

;--------------------------------------
;		Include files
;--------------------------------------

_VideoDriver		=	1
VIDEO_STACK_SIZE	equ	512	; set size of local stack

include	vidcomGeode.def			; common video driver stuff

;---------------------------------------------------------------------
;			Constants and Macros
;---------------------------------------------------------------------

include vgaConstant.def
include vgacomConstant.def
include vidcomConstant.def

include vgacomMacro.def
include vidcomMacro.def

;------------------------------------------------------------------------------
;			Variables
;------------------------------------------------------------------------------
idata	segment

include	vgaDevInfo.asm			; device info block
include	vidcomTables.asm		; common tables
include	vgaTables.asm			; important tabular information

idata	ends


udata	segment

include vidcomVariable.def
include	vgacomVariable.def		; local buffer space

udata	ends

;------------------------------------------------------------------------------
;			Extended Device Info
;------------------------------------------------------------------------------

VideoDevices	segment	lmem LMEM_TYPE_GENERAL
include	vgaStringTab.asm		; device names
VideoDevices	ends

;------------------------------------------------------------------------------
;			Fixed Code
;------------------------------------------------------------------------------

idata segment 

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
include	vidcomDither.asm		; dither support
include vidcomPalette.asm		; support for VidGetPixel
include	vgacomOutput.asm		; output routines
include vgacomUtils.asm			; misc utility routines
include	vgacomChars.asm			; character drawing routines
include vgacomPointer.asm		; pointer support
include vgacomPalette.asm		; color palette table
include	vgaEscTab.asm			; escape code jump table
include vgaPalette.asm			; color escape support

idata ends

;------------------------------------------------------------------------------
;			Moveable Code
;------------------------------------------------------------------------------

include vidcomPolygon.asm	 	; polygon drawing
include	vidcomLine.asm			; line drawing routine
include	vidcomPutLine.asm			; line drawing routine
include vidcomRaster.asm		; raster primitive support
include vidcomExclBounds.asm	; bounds accumulation
include vgacomRaster.asm		; raster primitive support
include vgacomTables.asm		; common tables
include	vgaAdmin.asm			; misc admin routines

end
