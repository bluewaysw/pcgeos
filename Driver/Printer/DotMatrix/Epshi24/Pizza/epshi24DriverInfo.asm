COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Epson late model 24-pin printer driver
FILE:		epshi24DriverInfo.asm

AUTHOR:		Dave Durran, 26 Mar 1990

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/27/90		Initial revision

DESCRIPTION:
	Driver info for the epson 24-pin printer driver

	The file "printerDriver.def" should be included before this one
		

	$Id: epshi24DriverInfo.asm,v 1.1 97/04/18 11:54:09 newdeal Exp $

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

DefPrinter PD_TOSHIBA_DYNA, "Toshiba DynaPrinter(Epson Mode)", dynaInfo

DefPrinter PD_TOSHIBA_DM_2V, "Toshiba DualMode 2V (Epson Mode)", dual2Info
DefPrinter PD_TOSHIBA_DM_3V, "Toshiba DualMode 3V (Epson Mode)", dual34MInfo
DefPrinter PD_TOSHIBA_DM_3VE, "Toshiba DualMode 3VE (Epson Mode)", dual34MInfo
DefPrinter PD_TOSHIBA_DM_4V, "Toshiba DualMode 4V (Epson Mode)", dual34Info
DefPrinter PD_TOSHIBA_DM_4VE, "Toshiba DualMode 4VE (Color, Epson Mode)", dual34Info
DefPrinter PD_TOSHIBA_DM_4VEM, "Toshiba DualMode 4VE (B/W, Epson Mode)", dual34MInfo
DefPrinter PD_TOSHIBA_DM_5V, "Toshiba DualMode 5V (Epson Mode)", dual5Info

DefPrinter PD_TOSHIBA_FB_2H, "Toshiba Flat Bed 2H (Epson Mode)", fb2HInfo
DefPrinter PD_TOSHIBA_FB_5H, "Toshiba Flat Bed 5H (Epson Mode)", fb5HInfo

DefPrinter PD_TOSHIBA_A3_PG, "Toshiba A3 Page Printer (Epson Mode)", lbpA3Info
DefPrinter PD_TOSHIBA_A4_PG, "Toshiba A4 Page Printer (Epson Mode)", lbpA4Info

DefPrinter PD_TOSHIBA_LBP, "Toshiba LBP 1 (Epson Mode)", lbpInfo
DefPrinter PD_TOSHIBA_LBP_2, "Toshiba LBP 2 (Epson Mode)", lbp2Info
DefPrinter PD_TOSHIBA_LBP_H, "Toshiba LBP H (Epson Mode)", lbpHInfo

;DefPrinter PD_HP_DESKJET_300J, "HP DeskJet 300J (Epson Mode)", dj300JInfo
;DefPrinter PD_HP_DESKJET_505JM, "HP DeskJet 505J (B/W, Epson Mode)", dj505JMInfo
;DefPrinter PD_HP_DESKJET_505JM, "HP DeskJet 505J (B/W)", dj505JMInfo
;DefPrinter PD_HP_DESKJET_505J, "HP DeskJet 505J (Color)", dj505JInfo


;----------------------------------------------------------------------------
;	Driver Info Header
;----------------------------------------------------------------------------

DriverExtendedInfoTable			 < {},		; lmem hdr
					   PrintDevice/2,	; # devices
					   offset deviceStrings, ; devices
					   offset deviceInfoTab	; info blocks
					   >

PrintDriverInfo				 < 10,			; timeout (sec)
					   PR_DONT_RESEND,	;
					   isoSubstitutions,	;ISO sub tab.
					   asciiTransTable,
					   PDT_PRINTER,
					   TRUE
					>


;----------------------------------------------------------------------------
;	Device String Table and Strings
;----------------------------------------------------------------------------

	;ISO Substitutions for this printer.
	;France,Germany,UK,Denmark1,Sweden,Italy,Spain1,Japan,Norway,Denmark2,
	;Spain2,Latin America,Legal.
isoSubstitutions 	chunk.word \
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
		7b92h,7c96h,7d97h,7e9ch,0000h,0000h,0000h,0000h,\
		2323h,2424h,40a4h,5ba1h,5cd5h,5dd3h,5ea6h,6060h,\
		7ba9h,7ca8h,7da0h,7eaah,0000h,0000h,0000h,0000h

        ; ASCII Translation List for Foreign Language Versions
asciiTransTable         chunk.char ";;",0



;Create the actual tables now....
PrinterTables


DriverInfo	ends
