COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		IBM Proprinter X24 24-pin printer driver
FILE:		propx24DriverInfo.asm

AUTHOR:		Dave Durran, 26 Mar 1990

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/27/90		Initial revision
	Dave	5/92		Initial 2.0 version

DESCRIPTION:
	Driver info for the propx 24-pin printer driver

	The file "printerDriver.def" should be included before this one
		

	$Id: propx24DriverInfo.asm,v 1.1 97/04/18 11:53:47 newdeal Exp $

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


DefPrinter PD_AEG_NP13624_I, "AEG Olympia NP 136-24 (IBM Mode)", generwInfo
DefPrinter PD_AEG_NP8024_I, "AEG Olympia NP 80-24 (IBM Mode)", generInfo
DefPrinter PD_AMT_ACCEL_500_I, "AMT Accel-500 (IBM Mode)", generwInfo
DefPrinter PD_ATT_580_I, "AT&T 580 (IBM Mode)", generInfo
DefPrinter PD_ATT_581_I, "AT&T 581 (IBM Mode)", generwInfo
DefPrinter PD_ATT_583_I, "AT&T 583 (IBM Mode)", generwInfo
DefPrinter PD_AMSTRAD_LQ3500_I, "Amstrad LQ 3500 (IBM Mode)", generInfo
DefPrinter PD_BROTHER_M1824L_I, "Brother M-1824L (IBM Mode)", generInfo
DefPrinter PD_CITOH_C815_I, "C.Itoh C-815 (IBM Mode)", generwInfo
DefPrinter PD_CANON_BJ_30_I, "Canon BJ-30 (IBM Mode)", generInfo
DefPrinter PD_CANON_BJ_230_I, "Canon BJ-230 (IBM Mode)", generInfo
DefPrinter PD_CANON_BJC_70_I, "Canon BJC-70 (IBM Mode)(B/W)", generInfo
DefPrinter PD_CANON_BJC_210_I, "Canon BJC-210 (IBM Mode)(B/W)", generInfo
DefPrinter PD_CITIZEN_GSX130_I, "Citizen GSX-130 (IBM Mode)", generInfo
DefPrinter PD_CITIZEN_GSX140_I, "Citizen GSX-140 (IBM Mode)", generInfo
DefPrinter PD_CITIZEN_GSX145_I, "Citizen GSX-145 (IBM Mode)", generwInfo
DefPrinter PD_CITIZEN_PN48_I, "Citizen PN-48 (IBM Mode)", bjIBMInfo
DefPrinter PD_EPSON_LQ_300_I, "Epson LQ-300 (IBM Mode)", generInfo
DefPrinter PD_FACIT_B2400_I, "Facit B2400 (IBM Mode)", generInfo
DefPrinter PD_FUJITSU_DL4400_I, "Fujitsu DL4400 (IBM Mode)", generInfo
DefPrinter PD_GENICOM_1040_I, "Genicom 1040 (IBM Mode)", generInfo
DefPrinter PD_IBM_5183_I, "IBM Portable 5183 (IBM Mode)", bjIBMInfo
DefPrinter PD_IBM_PPRINTER_24P, "IBM Proprinter 24P", pp24pInfo
DefPrinter PD_IBM_PPRINTER_X24, "IBM Proprinter X24", generInfo
DefPrinter PD_IBM_PPRINTER_X24E, "IBM Proprinter X24E", generInfo
DefPrinter PD_IBM_PPRINTER_XL24, "IBM Proprinter XL24", generwInfo
DefPrinter PD_IBM_PPRINTER_XL24E, "IBM Proprinter XL24E", generwInfo
DefPrinter PD_IBM_PS1PRINTER, "IBM PS/1 Printer", ps1Info
DefPrinter PD_IBM_QKWRTR, "IBM Quickwriter", generwInfo
DefPrinter PD_OLIVETTI_DM124_I, "Olivetti DM 124 (IBM Mode)", generInfo
DefPrinter PD_OLIVETTI_DM124C_I, "Olivetti DM 124C (IBM Mode)", generInfo
DefPrinter PD_OLIVETTI_DM124L_I, "Olivetti DM 124L (IBM Mode)", generwInfo
DefPrinter PD_OLIVETTI_DM324_I, "Olivetti DM 324 (IBM Mode)", generInfo
DefPrinter PD_OLIVETTI_DM324L_I, "Olivetti DM 324L (IBM Mode)", generwInfo
DefPrinter PD_OLIVETTI_DM624_I, "Olivetti DM 624 (IBM Mode)", generwInfo
DefPrinter PD_PANASONIC_KXP1123_I, "Panasonic KX-P1123 (IBM Mode)", generInfo
DefPrinter PD_PANASONIC_KXP1124_I, "Panasonic KX-P1124 (IBM Mode)", generInfo
DefPrinter PD_PANASONIC_KXP1124I_I, "Panasonic KX-P1124i (IBM Mode)", generInfo
DefPrinter PD_PANASONIC_KXP1624_I, "Panasonic KX-P1624 (IBM Mode)", generwInfo
DefPrinter PD_PANASONIC_KXP2023_I, "Panasonic KX-P2023 (IBM Mode)", generInfo
DefPrinter PD_PANASONIC_KXP2123_I, "Panasonic KX-P2123 (IBM Mode)", generInfo
DefPrinter PD_PANASONIC_KXP2124_I, "Panasonic KX-P2124 (IBM Mode)", generInfo
DefPrinter PD_PANASONIC_KXP2624_I, "Panasonic KX-P2624 (IBM Mode)", generwInfo
DefPrinter PD_PHILIPS_NMS1461_I, "Philips NMS 1461 (IBM Mode)", generInfo
DefPrinter PD_PHILIPS_NMS1467_I, "Philips NMS 1467 (IBM Mode)", generwInfo
DefPrinter PD_SEIKOSHA_SL130AI_I, "Seikosha SL-130AI (IBM Mode)", generwInfo
DefPrinter PD_SEIKOSHA_SL230AI_I, "Seikosha SL-230AI (IBM Mode)", generwInfo
DefPrinter PD_STAR_NB2410_I, "Star NB-24-10 (IBM Mode)", generInfo
DefPrinter PD_STAR_NB2415_I, "Star NB-24-15 (IBM Mode)", generwInfo
DefPrinter PD_STAR_NX2420_I, "Star NX-2420 (IBM Mode)", generInfo
DefPrinter PD_TANDY_DMP202, "Tandy DMP 202", generInfo
DefPrinter PD_TANDY_DMP203, "Tandy DMP 203", generInfo
DefPrinter PD_TANDY_DMP240_I, "Tandy DMP 240 (IBM Mode)", generInfo
DefPrinter PD_TANDY_DMP300_I, "Tandy DMP 300 (IBM Mode)", generInfo
DefPrinter PD_TANDY_DMP302_I, "Tandy DMP 302 (IBM Mode)", generInfo
DefPrinter PD_TANDY_DMP310_I, "Tandy DMP 310 (IBM Mode)", generInfo
DefPrinter PD_TANDY_DMP2102_I, "Tandy DMP 2102 (IBM Mode)", generwInfo
DefPrinter PD_TANDY_DMP2103_I, "Tandy DMP 2103 (IBM Mode)", generwInfo
DefPrinter PD_TANDY_DMP2104_I, "Tandy DMP 2104 (IBM Mode)", generwInfo
DefPrinter PD_TANDY_JP250_I, "Tandy JP 250 (IBM Mode)", bjIBMInfo


;----------------------------------------------------------------------------
;	Driver Info Header
;----------------------------------------------------------------------------

DriverExtendedInfoTable			 < {},		; lmem hdr
					   PrintDevice/2,	; # devices
					   offset deviceStrings, ; devices
					   offset deviceInfoTab	; info blocks
					 >

PrintDriverInfo			      < 30,			; timeout (sec)
					PR_DONT_RESEND,	;
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


;create the actual tables here.....
PrinterTables


DriverInfo	ends
