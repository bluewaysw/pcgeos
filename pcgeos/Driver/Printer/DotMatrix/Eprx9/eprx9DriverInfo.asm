COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Epson RX 9-pin printer driver
FILE:		eprx9DriverInfo.asm

AUTHOR:		Dave Durran, 27 Feb 1990

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	2/27/90		Initial revision

DESCRIPTION:
	Driver info for the epson RX 9-pin printer driver

	The file "printerDriver.def" should be included before this one
		

	$Id: eprx9DriverInfo.asm,v 1.1 97/04/18 11:53:49 newdeal Exp $

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

DefPrinter PD_EPSON_RX80, "Epson RX-80", rx80Info
DefPrinter PD_EPSON_RX80_FT, "Epson RX-80 F/T", rx80Info
DefPrinter PD_EPSON_RX100, "Epson RX-100", rx100Info
DefPrinter PD_PANASONIC_KXP1080, "Panasonic KX-P1080", rx80Info	
DefPrinter PD_PANASONIC_KXP1080I_E, "Panasonic KX-P1080i (Standard Mode)", rx80Info
DefPrinter PD_PANASONIC_KXP1091_E, "Panasonic KX-P1091 (Standard Mode)", rx80Info
DefPrinter PD_PANASONIC_KXP1091I_E, "Panasonic KX-P1091i (Standard Mode)", rx80Info

;----------------------------------------------------------------------------
;	Driver Info Header
;----------------------------------------------------------------------------

DriverExtendedInfoTable			 < {},		; lmem hdr
					   PrintDevice/2,	; # devices
					   offset deviceStrings, ; devices
					   offset deviceInfoTab	; info blocks
					   >

PrintDriverInfo				< 30,			; timeout (sec)
					   PR_DONT_RESEND,	;
                                           isoSubstitutions,    ;ISO sub tab.
                                           asciiTransTable,
                                           PDT_PRINTER,
                                           TRUE
					>


;----------------------------------------------------------------------------
;	Device String Table and Strings
;----------------------------------------------------------------------------

        ;ISO Substitutions for this printer.
        ;France,Germany,UK,Denmark1,Sweden,Italy,Spain1,Japan
isoSubstitutions        chunk.word \
                2323h,2424h,4088h,5ba1h,5c8dh,5da4h,5e5eh,6060h,\
                7b8eh,7c9dh,7d8fh,7each,0000h,0000h,0000h,0000h,\
                2323h,2424h,40a4h,5b80h,5c85h,5d86h,5e5eh,6060h,\
                7b8ah,7c9ah,7d9fh,7ea7h,0000h,0000h,0000h,0000h,\
                23a3h,0000h,0000h,0000h,0000h,0000h,0000h,0000h,\
                0000h,0000h,0000h,0000h,0000h,0000h,0000h,0000h,\
                2323h,2424h,4040h,5baeh,5cafh,5d81h,5e5eh,6060h,\
                7bbeh,7cbfh,7d8ch,0000h,0000h,0000h,0000h,0000h,\
                2323h,24dbh,4083h,5b80h,5c85h,5d81h,5e86h,608eh,\
                7b8ah,7c9ah,7d8ch,7e9fh,0000h,0000h,0000h,0000h,\
                2323h,2424h,4040h,5ba1h,5c5ch,5d8eh,5e5eh,609dh,\
                7b88h,7c98h,7d8fh,7e93h,0000h,0000h,0000h,0000h,\
                2320h,2424h,4040h,5bc1h,5c84h,5dc2h,5e5eh,6060h,\
                7bach,7c96h,0000h,0000h,0000h,0000h,0000h,0000h,\
                2323h,2424h,4040h,5b5bh,5cb4h,0000h,0000h,0000h,\
                0000h,0000h,0000h,0000h,0000h,0000h,0000h,0000h

        ; ASCII Translation List for Foreign Language Versions
asciiTransTable         chunk.char ";;",0

;Create the actual tables now.....
PrinterTables

DriverInfo	ends
