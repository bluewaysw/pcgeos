COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1988 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		Video driver
FILE:		egaManager.asm

AUTHOR:		Jim DeFrisco


REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Jim	4/88	initial version

DESCRIPTION:
	This file contains the source for the EGA screen driver.  There
	are a number of actual files included in this one that actually 
	contain the actual source code.  They are located in the EGA
	directory.
		
	The complete specification for screen drivers can be found on the 
	system in the pcgeos spec directory (/staff/pcgeos/Spec).  

	$Id: egaManager.asm,v 1.1 97/04/18 11:42:08 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

;--------------------------------------
;		Include files
;--------------------------------------

_VideoDriver		=	1
VIDEO_STACK_SIZE	equ	512		; set size of VidStack

include	vidcomGeode.def				; common video driver includes

;---------------------------------------------------------------------
;		Constants and Macros
;---------------------------------------------------------------------

include egaConstant.def
include vgacomConstant.def
include vidcomConstant.def

include vgacomMacro.def
include vidcomMacro.def

;------------------------------------------------------------------------------
;			Variables
;------------------------------------------------------------------------------
idata	segment

include	egaDevInfo.asm			; device info block
include	vidcomTables.asm			; common tables
include	egaTables.asm			; important tabular information

idata	ends


udata	segment

include vidcomVariable.def
include	vgacomVariable.def			; local buffer space

udata	ends

;------------------------------------------------------------------------------
;			Variables
;------------------------------------------------------------------------------
VideoDevices	segment	lmem LMEM_TYPE_GENERAL
include egaStringTab.asm		; device names
VideoDevices	ends

;------------------------------------------------------------------------------
;			Code
;------------------------------------------------------------------------------
idata segment

include	vidcomEntry.asm			; entry point,jump tab
include	vidcomOutput.asm		; common output routines
include	vidcomChars.asm			; common character output routines
include	vgacomGenChar.asm		; routines for larger characters
include	vidcomFont.asm			; routines for rotating, building chars
include vidcomUnder.asm			; save under routines
include	vidcomUtils.asm			; utility routines
include	vidcomRegion.asm		; region drawing routines
include vidcomXOR.asm			; xor region support
include vidcomInfo.asm			; device setting/naming
include	vidcomEscape.asm		; implements some escape functions
include vidcomDither.asm		; dither support
include vidcomPalette.asm		; support for VidGetPixel
include	vgacomOutput.asm		; output routines
include vgacomUtils.asm			; misc utility routines
include	vgacomChars.asm			; character drawing routines
include vgacomPointer.asm		; pointer support
include vgacomPalette.asm		; standard palette buffer
include	egaEscTab.asm			; escape code jump table
include egaPalette.asm			; color palette table

idata ends

include vidcomPolygon.asm		; polygon drawing
include	vidcomLine.asm			; line drawing routine
include	vidcomPutLine.asm		; rotated bitmap support routine
include vidcomRaster.asm		; raster primitive support
include vidcomExclBounds.asm	; bounds accumulation
include vgacomRaster.asm		; raster primitive support
include vgacomTables.asm		; some common tables
include	egaAdmin.asm			; misc admin routines

	end
