COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GlobalPC 1999.  All rights reserved.
	GLOBALPC CONFIDENTIAL

PROJECT:	GlobalPC
MODULE:		Canon BJC Printer Driver
FILE:		canonBJCDriverInfo.asm

AUTHOR:		Joon Song, Jan 24, 1999

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon   	1/24/99   	Initial revision from canon48DriverInfo.asm


DESCRIPTION:
	Driver info for the Canon BJC printer driver
	

	$Id$

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

; Canon models supported by this driver
;
DefPrinter PD_CANON_BJC1000_MONO, "Canon BJC-1000 (B/W)", monoInfo
DefPrinter PD_CANON_BJC1000_COLOR, "Canon BJC-1000 (Color)", rgbInfo
DefPrinter PD_CANON_BJC2000, "Canon BJC-2000", rgbInfo
DefPrinter PD_CANON_BJC2100, "Canon BJC-2100", rgbInfo

; GlobalPC-specific models supported by this driver
;
DefPrinter PD_GLOBALPC_BJC2120, "Canon BJC-2120", rgbInfo
DefPrinter PD_GLOBALPC_BJC2120_MONO, "Canon BJC-2120 (B/W)", mono2Info
DefPrinter PD_GLOBALPC_BJC2112, "Canon BJC-2112", rgbInfo
DefPrinter PD_GLOBALPC_BJC2112_MONO, "Canon BJC-2112 (B/W)", mono2Info

; if you add more color printers to this list you will also need to change
; CMYKColorLibInitialize to select the correct ink type.

;----------------------------------------------------------------------------
;	Driver Info Header
;----------------------------------------------------------------------------

DriverExtendedInfoTable			 < {},			; lmem hdr
					   PrintDevice/2,	; # devices
					   offset deviceStrings,; devices
					   offset deviceInfoTab	; info blocks
					   >

PrintDriverInfo				 < 30,			; timeout (sec)
					   PR_DONT_RESEND,	;
                                           isoSubstitutions,    ; ISO sub tab.
                                           asciiTransTable,
                                           PDT_PRINTER,
					   TRUE
					>


;----------------------------------------------------------------------------
;	Device String Table and Strings
;----------------------------------------------------------------------------
isoSubstitutions        chunk.word 0ffffh	;no ISO subs.

        ; ASCII Translation List for Foreign Language Versions
asciiTransTable         chunk.char ";;",0

	; create the actual tables....
PrinterTables

DriverInfo	ends
