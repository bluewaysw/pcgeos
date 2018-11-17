COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Quietjet printer driver
FILE:		quietjetDriverInfo.asm

AUTHOR:		Dave Durran, 27 Feb 1990

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	2/27/90		Initial revision

DESCRIPTION:
	Driver info for the quietJet printer driver

	The file "printerDriver.def" should be included before this one
		

	$Id: quietjetDriverInfo.asm,v 1.1 97/04/18 11:52:13 newdeal Exp $

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

DefPrinter PD_QUIETJET, "HP QuietJet (HP Mode)", qjetInfo
DefPrinter PD_QUIETJET_PLUS, "HP QuietJet Plus (HP Mode)", qjetpInfo

;----------------------------------------------------------------------------
;	Driver Info Header
;----------------------------------------------------------------------------

DriverExtendedInfoTable			 <
					{},			; lmem hdr
					PrintDevice/2,		; # devices
					offset deviceStrings, 	; devices
					offset deviceInfoTab 	; info blocks
					>

PrintDriverInfo				 < 30,		;device timout
					  PR_RESEND,	;
                                          isoSubstitutions,    ;ISO sub tab.
                                          asciiTransTable,
                                          PDT_PRINTER,
                                          TRUE
					>


;----------------------------------------------------------------------------
;	Device String Table and Strings
;----------------------------------------------------------------------------

isoSubstitutions        chunk.word  0ffffh      ;no ISO Subs.

        ; ASCII Translation List for Foreign Language Versions
asciiTransTable         chunk.char ";;",0


;create the actual tables.....
PrinterTables


DriverInfo	ends
