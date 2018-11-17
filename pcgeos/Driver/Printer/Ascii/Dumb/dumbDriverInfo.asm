COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Dumb ASCII (Unformatted) Print Driver
FILE:		dumbDriverInfo.asm

AUTHOR:		Dave Durran

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
        Dave    8/30/93         Initial Revision

DESCRIPTION:
	Driver info for the Dumb ASCII (Unformatted) printer driver

	The file "printerDriver.def" should be included before this one
		

	$Id: dumbDriverInfo.asm,v 1.1 97/04/18 11:56:41 newdeal Exp $

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

DefPrinter PD_DUMB_ASCII, "Text Only Printer (Unformatted)", dumbInfo

;----------------------------------------------------------------------------
;	Driver Info Header
;----------------------------------------------------------------------------

DriverExtendedInfoTable			 < {},		; lmem hdr
					   PrintDevice/2,	; # devices
					   offset deviceStrings, ; devices
					   offset deviceInfoTab	; info blocks
					   >

PrintDriverInfo				< 45,			; timeout (sec)
					   PR_RESEND,		; resend after
                                           isoSubstitutions,    ;ISO sub tab.
                                           asciiTransTable,
                                           PDT_PRINTER,
                                           TRUE
					>


;----------------------------------------------------------------------------
;	Device String Table and Strings
;----------------------------------------------------------------------------

isoSubstitutions        chunk.word  0ffffh	;no subs.


        ; ASCII Translation List for Foreign Language Versions
asciiTransTable         chunk.char ";;",0


;Create the actual tables here.....
PrinterTables

DriverInfo	ends
