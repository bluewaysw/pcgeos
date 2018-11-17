COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Epson 9-pin printer driver
FILE:		epson9DriverInfo.asm

AUTHOR:		Jim DeFrisco, 27 Feb 1990

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	2/27/90		Initial revision
	Dave	5/91		Modified to use the table macros.

DESCRIPTION:
	Driver info for the epson 9-pin printer driver

	The file "printerDriver.def" should be included before this one
		

	$Id: epson9DriverInfo.asm,v 1.1 97/04/18 11:53:12 newdeal Exp $

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

DefPrinter PD_ALPS_ALQ200, "ALPS ALQ200 18-pin", generInfo
DefPrinter PD_ALPS_ALQ300, "ALPS ALQ300 18-pin", generwInfo
DefPrinter PD_ALPS_ASP1000_E, "ALPS ASP1000 (Epson Mode)", generInfo
DefPrinter PD_ALPS_P2000G, "ALPS P2000G", generInfo
DefPrinter PD_ATT_570_E, "AT&T 570 (Epson Mode)", generInfo
DefPrinter PD_ATT_571_E, "AT&T 571 (Epson Mode)", generwInfo
DefPrinter PD_AMSTRAD_DMP3000_E, "Amstrad DMP3000 (Epson Mode)", generInfo
DefPrinter PD_AXONIX_LITEWRITE_E, "Axonix LiteWrite (Epson Mode)", generInfo
DefPrinter PD_AXONIX_THINWRITE_E, "Axonix ThinWrite 100 (Epson Mode)", generInfo
DefPrinter PD_BLUECHIP_M200_E, "Blue Chip M200/NLQ (Epson Mode)", generInfo
DefPrinter PD_BROTHER_M1109, "Brother M-1109 (Epson Mode)", generInfo
DefPrinter PD_BROTHER_M1509, "Brother M-1509", generInfo
DefPrinter PD_BROTHER_M1709_E, "Brother M-1709 (Epson Mode)", generwInfo
DefPrinter PD_BROTHER_M1809_E, "Brother M-1809 (Epson Mode)", m1809Info
DefPrinter PD_BROTHER_M1909, "Brother M-1909", generInfo
DefPrinter PD_BROTHER_M2518_E, "Brother M-2518 (Epson Mode)", generwInfo
DefPrinter PD_BROTHER_M4018_E, "Brother M-4018 (Epson Mode)", generwInfo
DefPrinter PD_BROTHER_TW6_E, "Brother Twinriter 6 (Epson Mode)", generwInfo
DefPrinter PD_CITOH_5000_E, "C.Itoh 5000 (Epson Mode)", generwInfo
DefPrinter PD_CITOH_C310_E, "C.Itoh ProWriter C-310 CXP (Epson Mode)", generInfo
DefPrinter PD_CITOH_PWJR, "C.Itoh ProWriter Jr. Plus", generInfo
DefPrinter PD_CITIZEN_120D, "Citizen 120-D", generInfo
DefPrinter PD_CITIZEN_180D, "Citizen 180-D", generInfo
DefPrinter PD_CITIZEN_200GX_MONO, "Citizen 200GX (B/W)", generInfo
DefPrinter PD_CITIZEN_200GX, "Citizen 200GX (Color)", ex800Info
DefPrinter PD_CITIZEN_200GX15_MONO, "Citizen 200GX/15 (B/W)", generwInfo
DefPrinter PD_CITIZEN_200GX15, "Citizen 200GX/15 (Color)", ex1000Info
DefPrinter PD_CITIZEN_5200, "Citizen 5200", generInfo
DefPrinter PD_CITIZEN_5800, "Citizen 5800", generInfo
DefPrinter PD_CITIZEN_HSP500_E_MONO, "Citizen HSP-500 (Epson Mode)(B/W)", generInfo
DefPrinter PD_CITIZEN_HSP500_E, "Citizen HSP-500 (Epson Mode)(Color)", ex800Info
DefPrinter PD_CITIZEN_HSP550_E_MONO, "Citizen HSP-550 (Epson Mode)(B/W)", generwInfo
DefPrinter PD_CITIZEN_HSP550_E, "Citizen HSP-550 (Epson Mode)(Color)", ex1000Info
DefPrinter PD_CITIZEN_MSP10, "Citizen MSP-10", generInfo
DefPrinter PD_CITIZEN_MSP15, "Citizen MSP-15", generInfo
DefPrinter PD_CITIZEN_MSP20, "Citizen MSP-20", generInfo
DefPrinter PD_CITIZEN_MSP25, "Citizen MSP-25", generInfo
DefPrinter PD_CITIZEN_MSP40_E, "Citizen MSP-40 (Epson Mode)", generInfo
DefPrinter PD_CITIZEN_MSP55_E, "Citizen MSP-55 (Epson Mode)", generInfo
DefPrinter PD_CITIZEN_T124_E, "Citizen Tribute 124 (Epson Mode)", generInfo
DefPrinter PD_CITIZEN_T224_E, "Citizen Tribute 224 (Epson Mode)", generwInfo
DefPrinter PD_COPAL_5930_E, "Copal Writehand 5930 (Epson Mode)", generwInfo
DefPrinter PD_EPSON_AP_2250, "Epson Action Printer 2250", generInfo
DefPrinter PD_EPSON_AP_2500, "Epson Action Printer 2500", generwInfo
DefPrinter PD_EPSON_AP_T750, "Epson Action Printer T-750", fx286eInfo
DefPrinter PD_EPSON_DFX5000, "Epson DFX-5000", dfx5000Info
DefPrinter PD_EPSON_DFX8000_E, "Epson DFX-8000 (Epson Mode)", dfx5000Info
DefPrinter PD_EPSON_EX1000_E_MONO, "Epson EX-1000 (Epson Mode)(B/W)", generwInfo
DefPrinter PD_EPSON_EX1000_E, "Epson EX-1000 (Epson Mode)(Color)", ex1000Info
DefPrinter PD_EPSON_EX800_E_MONO, "Epson EX-800 (Epson Mode)(B/W)", generInfo
DefPrinter PD_EPSON_EX800_E, "Epson EX-800 (Epson Mode)(Color)", ex800Info
DefPrinter PD_EPSON_FX1000_E, "Epson FX-1000 (Epson Mode)", generwInfo
DefPrinter PD_EPSON_FX1050_E, "Epson FX-1050 (Epson Mode)", generwInfo
DefPrinter PD_EPSON_FX185_E, "Epson FX-185 (Epson Mode)", fx185Info
DefPrinter PD_EPSON_FX286_E, "Epson FX-286 (Epson Mode)", fx185Info
DefPrinter PD_EPSON_FX286E_E, "Epson FX-286e (Epson Mode)", fx286eInfo
DefPrinter PD_EPSON_FX85_E, "Epson FX-85 (Epson Mode)", fx85Info
DefPrinter PD_EPSON_FX800_E, "Epson FX-800 (Epson Mode)", generInfo
DefPrinter PD_EPSON_FX850_E, "Epson FX-850 (Epson Mode)", generInfo
DefPrinter PD_EPSON_FX86E_E, "Epson FX-86e (Epson Mode)", fx86eInfo
DefPrinter PD_EPSON_IX800_E, "Epson IX-800 (Epson Mode)", generInfo
DefPrinter PD_FACIT_B3100_E, "Facit B3100 (Epson Mode)", generInfo
DefPrinter PD_FACIT_B3150_E, "Facit B3150 (Epson Mode)", generInfo
DefPrinter PD_FACIT_B3350_E, "Facit B3350 (Epson Mode)", generwInfo
DefPrinter PD_FACIT_B3550_E, "Facit B3550 (Epson Mode)", generwInfo
DefPrinter PD_FORTIS_DM1310_E, "Fortis DM 1310 (Epson Mode)", generInfo
DefPrinter PD_FORTIS_DM2210_E, "Fortis DM 2210 (Epson Mode)", generInfo
DefPrinter PD_FORTIS_DM2215_E, "Fortis DM 2215 (Epson Mode)", generwInfo
DefPrinter PD_FUJITSU_DL2600_E, "Fujitsu DL2600 (Epson Mode)", generwInfo
DefPrinter PD_FUJITSU_DL3400_E, "Fujitsu DL3400 (Epson Mode)", generwInfo
DefPrinter PD_FUJITSU_DL5600_E, "Fujitsu DL5600 (Epson Mode)", generwInfo
DefPrinter PD_GENICOM_3820_E, "Genicom 3820 (Epson Mode)", generwInfo
DefPrinter PD_GENICOM_PS220_E, "Genicom Printstation 220 (Epson Mode)", generwInfo
DefPrinter PD_HONEYWELL_466_E, "Honeywell Bull 4/66 (Epson Mode)", generInfo
DefPrinter PD_HYUNDAI_HDP1810_E, "Hyundai HDP-1810 (Epson Card)", generInfo
DefPrinter PD_HYUNDAI_HDP1820_E, "Hyundai HDP-1820 (Epson Card)", generwInfo
DefPrinter PD_HYUNDAI_HDP910_E, "Hyundai HDP-910 (Epson Mode)", generInfo
DefPrinter PD_HYUNDAI_HDP920_E, "Hyundai HDP-920 (Epson Mode)", generwInfo
DefPrinter PD_LASER_145, "Laser 145", generInfo
DefPrinter PD_LASER_190E_E, "Laser 190E (Epson Mode)", generInfo
DefPrinter PD_LASER_240_E, "Laser 240 (Epson Mode)", generInfo
DefPrinter PD_MANN_TALLY_340_E, "Mannesmann Tally 340 (Epson Mode)", generwInfo
DefPrinter PD_MANN_TALLY_81_E, "Mannesmann Tally 81 (Epson Mode)", generInfo
DefPrinter PD_MANN_TALLY_87_E, "Mannesmann Tally 87 (Epson Mode)", generInfo
DefPrinter PD_MANN_TALLY_90_E, "Mannesmann Tally 90 (Epson Mode)", generInfo
DefPrinter PD_OTC_TM850XL_E, "OTC TriMatrix 850XL (Epson Mode)", generwInfo
DefPrinter PD_OKI_ML320_E, "Okidata ML 320 (Epson Mode)", generInfo
DefPrinter PD_OKI_ML321_E, "Okidata ML 321 (Epson Mode)", generwInfo
DefPrinter PD_OLIVETTI_DM_109_E, "Olivetti DM 109 (Epson Mode)", generInfo
DefPrinter PD_OLIVETTI_DM_309_E, "Olivetti DM 309 (Epson Mode)", generInfo
DefPrinter PD_OLIVETTI_DM_309L_E, "Olivetti DM 309L (Epson Mode)", generwInfo
DefPrinter PD_OLIVETTI_DM_99_E, "Olivetti DM 99 (Epson Mode)", generInfo
DefPrinter PD_OLYMPIA_NP136_E, "Olympia NP136 (Epson Mode)", generwInfo
DefPrinter PD_OLYMPIA_NP30_E, "Olympia NP30 (Epson Mode)", generInfo
DefPrinter PD_OLYMPIA_NP80_E, "Olympia NP80 (Epson Mode)", generInfo
DefPrinter PD_OUTPUT_TECH_560DL_E, "Output Technology 560DL (Epson Mode)", generwInfo
DefPrinter PD_OUTPUT_TECH_850SE_E, "Output Technology 850SE (Epson Mode)", generwInfo
DefPrinter PD_PANASONIC_KXP1180_E, "Panasonic KX-P1180 (Standard Mode)", fx86eInfo
DefPrinter PD_PANASONIC_KXP1180I_E, "Panasonic KX-P1180i (Standard Mode)", fx86eInfo
DefPrinter PD_PANASONIC_KXP1191_E, "Panasonic KX-P1191 (Standard Mode)", fx86eInfo
DefPrinter PD_PANASONIC_KXP1595_E, "Panasonic KX-P1595 (Standard Mode)", fx185Info
DefPrinter PD_PANASONIC_KXP1695_E, "Panasonic KX-P1695 (Standard Mode)", generwInfo
DefPrinter PD_PANASONIC_KXP2180_E_MONO, "Panasonic KX-P2180 (Standard Mode)(B/W)", generInfo
DefPrinter PD_PANASONIC_KXP2180_E, "Panasonic KX-P2180 (Standard Mode)(Color)", ex800Info
DefPrinter PD_PHILIPS_NMS_1433_E, "Philips NMS 1433 (Epson Mode)", fx85Info
DefPrinter PD_RELISYS_RP1814_E, "Relisys RP1814 (Epson Mode)", generInfo
DefPrinter PD_RELISYS_RP2410_E, "Relisys RP2410 (Epson Mode)", generInfo
DefPrinter PD_SAKATA_SP1500, "Sakata SP-1500", generInfo
DefPrinter PD_SEARS_SR2000_E, "Sears SR-2000 (Epson Mode)", generInfo
DefPrinter PD_SEARS_SR3000_E, "Sears SR-3000 (Epson Mode)", generInfo
DefPrinter PD_SEIKOSHA_BP5460, "Seikosha BP-5460", generwInfo
DefPrinter PD_SEIKOSHA_MP5300AI_E, "Seikosha MP-5300AI (Epson Mode)", generwInfo
DefPrinter PD_SEIKOSHA_SK3000AI_E, "Seikosha SK-3000AI (Epson Mode)", generInfo
DefPrinter PD_SEIKOSHA_SK3005AI_E, "Seikosha SK-3005AI (Epson Mode)", generwInfo
DefPrinter PD_SEIKOSHA_SP1000A, "Seikosha SP-1000A", generInfo
DefPrinter PD_SEIKOSHA_SP1200AI_E, "Seikosha SP-1200AI (Epson Mode)", generInfo
DefPrinter PD_SEIKOSHA_SP1600AI_E, "Seikosha SP-1600AI (Epson Mode)", generInfo
DefPrinter PD_SEIKOSHA_SP180AI_E, "Seikosha SP-180AI (Epson Mode)", generInfo
DefPrinter PD_STAR_ND15, "Star ND-15", generwInfo
DefPrinter PD_STAR_NP10, "Star NP-10", generInfo
DefPrinter PD_STAR_NR10_E, "Star NR-10 (Standard Mode)", generInfo
DefPrinter PD_STAR_NR15_E, "Star NR-15 (Standard Mode)", generwInfo
DefPrinter PD_STAR_NX10_E, "Star NX-10 (Standard Mode)", generInfo
DefPrinter PD_STAR_NX1000_E_MONO, "Star NX-1000 (Standard Mode)(B/W)", generInfo
DefPrinter PD_STAR_NX1000_E, "Star NX-1000 (Standard Mode)(Color)", ex800Info
DefPrinter PD_STAR_NX1001, "Star NX-1001", generInfo
DefPrinter PD_STAR_NX1010_E_MONO, "Star NX-1010 (Standard Mode)(B/W)", generInfo
DefPrinter PD_STAR_NX1010_E, "Star NX-1010 (Standard Mode)(Color)", ex800Info
DefPrinter PD_STAR_NX1020_E_MONO, "Star NX-1020 (Standard Mode)(B/W)", generInfo
DefPrinter PD_STAR_NX1020_E, "Star NX-1020 (Standard Mode)(Color)", ex800Info
DefPrinter PD_STAR_NX15_E, "Star NX-15 (Standard Mode)", generwInfo
DefPrinter PD_STAR_XR1000_E_MONO, "Star XR-1000 (Standard Mode)(B/W)", generInfo
DefPrinter PD_STAR_XR1000_E, "Star XR-1000 (Standard Mode)(Color)", ex800Info
DefPrinter PD_STAR_XR1020_E_MONO, "Star XR-1020 (Standard Mode)(B/W)", generInfo
DefPrinter PD_STAR_XR1020_E, "Star XR-1020 (Standard Mode)(Color)", ex800Info
DefPrinter PD_STAR_XR1500_E_MONO, "Star XR-1500 (Standard Mode)(B/W)",generwInfo
DefPrinter PD_STAR_XR1500_E, "Star XR-1500 (Standard Mode)(Color)", ex1000Info
DefPrinter PD_STAR_XR1520_E_MONO, "Star XR-1520 (Standard Mode)(B/W)",generwInfo
DefPrinter PD_STAR_XR1520_E, "Star XR-1520 (Standard Mode)(Color)", ex1000Info
DefPrinter PD_TANDY_DMP135_E, "Tandy DMP 135 (Epson Mode)", generInfo
DefPrinter PD_TANDY_DMP136_E_MONO, "Tandy DMP 136 (Epson Mode)(B/W)", generInfo
DefPrinter PD_TANDY_DMP136_E, "Tandy DMP 136 (Epson Mode)(Color)", ex800Info
DefPrinter PD_TANDY_DMP137_E_MONO, "Tandy DMP 137 (Epson Mode)(B/W)", generInfo
DefPrinter PD_TANDY_DMP137_E, "Tandy DMP 137 (Epson Mode)(Color)", ex800Info
DefPrinter PD_TANDY_DMP2130_E, "Tandy DMP 2130 (Epson Mode)", fx286eInfo
DefPrinter PD_UNISYS_AP1327_E, "Unisys AP 1327 (Epson Mode)", generInfo

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
asciiTransTable         chunk.char ";;",0


;Create the actual tables now......
PrinterTables


DriverInfo	ends

