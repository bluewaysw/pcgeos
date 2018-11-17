COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Epson 24-pin printer driver
FILE:		epson24DriverInfo.asm

AUTHOR:		Dave Durran, 26 Mar 1990

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/27/90		Initial revision

DESCRIPTION:
	Driver info for the epson 24-pin printer driver

	The file "printerDriver.def" should be included before this one
		

	$Id: epson24DriverInfo.asm,v 1.1 97/04/18 11:53:28 newdeal Exp $

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


DefPrinter PD_AEG_NP13624_E, "AEG Olympia NP 136-24 (Epson Mode)", generwInfo
DefPrinter PD_AEG_NP8024_E, "AEG Olympia NP 80-24 (Epson Mode)", generInfo
DefPrinter PD_ALPS_ALQ200_24, "ALPS ALQ200 24-pin", generInfo
DefPrinter PD_ALPS_ALQ300_24, "ALPS ALQ300 24-pin", generwInfo
DefPrinter PD_ALPS_ALLEGRO_24, "ALPS Allegro 24", generwInfo
DefPrinter PD_ALPS_P2400C, "ALPS P2400C", generwInfo
DefPrinter PD_ALPS_P2424C, "ALPS P2424C", generwInfo
DefPrinter PD_AMT_ACCEL_500_E, "AMT Accel-500 (Epson Mode)", generwInfo
DefPrinter PD_ATT_580_E, "AT&T 580 (Epson Mode)", generInfo
DefPrinter PD_ATT_581_E, "AT&T 581 (Epson Mode)", generwInfo
DefPrinter PD_ATT_583_E, "AT&T 583 (Epson Mode)", generwInfo
DefPrinter PD_AMSTRAD_LQ3500_E, "Amstrad LQ 3500 (Epson Mode)", generInfo
DefPrinter PD_BROTHER_2024L, "Brother 2024L", generInfo
DefPrinter PD_BROTHER_M1724L_E, "Brother M-1724L (Epson Mode)", generwInfo
DefPrinter PD_BROTHER_M1824L_E, "Brother M-1824L (Epson Mode)", generInfo
DefPrinter PD_CITOH_C610_E, "C.Itoh C-610 (Epson Mode)", generwInfo
DefPrinter PD_CITOH_C715A, "C.Itoh C-715A", generwInfo
DefPrinter PD_CITIZEN_TRIB124_E, "Citizen Tribute 124 (LQ interface, Epson Mode)", generInfo
DefPrinter PD_COPAL_6730_E, "Copal Writehand 6730 (Epson Mode)", generwInfo
DefPrinter PD_DATAPRODUCTS_9044_E, "Dataproducts 9044 (Epson Mode)", generInfo
DefPrinter PD_EPSON_AP_L1000, "Epson Action Printer L-1000", lq500Info
DefPrinter PD_EPSON_AP_L3000, "Epson Action Printer L-3000", lq500Info
DefPrinter PD_EPSON_AP_L750, "Epson Action Printer L-750", lq1000Info
DefPrinter PD_EPSON_LQ1000, "Epson LQ-1000", lq1000Info
DefPrinter PD_EPSON_LQ1050_EV, "Epson LQ-1050 (Early Version)", lq1000Info
DefPrinter PD_EPSON_LQ1500, "Epson LQ-1500", lq1500Info
DefPrinter PD_EPSON_LQ200, "Epson LQ-200", lq800Info
DefPrinter PD_EPSON_LQ300_MONO, "Epson LQ-300 (B/W)", lq800Info
DefPrinter PD_EPSON_LQ300, "Epson LQ-300 (Color)", lq2500Info
DefPrinter PD_EPSON_LQ2500_MONO, "Epson LQ-2500 (B/W)", generwInfo
DefPrinter PD_EPSON_LQ2500, "Epson LQ-2500 (Color)", lq2500Info
DefPrinter PD_EPSON_LQ2500_PLUS_MONO, "Epson LQ-2500+ (B/W)", generwInfo
DefPrinter PD_EPSON_LQ2500_PLUS, "Epson LQ-2500+ (Color)", lq2500Info
DefPrinter PD_EPSON_LQ400, "Epson LQ-400", lq500Info
DefPrinter PD_EPSON_LQ450, "Epson LQ-450", lq500Info
DefPrinter PD_EPSON_LQ500, "Epson LQ-500", lq500Info
DefPrinter PD_EPSON_LQ800, "Epson LQ-800", lq800Info
DefPrinter PD_EPSON_LQ850_EV, "Epson LQ-850 (Early Version)", lq800Info
DefPrinter PD_EPSON_LQ950_EV, "Epson LQ-950 (Early Version)", lq900Info
DefPrinter PD_EPSON_P_80X, "Epson P-80X", lq800Info
DefPrinter PD_EPSON_SQ_2000, "Epson SQ-2000", lq1000Info
DefPrinter PD_FACIT_B2400_E, "Facit B2400 (Epson Mode)", generInfo
DefPrinter PD_FORTIS_DQ4110_E, "Fortis DQ 4110 (Epson Mode)", generInfo
DefPrinter PD_FORTIS_DQ4210_E, "Fortis DQ 4210 (Epson Mode)", generInfo
DefPrinter PD_FORTIS_DQ4215_E, "Fortis DQ 4215 (Epson Mode)", generwInfo
DefPrinter PD_FUJITSU_DL4400_E, "Fujitsu DL4400 (Epson Mode)", generInfo
DefPrinter PD_GENICOM_1040_E, "Genicom 1040 (Epson Mode)", generInfo
DefPrinter PD_HP_RUGGWR_480_E, "HP RuggedWriter 480 (LQ-1000 Mode)", lq1000Info
DefPrinter PD_MANN_TALLY_222_E, "Mannesmann Tally 222 (Epson Mode)", generwInfo
DefPrinter PD_MANN_TALLY_23024_E, "Mannesmann Tally 230/24 (Epson Mode)", generwInfo
DefPrinter PD_MANN_TALLY_330, "Mannesmann Tally 330", generwInfo
DefPrinter PD_NISSHO_NP2405_E, "Nissho NP-2405 (Epson Mode)", generwInfo
DefPrinter PD_OKI_ML390_E, "Okidata ML 390 (Epson Mode)", generInfo
DefPrinter PD_OKI_ML391_E, "Okidata ML 391 (Epson Mode)", generwInfo
DefPrinter PD_OKI_ML393, "Okidata ML 393", generwInfo
DefPrinter PD_OKI_ML393C, "Okidata ML 393C ", generwInfo
DefPrinter PD_PANASONIC_KXP1524_E, "Panasonic KX-P1524 (Standard Mode)", generwInfo
DefPrinter PD_PANASONIC_KXP1624_E, "Panasonic KX-P1624 (Standard Mode)", generwInfo
DefPrinter PD_PHILIPS_NMS1461_E, "Philips NMS 1461 (Epson Mode)", lq800Info
DefPrinter PD_PHILIPS_NMS1467_E, "Philips NMS 1467 (Epson Mode)", lq1000Info 
DefPrinter PD_SANYO_PR241_E, "Sanyo PR-241 (Epson Mode)", generwInfo
DefPrinter PD_SEARS_SR5000, "Sears SR-5000", generInfo
DefPrinter PD_SEIKOSHA_SBP10AI_E, "Seikosha SBP-10AI (Epson Mode)", generwInfo
DefPrinter PD_SEIKOSHA_SL130AI_E, "Seikosha SL-130AI (Epson Mode)", generwInfo
DefPrinter PD_SEIKOSHA_SL230AI_E, "Seikosha SL-230AI (Epson Mode)", generwInfo
DefPrinter PD_SEIKOSHA_SL80AI_E, "Seikosha SL-80AI (Epson Mode)", generInfo
DefPrinter PD_STAR_NB15, "Star NB-15", lq1500Info
DefPrinter PD_STAR_NB2410_E, "Star NB-24-10 (Standard Mode)", lq800Info
DefPrinter PD_STAR_NB2415_E, "Star NB-24-15 (Standard Mode)", lq1000Info
DefPrinter PD_STAR_NB2400_E, "Star NX-2400 (Standard Mode)", generInfo
DefPrinter PD_TI_OMNI875, "Texas Instr. Omni 875", generInfo
DefPrinter PD_TI_OMNI877, "Texas Instr. Omni 877", generInfo
DefPrinter PD_TOSHIBA_EXWR301_E, "Toshiba ExpressWriter 301 (Epson Mode)", generInfo
DefPrinter PD_TOSHIBA_EXWR311_E, "Toshiba ExpressWriter 311 (Epson Mode)", generInfo
DefPrinter PD_UNISYS_AP1324, "Unisys AP 1324", generwInfo





;----------------------------------------------------------------------------
;	Driver Info Header
;----------------------------------------------------------------------------

DriverExtendedInfoTable			 < 
					    {},			  ; lmem hdr
					    PrintDevice/2, ; # devices
					    offset deviceStrings, ; names
					    offset deviceInfoTab  ; info blocks
					    >

PrintDriverInfo				 <  10,			; timeout (sec)
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
        ;France,Germany,UK,Denmark1,Sweden,Italy,Spain1,Japan,Norway,Denmark2,
        ;Spain2,Latin America.
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
asciiTransTable		chunk.char ";;",0

;Create the actual Tables......
PrinterTables

DriverInfo	ends
