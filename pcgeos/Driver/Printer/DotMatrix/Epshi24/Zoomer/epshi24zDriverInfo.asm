COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Epson late model 24-pin printer driver for Zoomer
FILE:		epshi24zDriverInfo.asm

AUTHOR:		Dave Durran, 26 Mar 1990

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/27/90		Initial revision

DESCRIPTION:
	Driver info for the epson 24-pin printer driver

	The file "printerDriver.def" should be included before this one
		

	$Id: epshi24zDriverInfo.asm,v 1.1 97/04/18 11:54:07 newdeal Exp $

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


DefPrinter PD_EPSON_LQ1050, "Epson LQ-1050", lq1050Info
DefPrinter PD_EPSON_LQ2550_MONO, "Epson LQ-2550 (B/W)", lq1050Info
DefPrinter PD_EPSON_LQ2550, "Epson LQ-2550 (Color)", lq2550Info
DefPrinter PD_EPSON_LQ850, "Epson LQ-850", lq850Info
DefPrinter PD_EPSON_LQ860_MONO, "Epson LQ-860 (B/W)", lq850Info
DefPrinter PD_EPSON_LQ860, "Epson LQ-860 (Color)", lq860Info
DefPrinter PD_TANDY_DMP204_MONO, "Tandy DMP 204 (Epson B/W)", lq850Info
DefPrinter PD_TANDY_DMP204, "Tandy DMP 204 (Epson Color)", lq860Info
DefPrinter PD_TANDY_DMP205_MONO, "Tandy DMP 205 (Epson B/W)", lq850Info
DefPrinter PD_TANDY_DMP205, "Tandy DMP 205 (Epson Color)", lq860Info
DefPrinter PD_TANDY_DMP206, "Tandy DMP 206 (Epson)", lq850Info
DefPrinter PD_TANDY_DMP240_E_MONO, "Tandy DMP 240 (Epson B/W)", lq850Info
DefPrinter PD_TANDY_DMP240_E, "Tandy DMP 240 (Epson Color)", lq860Info
DefPrinter PD_TANDY_DMP250_MONO, "Tandy DMP 250 (Epson B/W)", lq850Info
DefPrinter PD_TANDY_DMP250, "Tandy DMP 250 (Epson Color)", lq860Info
DefPrinter PD_TANDY_DMP302_E, "Tandy DMP 302 (Epson)", lq850Info
DefPrinter PD_TANDY_DMP2103_E, "Tandy DMP 2103 (Epson)", lq1050Info
DefPrinter PD_TANDY_DMP2104_E, "Tandy DMP 2104 (Epson)", lq1050Info
DefPrinter PD_TANDY_JP250_E, "Tandy JP 250 (Epson)", lq850Info

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
