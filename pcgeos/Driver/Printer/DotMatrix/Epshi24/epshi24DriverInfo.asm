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
		

	$Id: epshi24DriverInfo.asm,v 1.1 97/04/18 11:54:16 newdeal Exp $

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

ifdef	GPC_ONLY
;
; GlobalPC printer drivers (compatibility modes only)
;
DefPrinter PD_EPSON_24PIN_NARROW_BW, "Epson 24-Pin B/W Compatible", lq850Info
DefPrinter PD_EPSON_24PIN_NARROW_COLOR, "Epson 24-Pin Color Compatible", lq860Info
DefPrinter PD_EPSON_24PIN_WIDE_BW, "Epson 24-Pin (wide) B/W Compatible", lq1050Info
DefPrinter PD_EPSON_24PIN_WIDE_COLOR, "Epson 24-Pin (wide) Color Compatible", lq2550Info
else
;
; Default printer driver list (all known supported devices)
;
DefPrinter PD_CITOH_C610_PLUS_E_MONO, "C.Itoh C-610+ (Epson Mode)(B/W)", lq850Info
DefPrinter PD_CITOH_C610_PLUS_E, "C.Itoh C-610+ (Epson Mode)(Color)", lq860Info
DefPrinter PD_CITIZEN_GSX130_E, "Citizen GSX-130 (Epson Mode)", lq850Info
DefPrinter PD_CITIZEN_GSX140_E_MONO, "Citizen GSX-140 (Epson Mode)(B/W)", lq850Info
DefPrinter PD_CITIZEN_GSX140_E, "Citizen GSX-140 (Epson Mode)(Color)", lq860Info
DefPrinter PD_CITIZEN_GSX145_E_MONO, "Citizen GSX-145 (Epson Mode)(B/W)", lq1050Info
DefPrinter PD_CITIZEN_GSX145_E, "Citizen GSX-145 (Epson Mode)(Color)", lq2550Info
DefPrinter PD_CITIZEN_PN48_E, "Citizen PN-48 (Epson Mode)", lq850Info
DefPrinter PD_EPSON_AP3250, "Epson Action Printer 3250", lq510Info
DefPrinter PD_EPSON_AP4000, "Epson Action Printer 4000", lq510Info
DefPrinter PD_EPSON_AP4500, "Epson Action Printer 4500", lq1010Info
DefPrinter PD_EPSON_AP5000, "Epson Action Printer 5000", lq510Info
DefPrinter PD_EPSON_AP5000_PLUS, "Epson Action Printer 5000+", lq510Info
DefPrinter PD_EPSON_AP5500, "Epson Action Printer 5500", lq1010Info
DefPrinter PD_EPSON_DLQ2000, "Epson DLQ-2000", lq1010Info
DefPrinter PD_EPSON_LQ1010, "Epson LQ-1010", lq1010Info
DefPrinter PD_EPSON_LQ1050, "Epson LQ-1050", lq1050Info
DefPrinter PD_EPSON_LQ1050_PLUS, "Epson LQ-1050+", lq1050Info
DefPrinter PD_EPSON_LQ1060, "Epson LQ-1060", lq1050Info
DefPrinter PD_EPSON_LQ1060_PLUS, "Epson LQ-1060+", lq1050Info
DefPrinter PD_EPSON_LQ1070, "Epson LQ-1070", lq1010Info
DefPrinter PD_EPSON_LQ1170, "Epson LQ-1170", lq1010Info
DefPrinter PD_EPSON_LQ2550_MONO, "Epson LQ-2550 (B/W)", lq1050Info
DefPrinter PD_EPSON_LQ2550, "Epson LQ-2550 (Color)", lq2550Info
DefPrinter PD_EPSON_LQ510, "Epson LQ-510", lq510Info
DefPrinter PD_EPSON_LQ550, "Epson LQ-550", lq510Info
DefPrinter PD_EPSON_LQ570, "Epson LQ-570", lq510Info
DefPrinter PD_EPSON_LQ570_PLUS, "Epson LQ-570+", lq510Info
DefPrinter PD_EPSON_LQ850, "Epson LQ-850", lq850Info
DefPrinter PD_EPSON_LQ850_PLUS, "Epson LQ-850+", lq850Info
DefPrinter PD_EPSON_LQ860_MONO, "Epson LQ-860 (B/W)", lq850Info
DefPrinter PD_EPSON_LQ860, "Epson LQ-860 (Color)", lq860Info
DefPrinter PD_EPSON_LQ860_PLUS_MONO, "Epson LQ-860+ (B/W)", lq850Info
DefPrinter PD_EPSON_LQ860_PLUS, "Epson LQ-860+ (Color)", lq860Info
DefPrinter PD_EPSON_LQ870, "Epson LQ-870", lq510Info
DefPrinter PD_EPSON_LQ950, "Epson LQ-950", lq950Info
DefPrinter PD_EPSON_SQ2500, "Epson SQ-2500", lq850Info
DefPrinter PD_EPSON_SQ2550, "Epson SQ-2550", lq1050Info
DefPrinter PD_EPSON_SQ850, "Epson SQ-850", lq850Info
DefPrinter PD_IBM_4070_E, "IBM 4070 IJ (Epson Mode)", lq850Info
DefPrinter PD_IBM_5183_E, "IBM Portable 5183 (Epson Mode)", lq850Info
DefPrinter PD_LASER_2410, "Laser 2410", lq850Info
DefPrinter PD_OLIVETTI_DM124_E, "Olivetti DM 124 (Epson Mode)", lq850Info
DefPrinter PD_OLIVETTI_DM124C_E_MONO, "Olivetti DM 124C (Epson Mode)(B/W)", lq850Info
DefPrinter PD_OLIVETTI_DM124C_E, "Olivetti DM 124C (Epson Mode)(Color)", lq860Info
DefPrinter PD_OLIVETTI_DM124L_E, "Olivetti DM 124L (Epson Mode)", lq1050Info
DefPrinter PD_OLIVETTI_DM324_E, "Olivetti DM 324 (Epson Mode)", lq850Info
DefPrinter PD_OLIVETTI_DM324L_E, "Olivetti DM 324L (Epson Mode)", lq1050Info
DefPrinter PD_OLIVETTI_DM624_E, "Olivetti DM 624 (Epson Mode)", lq1050Info
DefPrinter PD_PANASONIC_KXP1123_E, "Panasonic KX-P1123 (Epson Mode)", lq850Info
DefPrinter PD_PANASONIC_KXP1124_E, "Panasonic KX-P1124 (Standard Mode)", lq850Info
DefPrinter PD_PANASONIC_KXP1124I_E, "Panasonic KX-P1124i (Epson Mode)", lq850Info
DefPrinter PD_PANASONIC_KXP1654_E, "Panasonic KX-P1654 (Epson Mode)", lq1050Info
DefPrinter PD_PANASONIC_KXP2023_E, "Panasonic KX-P2023 (Epson Mode)", lq850Info
DefPrinter PD_PANASONIC_KXP2123_E_MONO, "Panasonic KX-P2123 (Epson Mode)(B/W)", lq850Info
DefPrinter PD_PANASONIC_KXP2123_E, "Panasonic KX-P2123 (Epson Mode)(Color)", lq860Info
DefPrinter PD_PANASONIC_KXP2124_E_MONO, "Panasonic KX-P2124 (Epson Mode)(B/W)", lq850Info
DefPrinter PD_PANASONIC_KXP2124_E, "Panasonic KX-P2124 (Epson Mode)(Color)", lq860Info
DefPrinter PD_PANASONIC_KXP2624_E, "Panasonic KX-P2624 (Epson Mode)", lq1050Info
DefPrinter PD_PHILIPS_NMS1453, "Philips NMS 1453", lq850Info
DefPrinter PD_STAR_NX2420_E, "Star NX-2420 (Standard Mode)", lq850Info
DefPrinter PD_STAR_NX2460_E_MONO, "Star NX-2460C (Standard Mode)(B/W)", lq850Info
DefPrinter PD_STAR_NX2460_E, "Star NX-2460C (Standard Mode)(Color)", lq860Info
DefPrinter PD_SEIKOSHA_SL90, "Seikosha SL-90", lq850Info
DefPrinter PD_STAR_XB2410_E, "Star XB-2410 (Standard Mode)", lq850Info
DefPrinter PD_STAR_XB2415_E, "Star XB-2415 (Standard Mode)", lq1050Info
DefPrinter PD_STAR_XB2420_E_MONO, "Star XB-2420 (Standard Mode)(B/W)", lq850Info
DefPrinter PD_STAR_XB2420_E, "Star XB-2420 (Standard Mode)(Color)", lq860Info
DefPrinter PD_TANDY_DMP204_MONO, "Tandy DMP 204 (B/W)", lq850Info
DefPrinter PD_TANDY_DMP204, "Tandy DMP 204 (Color)", lq860Info
DefPrinter PD_TANDY_DMP205_MONO, "Tandy DMP 205 (B/W)", lq850Info
DefPrinter PD_TANDY_DMP205, "Tandy DMP 205 (Color)", lq860Info
DefPrinter PD_TANDY_DMP206, "Tandy DMP 206", lq850Info
DefPrinter PD_TANDY_DMP240_E_MONO, "Tandy DMP 240 (Epson Mode)(B/W)", lq850Info
DefPrinter PD_TANDY_DMP240_E, "Tandy DMP 240 (Epson Mode)(Color)", lq860Info
DefPrinter PD_TANDY_DMP250_MONO, "Tandy DMP 250 (B/W)", lq850Info
DefPrinter PD_TANDY_DMP250, "Tandy DMP 250 (Color)", lq860Info
DefPrinter PD_TANDY_DMP302_E, "Tandy DMP 302 (Epson Mode)", lq850Info
DefPrinter PD_TANDY_DMP2103_E, "Tandy DMP 2103 (Epson Mode)", lq1050Info
DefPrinter PD_TANDY_DMP2104_E, "Tandy DMP 2104 (Epson Mode)", lq1050Info
DefPrinter PD_TANDY_JP250_E, "Tandy JP 250 (Epson Mode)", lq510Info
endif

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
