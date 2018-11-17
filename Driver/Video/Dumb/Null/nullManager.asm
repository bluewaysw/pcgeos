COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1988 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		Null screen driver
FILE:		nullManager.asm

AUTHOR:		Jim DeFrisco


REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Jim	6/90	initial version

DESCRIPTION:
	This file contains the source for the Null screen driver.  There
	are a number of actual files included in this one that actually 
	contain the actual source code.  They are located in the Null
	directory.
		
	The complete specification for screen drivers can be found on the 
	system in the pcgeos spec directory (/staff/pcgeos/Spec).  

	$Id: nullManager.asm,v 1.1 97/04/18 11:43:44 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}


;------------------------------------------------------------------------------
;			Constants
;------------------------------------------------------------------------------

_VideoDriver		=	1

;--------------------------------------
;	Include files
;--------------------------------------

VIDEO_STACK_SIZE	equ	512		; size of local stack
include	vidcomGeode.def				; common include files

;---------------------------------------------------------------------
;		Constants and Macros
;---------------------------------------------------------------------
include nullConstant.def

;------------------------------------------------------------------------------
;			Variables
;------------------------------------------------------------------------------
idata	segment
include dumbcomDevInfo.asm

idata	ends


udata	segment

udata	ends

;------------------------------------------------------------------------------
;			Extended Device Info
;------------------------------------------------------------------------------
VideoDevices	segment	lmem LMEM_TYPE_GENERAL
include	nullStringTab.asm		; device names
VideoDevices	ends


;------------------------------------------------------------------------------
;			Fixed Code
;------------------------------------------------------------------------------
idata segment 

include	nullEntry.asm			; entry point,jump tab
idata	ends

;------------------------------------------------------------------------------
;			Movable Code
;------------------------------------------------------------------------------

	end
