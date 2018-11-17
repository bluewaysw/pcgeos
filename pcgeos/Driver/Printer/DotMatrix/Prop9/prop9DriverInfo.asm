COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		IBM Proprinter 9-pin printer driver
FILE:		prop9DriverInfo.asm

AUTHOR:		Dave Durran, 27 Feb 1990

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	2/27/90		Initial revision
	Dave	5/92		Initial 2.0 version

DESCRIPTION:
	Driver info for the prop 9-pin printer driver

	The file "printerDriver.def" should be included before this one
		

	$Id: prop9DriverInfo.asm,v 1.1 97/04/18 11:54:01 newdeal Exp $

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


DefPrinter PD_ALPS_ASP1000_I, "ALPS ASP1000 (IBM Mode)", pp2Info
DefPrinter PD_ATT_570_I, "AT&T 570 (IBM Mode)", pp2Info
DefPrinter PD_ATT_571_I, "AT&T 571 (IBM Mode)", xlInfo
DefPrinter PD_AMSTRAD_DMP3000_I, "Amstrad DMP3000 (IBM Mode)", pp2Info
DefPrinter PD_AXONIX_LITEWRITE_I, "Axonix LiteWrite (IBM Mode)", pp2Info
DefPrinter PD_AXONIX_THINWRITE_I, "Axonix ThinWrite 100 (IBM Mode)", pp2Info
DefPrinter PD_BLUECHIP_M200_I, "Blue Chip M200/NLQ (IBM Mode)", pp2Info
DefPrinter PD_BROTHER_M1109_I, "Brother M-1109 (IBM Mode)", pp2Info
DefPrinter PD_BROTHER_M1709_I, "Brother M-1709 (IBM Mode)", xlInfo
DefPrinter PD_BROTHER_M1724L_I, "Brother M-1724L (IBM Mode)", xlInfo
DefPrinter PD_BROTHER_M1809_I, "Brother M-1809 (IBM Mode)", pp2Info
DefPrinter PD_BROTHER_M2518_I, "Brother M-2518 (IBM Mode)", xlInfo
DefPrinter PD_BROTHER_M4018_I, "Brother M-4018 (IBM Mode)", xlInfo
DefPrinter PD_BROTHER_TW6_I, "Brother Twinriter 6 (IBM Mode)", xlInfo
DefPrinter PD_CITOH_5000_I, "C.Itoh 5000 (IBM Mode)", xlInfo
DefPrinter PD_CITOH_C610_I, "C.Itoh C-610 (IBM Mode)", pp2Info
DefPrinter PD_CITOH_CI2500_I, "C.Itoh CI-2500 (IBM Mode)", xlInfo
DefPrinter PD_CITOH_C310_I, "C.Itoh ProWriter C-310 CXP (IBM Mode)", pp2Info
DefPrinter PD_CITOH_CI3500, "C.Itoh TriPrinter CI-3500", xlInfo
DefPrinter PD_CITOH_CI5000, "C.Itoh TriPrinter CI-5000", xlInfo
DefPrinter PD_CANON_BJ130, "Canon BJ-130", bjInfo
DefPrinter PD_CITIZEN_HSP500_I, "Citizen HSP-500 (IBM Mode)", pp2Info
DefPrinter PD_CITIZEN_HSP550_I, "Citizen HSP-550 (IBM Mode)", xlInfo
DefPrinter PD_CITIZEN_MSP40_I, "Citizen MSP-40 (IBM Mode)", pp2Info
DefPrinter PD_CITIZEN_MSP55_I, "Citizen MSP-55 (IBM Mode)", pp2Info
DefPrinter PD_CITIZEN_T124_I, "Citizen Tribute 124 (LQ interface, IBM Mode)", pp2Info
DefPrinter PD_COPAL_5930_I, "Copal Writehand 5930 (IBM Mode)", xlInfo
DefPrinter PD_COPAL_6730_I, "Copal Writehand 6730 (IBM Mode)", xlInfo
DefPrinter PD_DATAPRODUCTS_8070_I, "Dataproducts 8070 Plus (IBM Mode)", xlInfo
DefPrinter PD_DATAPRODUCTS_SI480_I, "Dataproducts SI 480 (IBM Mode)", xlInfo
DefPrinter PD_DICONIX_150_I, "Diconix 150 + (IBM Mode)", pp2Info
DefPrinter PD_DICONIX_300_I, "Diconix 300 (IBM Mode)", pp2Info
DefPrinter PD_DICONIX_300W_I, "Diconix 300w (IBM Mode)", xlInfo
DefPrinter PD_EPSON_DFX8000_I, "Epson DFX-8000 (IBM Mode)", xlInfo
DefPrinter PD_EPSON_EX1000_I, "Epson EX-1000 (IBM Mode)", xlInfo
DefPrinter PD_EPSON_EX800_I, "Epson EX-800 (IBM Mode)", pp2Info
DefPrinter PD_EPSON_FX1050_I, "Epson FX-1050 (IBM Mode)", xlInfo
DefPrinter PD_EPSON_FX850_I, "Epson FX-850 (IBM Mode)", pp2Info
DefPrinter PD_FACIT_B3100_I, "Facit B3100 (IBM Mode)", pp2Info
DefPrinter PD_FACIT_B3150_I, "Facit B3150 (IBM Mode)", pp2Info
DefPrinter PD_FACIT_B3350_I, "Facit B3350 (IBM Mode)", xlInfo
DefPrinter PD_FACIT_B3550_I, "Facit B3550 (IBM Mode)", xlInfo
DefPrinter PD_FORTIS_DM1310_I, "Fortis DM 1310 (IBM Mode)", pp2Info
DefPrinter PD_FORTIS_DM2210_I, "Fortis DM 2210 (IBM Mode)", pp2Info
DefPrinter PD_FORTIS_DM2215_I, "Fortis DM 2215 (IBM Mode)", xlInfo
DefPrinter PD_FORTIS_DM4110_I, "Fortis DQ 4110 (IBM Mode)", pp2Info
DefPrinter PD_FORTIS_DM4210_I, "Fortis DQ 4210 (IBM Mode)", pp2Info
DefPrinter PD_FORTIS_DM4215_I, "Fortis DQ 4215 (IBM Mode)", xlInfo
DefPrinter PD_FUJITSU_DL2600_I, "Fujitsu DL2600 (IBM Mode)", xlInfo
DefPrinter PD_FUJITSU_DL3400_I, "Fujitsu DL3400 (IBM Mode)", xlInfo
DefPrinter PD_FUJITSU_DL5600_I, "Fujitsu DL5600 (IBM Mode)", xlInfo
DefPrinter PD_FUJITSU_DX2300_I, "Fujitsu DX2300 (Type I)", pp2Info
DefPrinter PD_FUJITSU_DX2400_I, "Fujitsu DX2400 (Type I)", xlInfo
DefPrinter PD_GENICOM_3410XLQ_I, "Genicom 3410XLQ (IBM Mode)", xlInfo
DefPrinter PD_GENICOM_3820_I, "Genicom 3820 (IBM Mode)", xlInfo
DefPrinter PD_GENICOM_PS220_I, "Genicom Printstation 220 (IBM Mode)", xlInfo
DefPrinter PD_HONEYWELL_466_I, "Honeywell Bull 4/66 (IBM Mode)", pp2Info
DefPrinter PD_HYUNDAI_HDP1810_I, "Hyundai HDP-1810 (IBM Card)", pp2Info
DefPrinter PD_HYUNDAI_HDP1820_I, "Hyundai HDP-1820 (IBM Card)", xlInfo
DefPrinter PD_HYUNDAI_HDP910_I, "Hyundai HDP-910 (IBM Mode)", pp2Info
DefPrinter PD_HYUNDAI_HDP920_I, "Hyundai HDP-920 (IBM Mode)", xlInfo
DefPrinter PD_IBM_2380, "IBM Personal Printer Series II 2380", pp2380Info
DefPrinter PD_IBM_2381, "IBM Personal Printer Series II 2381", pp2381Info
DefPrinter PD_IBM_PP2, "IBM Proprinter II", pp2Info
DefPrinter PD_IBM_PP3, "IBM Proprinter III", pp2Info
DefPrinter PD_IBM_PP3XL, "IBM Proprinter III XL", xlInfo
DefPrinter PD_IBM_PPXL, "IBM Proprinter XL", xlInfo
DefPrinter PD_LASER_190E_I, "Laser 190E (IBM Mode)", pp2Info
DefPrinter PD_LASER_240_I, "Laser 240 (IBM Mode)", pp2Info
DefPrinter PD_MANN_TALLY_222_I, "Mannesmann Tally 222 (IBM Mode)", xlInfo
DefPrinter PD_MANN_TALLY_230_I, "Mannesmann Tally 230/24 (IBM Mode)", xlInfo
DefPrinter PD_MANN_TALLY_340_I, "Mannesmann Tally 340 (IBM Mode)", xlInfo
DefPrinter PD_MANN_TALLY_81_I, "Mannesmann Tally 81 (IBM Mode)", pp2Info
DefPrinter PD_MANN_TALLY_87_I, "Mannesmann Tally 87 (IBM Mode)", pp2Info
DefPrinter PD_MANN_TALLY_90_I, "Mannesmann Tally 90 (IBM Mode)", pp2Info
DefPrinter PD_OTC_TM850XL_I, "OTC TriMatrix 850XL (IBM Mode)", xlInfo
DefPrinter PD_OKI_ML172, "Okidata ML 172", pp2Info
DefPrinter PD_OKI_ML182, "Okidata ML 182", pp2Info
DefPrinter PD_OKI_ML193_I, "Okidata ML 192 (IBM Mode)", pp2Info
DefPrinter PD_OKI_ML320_I, "Okidata ML 193 (IBM Mode)", xlInfo
DefPrinter PD_OKI_ML321_I, "Okidata ML 320 (IBM Mode)", pp2Info
DefPrinter PD_OKI_ML192_I, "Okidata ML 321 (IBM Mode)", xlInfo
DefPrinter PD_OKI_ML390_I, "Okidata ML 390 (IBM Mode)", pp2Info
DefPrinter PD_OKI_ML391_I, "Okidata ML 391 (IBM Mode)", xlInfo
DefPrinter PD_OLIVETTI_DM309_I, "Olivetti DM 309 (IBM Mode)", pp2Info
DefPrinter PD_OLIVETTI_DM309L_I, "Olivetti DM 309L (IBM Mode)", xlInfo
DefPrinter PD_OLYMPIA_NP136_I, "Olympia NP136 (IBM Mode)", xlInfo
DefPrinter PD_OLYMPIA_NP30_I, "Olympia NP30 (IBM Mode)", pp2Info
DefPrinter PD_OLYMPIA_NP80_I, "Olympia NP80 (IBM Mode)", pp2Info
DefPrinter PD_OUTPUT_TECH_560DL_I, "Output Technology 560DL (IBM Mode)", xlInfo
DefPrinter PD_OUTPUT_TECH_850SE_I, "Output Technology 850SE (IBM Mode)", xlInfo
DefPrinter PD_PANASONIC_KXP1093_I, "Panasonic KX-P1093 (IBM Mode)", xlInfo
DefPrinter PD_PANASONIC_KXP1180_I, "Panasonic KX-P1180 (IBM Mode)", pp2Info
DefPrinter PD_PANASONIC_KXP1180I_I, "Panasonic KX-P1180i (IBM Mode)", pp2Info
DefPrinter PD_PANASONIC_KXP1191_I, "Panasonic KX-P1191 (IBM Mode)", pp2Info
DefPrinter PD_PANASONIC_KXP1524_I, "Panasonic KX-P1524 (IBM Mode)", xlInfo
DefPrinter PD_PANASONIC_KXP1592_I, "Panasonic KX-P1592 (IBM Mode)", xlInfo
DefPrinter PD_PANASONIC_KXP1595_I, "Panasonic KX-P1595 (IBM Mode)", xlInfo
DefPrinter PD_PANASONIC_KXP1695_I, "Panasonic KX-P1695 (IBM Mode)", xlInfo
DefPrinter PD_PHILIPS_NMS1433_I, "Philips NMS 1433 (IBM Mode)", pp2Info
DefPrinter PD_PRINTRONIX_S7024, "Printronix S-7024", xlInfo
DefPrinter PD_RELISYS_RP1814_I, "Relisys RP1814 (IBM Mode)", pp2Info
DefPrinter PD_RELISYS_RP2410_I, "Relisys RP2410 (IBM Mode)", pp2Info
DefPrinter PD_SANYO_PR241_I, "Sanyo PR-241 (IBM Mode)", xlInfo
DefPrinter PD_SEIKOSHA_MP5300AI_I, "Seikosha MP-5300AI (IBM Mode)", xlInfo
DefPrinter PD_SEIKOSHA_SBP10AI_I, "Seikosha SBP-10AI (IBM Mode)", xlInfo
DefPrinter PD_SEIKOSHA_SK3000AI_I, "Seikosha SK-3000AI (IBM Mode)", pp2Info
DefPrinter PD_SEIKOSHA_SK3005AI_I, "Seikosha SK-3005AI (IBM Mode)", xlInfo
DefPrinter PD_SEIKOSHA_SL80AI_I, "Seikosha SL-80AI (IBM Mode)", pp2Info
DefPrinter PD_SEIKOSHA_SP1200AI_I, "Seikosha SP-1200AI (IBM Mode)", pp2Info
DefPrinter PD_SEIKOSHA_SP1600AI_I, "Seikosha SP-1600AI (IBM Mode)", pp2Info
DefPrinter PD_SEIKOSHA_SP180AI_I, "Seikosha SP-180AI (IBM Mode)", pp2Info
DefPrinter PD_STAR_NR10_I, "Star NR-10 (IBM Mode)", pp2Info
DefPrinter PD_STAR_NR15_I, "Star NR-15 (IBM Mode)", xlInfo
DefPrinter PD_STAR_NX10_I, "Star NX-10 (IBM Mode)", pp2Info
DefPrinter PD_STAR_NX1000_I, "Star NX-1000 (IBM Mode)", pp2Info
DefPrinter PD_STAR_NX1020_I, "Star NX-1020 (IBM Mode)", pp2Info
DefPrinter PD_STAR_NX15_I, "Star NX-15 (IBM Mode)", xlInfo
DefPrinter PD_STAR_NX2400_I, "Star NX-2400 (IBM Mode)", pp2Info
DefPrinter PD_STAR_XB2410_I, "Star XB-2410 (IBM Mode)", pp2Info
DefPrinter PD_STAR_XB2415_I, "Star XB-2415 (IBM Mode)", xlInfo
DefPrinter PD_STAR_XR1000_I, "Star XR-1000 (IBM Mode)", pp2Info
DefPrinter PD_STAR_XR1500_I, "Star XR-1500 (IBM Mode)", xlInfo
DefPrinter PD_STAR_XR1520_I, "Star XR-1520 (IBM Mode)", xlInfo
DefPrinter PD_TANDY_DMP134_I, "Tandy DMP 134 (IBM Mode)", pp2Info
DefPrinter PD_TANDY_DMP135_I, "Tandy DMP 135 (IBM Mode)", pp2Info
DefPrinter PD_TANDY_DMP136_I, "Tandy DMP 136 (IBM Mode)", pp2Info
DefPrinter PD_TANDY_DMP137_I, "Tandy DMP 137 (IBM Mode)", pp2Info
DefPrinter PD_TANDY_DMP442_I, "Tandy DMP 442 (IBM Mode)", xlInfo
DefPrinter PD_TANDY_DMP2130_I, "Tandy DMP 2130 (IBM Mode)", xlInfo
DefPrinter PD_TOSHIBA_EW311_I, "Toshiba ExpressWriter 311 (IBM Mode)", pp2Info
DefPrinter PD_TOSHIBA_P321_I, "Toshiba P321 (IBM Mode)", pp2Info
DefPrinter PD_TOSHIBA_P321SL_I, "Toshiba P321SL (IBM Mode)", pp2Info
DefPrinter PD_TOSHIBA_P321SLC_I, "Toshiba P321SLC (IBM Mode)", pp2Info
DefPrinter PD_TOSHIBA_P341SL_I, "Toshiba P341SL (IBM Mode)", xlInfo
DefPrinter PD_TOSHIBA_P351_I, "Toshiba P351 (IBM Mode)", xlInfo
DefPrinter PD_TOSHIBA_P351C_I, "Toshiba P351C (IBM Mode)", xlInfo
DefPrinter PD_TOSHIBA_P351SX_I, "Toshiba P351SX (IBM Mode)", xlInfo
DefPrinter PD_UNISYS_AP1327_I, "Unisys AP 1327 (IBM Mode)", pp2Info

;----------------------------------------------------------------------------
;	Driver Info Header
;----------------------------------------------------------------------------

DriverExtendedInfoTable		 < {},		; lmem hdr
				    PrintDevice/2,	; # devices
				    offset deviceStrings, ; devices
				    offset deviceInfoTab	; info blocks
				    >

PrintDriverInfo			< 30,			; timeout (sec)
				    PR_DONT_RESEND,
                                    isoSubstitutions,    ;ISO sub tab.
                                    asciiTransTable,
                                    PDT_PRINTER,
                                    TRUE
				>


;----------------------------------------------------------------------------
;	Device String Table and Strings
;----------------------------------------------------------------------------

isoSubstitutions        chunk.word 0ffffh       ;no ISO subs.

        ; ASCII Translation List for Foreign Language Versions
asciiTransTable         chunk.char ";;",0

;Create the actual tables here......
PrinterTables


DriverInfo	ends
