COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Epson LX 9-pin printer driver
FILE:		eplx9DriverInfo.asm

AUTHOR:		Dave Durran

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	2/27/90		Initial revision
	Dave	5/91		Modified to use the table macros.

DESCRIPTION:
	Driver info for the eplx 9-pin printer driver

	The file "printerDriver.def" should be included before this one
		

	$Id: eplx9DriverInfo.asm,v 1.1 97/04/18 11:54:38 newdeal Exp $

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

DefPrinter PD_EPSON_APEX_80, "Epson Apex 80", fx80Info
DefPrinter PD_EPSON_AP_2000, "Epson Action Printer 2000", lx80Info
DefPrinter PD_EPSON_AP_T1000, "Epson Action Printer T-1000", fx80Info
DefPrinter PD_EPSON_FX100, "Epson FX-100", fx100Info
DefPrinter PD_EPSON_FX100_PLUS, "Epson FX-100+", fx100Info
DefPrinter PD_EPSON_FX80, "Epson FX-80", fx80Info
DefPrinter PD_EPSON_FX80_PLUS, "Epson FX-80+", fx80Info
DefPrinter PD_EPSON_JX80_MONO, "Epson JX-80 (B/W)", fx80Info
DefPrinter PD_EPSON_JX80, "Epson JX-80 (Color)", jx80Info
DefPrinter PD_EPSON_LX1050, "Epson LX-1050", fx100Info
DefPrinter PD_EPSON_LX80, "Epson LX-80", lx80Info
DefPrinter PD_EPSON_LX400, "Epson LX-400", lx80Info
DefPrinter PD_EPSON_LX800, "Epson LX-800", lx80Info
DefPrinter PD_EPSON_LX810, "Epson LX-810", lx80Info
DefPrinter PD_EPSON_LX850, "Epson LX-850", lx80Info
DefPrinter PD_EPSON_LX86, "Epson LX-86", lx80Info
DefPrinter PD_FUJITSU_DX2300_E, "Fujitsu DX2300 (Type F)", fx80Info
DefPrinter PD_FUJITSU_DX2400_E, "Fujitsu DX2400 (Type F)", fx100Info
DefPrinter PD_PANASONIC_KXP1092_E, "Panasonic KX-P1092 (Standard Mode)", fx80Info
DefPrinter PD_PANASONIC_KXP1092I_E, "Panasonic KX-P1092i (Standard Mode)", fx80Info
DefPrinter PD_PANASONIC_KXP1093_E, "Panasonic KX-P1093 (Standard Mode)", fx100Info
DefPrinter PD_PANASONIC_KXP1592_E, "Panasonic KX-P1592 (Standard Mode)", fx100Info

;----------------------------------------------------------------------------
;	Driver Info Header
;----------------------------------------------------------------------------

DriverExtendedInfoTable			 < {},		; lmem hdr
					   PrintDevice/2,	; # devices
					   offset deviceStrings, ; devices
					   offset deviceInfoTab	; info blocks
					   >

PrintDriverInfo				 < 30,			; timeout (sec)
					   PR_DONT_RESEND,
                                           isoSubstitutions,    ;ISO sub tab.
                                           asciiTransTable,
                                           PDT_PRINTER,
                                           TRUE
					>


;----------------------------------------------------------------------------
;	Device String Table and Strings
;----------------------------------------------------------------------------

        ;ISO Substitutions for this printer.
        ;France,Germany,UK,Denmark1,Sweden,Italy,Spain1,Japan,Norway,Denmark2,
        ;Spain2,Latin America
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
                0000h,0000h,0000h,0000h,0000h,0000h,0000h,0000h,\
                2323h,24dbh,4083h,5baeh,5cafh,5d81h,5e86h,608eh,\
                7bbeh,7cbfh,7d8ch,7e9fh,0000h,0000h,0000h,0000h,\
                2323h,2424h,4083h,5baeh,5cafh,5d81h,5e86h,608eh,\
                7bbeh,7cbfh,7d8ch,7e9fh,0000h,0000h,0000h,0000h,\
                2323h,2424h,4087h,5bc1h,5c84h,5dc2h,5e8eh,6060h,\
                7b92h,7c96h,7d97h,7e9ch,0000h,0000h,0000h,0000h,\
                2323h,2424h,4087h,5bc1h,5c84h,5dc2h,5e8eh,609fh,\
                7b92h,7c96h,7d97h,7e9ch,0000h,0000h,0000h,0000h

        ; ASCII Translation List for Foreign Language Versions
asciiTransTable         chunk.char ";;",0


;Create the actual tables now......
PrinterTables


DriverInfo	ends

