COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		ImageWriter 9-pin printer driver
FILE:		iwriter9DriverInfo.asm

AUTHOR:		Dave Durran

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	2/27/90		Initial revision

DESCRIPTION:
	Driver info for the iwriter 9-pin printer driver

	The file "printerDriver.def" should be included before this one
		

	$Id: iwriter9DriverInfo.asm,v 1.1 97/04/18 11:53:39 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Driver Info Resource

	This part of the file contains the information that pertains to
	all device supported by the driver.  It includes device names and
	a table of the resource handles for the specific device info.  A
	pointer to this info is provided by the DriverInfo function.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DriverInfo	segment	resource

;----------------------------------------------------------------------------
;	Device Enumerations
;----------------------------------------------------------------------------

; This etype defined in printDriver.def
;  PrintDevice	etype	word, 0, 2
PD_APP_IWRITER2 enum	PrintDevice, 0		; first printer supported

;----------------------------------------------------------------------------
;	Driver Info Header
;----------------------------------------------------------------------------

iwriter9DriverInfo	DriverInfoHeader < PrintDevice/2,	; # devices
					   20,			; timeout (sec)
					   PR_DONT_RESEND,
					   offset deviceStrings, ; devices
					   offset deviceInfoTab	; info blocks
					 >


;----------------------------------------------------------------------------
;	Device String Table and Strings
;----------------------------------------------------------------------------

deviceStrings	label	word
		nptr	offset IWriter2String	
		word	0				; table terminator

	; strings
IWriter2String	char	"Apple ImageWriter II (B/W)",0
;----------------------------------------------------------------------------
;	Device Info Table and Info Structures
;----------------------------------------------------------------------------

deviceInfoTab	label	word
		hptr	handle generInfo	;Apple ImageWriter II
		word	0				; table terminator


DriverInfo	ends

