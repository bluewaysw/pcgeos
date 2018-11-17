COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		IBM PPDS 24-pin printer driver
FILE:		ppds24DriverInfo.asm

AUTHOR:		Dave Durran, 26 Mar 1990

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/27/90		Initial revision
	Dave	5/92		Initial 2.0 version

DESCRIPTION:
	Driver info for the PPDS 24-pin printer driver

	The file "printerDriver.def" should be included before this one
		

	$Id: ppds24DriverInfo.asm,v 1.1 97/04/18 11:54:26 newdeal Exp $

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


DefPrinter PD_IBM_2390, "IBM Personal Printer Series II 2390", generInfo
DefPrinter PD_IBM_2391, "IBM Personal Printer Series II 2391", generwInfo


;----------------------------------------------------------------------------
;	Driver Info Header
;----------------------------------------------------------------------------

DriverExtendedInfoTable			 < {},		; lmem hdr
					   PrintDevice/2,	; # devices
					   offset deviceStrings, ; devices
					   offset deviceInfoTab	; info blocks
					   >

PrintDriverInfo			      < 30,			; timeout (sec)
					PR_DONT_RESEND,	;
                                    	isoSubstitutions,    ;ISO sub tab.
                                    	asciiTransTable,
                                    	PDT_PRINTER,
                                    	TRUE
				      >


;----------------------------------------------------------------------------
;	Device String Table and Strings
;----------------------------------------------------------------------------

isoSubstitutions        chunk.word 0ffffh       ;no ISO subs.


        ; ASCII Translation List for Foreign Language Versions
asciiTransTable         chunk.char ";;",0



;Create the actual tables now....
PrinterTables


DriverInfo	ends

