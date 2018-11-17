COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1988 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		Monochrome EGA screen driver
FILE:		megaManager.asm

AUTHOR:		Jeremy Dashe


REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Jim	4/88	initial version
	jeremy	5/91	monochrome version

DESCRIPTION:
	This file contains the source for the Monochrome EGA screen driver.
	There are a number of actual files included in this one that
	actually contain the actual source code.  They are located in the
	EGA and MEGA directories.  The complete specification for screen
	drivers can be found on the system in the pcgeos spec directory
	(/staff/pcgeos/Spec).  

	$Id: megaManager.asm,v 1.1 97/04/18 11:42:19 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

;--------------------------------------
;		Include files
;--------------------------------------

_VideoDriver		=	1
VIDEO_STACK_SIZE	equ	512	; size of local stack

include	vidcomGeode.def			; common include files

;---------------------------------------------------------------------
;		Data area
;---------------------------------------------------------------------

include megaConstant.def
include vgacomConstant.def
include vidcomConstant.def

include megaMacro.def
include vgacomMacro.def
include vidcomMacro.def

;------------------------------------------------------------------------------
;			Variables
;------------------------------------------------------------------------------
idata	segment

include	megaDevInfo.asm			; device info block
include	vidcomTables.asm		; common tables
include	megaTables.asm			; important tabular information

idata	ends


udata	segment

include vidcomVariable.def
include	vgacomVariable.def			; local buffer space

udata	ends

;------------------------------------------------------------------------------
;			Variables
;------------------------------------------------------------------------------
VideoDevices	segment	lmem LMEM_TYPE_GENERAL
include megaStringTab.asm		; device names
VideoDevices	ends

;------------------------------------------------------------------------------
;			Code
;------------------------------------------------------------------------------
idata segment

include	vidcomEntry.asm			; entry point,jump tab
include	vidcomOutput.asm		; common output routines
include	vidcomChars.asm			; common character output routines
include	megaGenChar.asm			; routines for larger characters
include	vidcomFont.asm			; routines for rotating, building chars
include vidcomUnder.asm			; save under routines
include	vidcomUtils.asm			; utility routines
include	vidcomRegion.asm		; region drawing routines
include vidcomXOR.asm			; xor region support
include vidcomInfo.asm			; device setting/naming
include	vidcomEscape.asm		; implements some escape functions
include vidcomPalette.asm		; support for VidGetPixel
include vgacomPointer.asm		; pointer support
include vgacomUtils.asm			; misc utility routines
include dumbcomUtils.asm            	; misc utility routines
include dumbcomPalette.asm            	; color tables
include	megaOutput.asm			; output routines
include	megaChars.asm			; character drawing routines
include	megaEscTab.asm			; escape code jump table

idata	ends

include vidcomPolygon.asm		; polygon drawing
include	vidcomLine.asm			; line drawing routine
include	vidcomPutLine.asm		; line drawing routine
include vidcomRaster.asm		; raster primitive support
include vidcomExclBounds.asm	; bounds accumulation
include vgacomRaster.asm		; raster primitive support
include	megaAdmin.asm			; misc admin routines

	end
