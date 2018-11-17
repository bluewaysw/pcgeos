COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer/Fax/CCom
FILE:		ccomDriverInfo.asm

AUTHOR:		Don Reeves, April 26, 1991

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/26/91		Initial revision

DESCRIPTION:
	Driver info for the Complete Communicator fax driver

	The file "printerDriver.def" should be included before this one
		
	$Id: ccomDriverInfo.asm,v 1.1 97/04/18 11:52:37 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Driver Info Resource

	This part of the file contains the information that pertains to
	all device supported by the driver.  It includes device names and
	a table of the resource handles for the specific device info.  A
	pointer to this info is provided by the DriverInfo function.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DriverInfo	segment	lmem LMEM_TYPE_GENERAL


;----------------------------------------------------------------------------
;	Device Enumerations
;----------------------------------------------------------------------------

; This etype defined in printDriver.def
;  PrintDevice	etype	word, 0, 2
; PD_COMPLETE_COMM	enum PrintDevice,0

DefPrinter PD_COMPLETE_COMM, "Complete Communicator Fax Modem", ccomDeviceInfo

;----------------------------------------------------------------------------
;	Driver Info Header
;----------------------------------------------------------------------------

ccomDriverInfo		DriverExtendedInfoTable < {},		; lmem hdr
					   PrintDevice/2,	; # devices
					   offset deviceStrings, ; devices
					   offset deviceInfoTab	; info blocks
					   >

ccomInfo		PrintDriverInfo <  1,			; timeout (sec)
					   PR_DONT_RESEND,
					   isoSubstitutions,
					   asciiTransTable,
					   PDT_FACSIMILE,
					   TRUE
					>


;----------------------------------------------------------------------------
;	ASCII Translation List for Foreign Language Versions
;----------------------------------------------------------------------------

asciiTransTable         chunk.char ";;",0

isoSubstitutions        chunk.word  0ffffh	;no ISO subs.

;----------------------------------------------------------------------------
;	Device String Table and Strings
;----------------------------------------------------------------------------
;create the tables...
PrinterTables

;----------------------------------------------------------------------------
;	Device Info Table and Info Structures
;----------------------------------------------------------------------------

;deviceInfoTab	label	word
;	hptr handle ccomDeviceInfo	; Complete Communicator
;	word	0			; table terminator

DriverInfo	ends


