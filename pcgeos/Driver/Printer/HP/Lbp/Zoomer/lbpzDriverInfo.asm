COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		LBP printer driver
FILE:		lbpDriverInfo.asm

AUTHOR:		Dave Durran

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	2/27/90		Initial revision
	Dave	6/22/92		Initial 2.0 revision

DESCRIPTION:
	Driver info for the LBP printer driver

	The file "printerDriver.def" should be included before this one
		

	$Id: lbpzDriverInfo.asm,v 1.1 97/04/18 11:51:58 newdeal Exp $

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

DefPrinter PD_LBP4, "Canon LBP-4 (1.5Mbyte)", capsl3Info
DefPrinter PD_LBP8III, "Canon LBP-8 Mark III", capsl3Info

;----------------------------------------------------------------------------
;	Driver Info Header
;----------------------------------------------------------------------------

DriverExtendedInfoTable			 < 
					  {},			; lmem hdr
					  PrintDevice/2,	; # devices
					  offset deviceStrings, ; devices
					  offset deviceInfoTab	; info blocks
					  >

PrintDriverInfo				< 30,		;device timout
					  PR_RESEND,	;
                                           isoSubstitutions,    ;ISO sub tab.
                                           asciiTransTable,
                                           PDT_PRINTER,
                                           TRUE
					>


;----------------------------------------------------------------------------
;	Device String Table and Strings
;----------------------------------------------------------------------------

isoSubstitutions        chunk.word  0ffffh	;no ISO subs.


        ; ASCII Translation List for Foreign Language Versions
asciiTransTable         chunk.char ";;",0

	; strings

;create the actual tables....
PrinterTables


DriverInfo	ends
