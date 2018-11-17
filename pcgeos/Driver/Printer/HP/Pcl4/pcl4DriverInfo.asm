COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		LaserJet printer driver
FILE:		pcl4DriverInfo.asm

AUTHOR:		Dave Durran

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	1/92		Initial revision from laserdwnDriverInfo.asm

DESCRIPTION:
	Driver info for the PCL 4 printer driver

	The file "printerDriver.def" should be included before this one
		

	$Id: pcl4DriverInfo.asm,v 1.1 97/04/18 11:52:22 newdeal Exp $

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
DefPrinter PD_HP_LASERJETS, "HP LaserJet Compatible", downloadInfo
else
;
; Default printer driver list (all known supported devices)
;
; The following models need to be officially tested:
;   HP Laserjet 4050 Brother HL-631 Brother HL-730
;
DefPrinter PD_BLAZER_STAR_2, "Blazer Star II", internalInfo
DefPrinter PD_BROTHER_HL4, "Brother HL-4 (HP Mode)", internalInfo
DefPrinter PD_BROTHER_HL631, "Brother HL-631", laserjet2Info
DefPrinter PD_BROTHER_HL730, "Brother HL-730", internalInfo
DefPrinter PD_BROTHER_HL8E, "Brother HL-8e (HP Mode)", internalInfo
DefPrinter PD_BROTHER_HL8PS_HP, "Brother HL-8PS (HP Mode)", internalInfo
DefPrinter PD_CANON_LBP4SX, "Canon LBP-4SX (HP Mode)", downloadInfo
DefPrinter PD_CANON_LBP8SX, "Canon LBP-8SX (HP Mode)", downloadInfo
DefPrinter PD_DATAPRODUCTS_LZR1230, "Dataproducts LZR1230", totalResetInfo
DefPrinter PD_EPSON_AL_1000, "Epson ActionLaser 1000 (HP Mode)", downloadInfo
DefPrinter PD_EPSON_AL_1100, "Epson ActionLaser 1100 (HP Mode)", downloadInfo
DefPrinter PD_EPSON_AL_1400, "Epson ActionLaser 1400 (HP Mode)", downloadInfo
DefPrinter PD_EPSON_AL_1500, "Epson ActionLaser 1500 (HP Mode)", downloadInfo
DefPrinter PD_EPSON_EPL7000, "Epson EPL-7000 (HP Mode)", downloadInfo
DefPrinter PD_HP_LJ_PLUS, "HP LaserJet PLUS", internalInfo
DefPrinter PD_HP_LJ_500_PLUS, "HP LaserJet 500 PLUS", internalInfo
DefPrinter PD_HP_LJ_2, "HP LaserJet II", laserjet2Info
DefPrinter PD_HP_LJ_2D, "HP LaserJet IID", downloadDuplexInfo
DefPrinter PD_HP_LJ_2_COMP, "HP LaserJet II Compatible", laserjet2Info
DefPrinter PD_HP_LJ_2P, "HP LaserJet IIP", downloadInfo
DefPrinter PD_HP_LJ_2P_PLUS, "HP LaserJet IIP Plus", downloadInfo
DefPrinter PD_HP_LJ_3, "HP LaserJet III", downloadInfo
DefPrinter PD_HP_LJ_3D, "HP LaserJet IIID", laserjet3DInfo
DefPrinter PD_HP_LJ_3P, "HP LaserJet IIIP", downloadInfo
DefPrinter PD_HP_LJ_3SI, "HP LaserJet IIISi", laserjet3SiInfo
DefPrinter PD_HP_LJ_4, "HP LaserJet 4 (PCL Mode)", laserjet4Info
DefPrinter PD_HP_LJ_4_PLUS, "HP LaserJet 4 Plus", laserjet4Info
DefPrinter PD_HP_LJ_4M_HP, "HP LaserJet 4M (PCL Mode)", laserjet4Info
DefPrinter PD_HP_LJ_4L, "HP LaserJet 4L", downloadInfo
DefPrinter PD_HP_LJ_4SI, "HP LaserJet 4Si", laserjet3SiInfo
DefPrinter PD_HP_LJ_4050, "HP LaserJet 4050", laserjet4Info
DefPrinter PD_HP_LJ_5L, "HP LaserJet 5L", downloadInfo
DefPrinter PD_HP_LJ_5P, "HP LaserJet 5P", downloadInfo
DefPrinter PD_HP_LJ_5SI, "HP LaserJet 5Si", laserjet3SiInfo
DefPrinter PD_HP_PJ_XL300, "HP PaintJet XL300 (B/W)", paintjetxl300Info
DefPrinter PD_HP_PCL_DF, "HP PCL Download Font Driver ", downloadInfo
DefPrinter PD_IBM_4019_HP, "IBM 4019 LaserPrinter (PCL Mode)", ibm4019Info
DefPrinter PD_IBM_4019_PPDS, "IBM 4019 LaserPrinter (PPDS Mode)", ppdsInfo
DefPrinter PD_IBM_4029_HP, "IBM 4029 LaserPrinter (PCL Mode)", ibm4019Info
DefPrinter PD_IBM_4029_PPDS, "IBM 4029 LaserPrinter (PPDS Mode)", ppdsInfo
DefPrinter PD_IBM_4039_HP, "IBM 4039 LaserPrinter (PCL Mode)", ibm4039Info
DefPrinter PD_KYOCERA_F, "Kyocera F-Series", downloadInfo
DefPrinter PD_LEXMARK_4039_HP, "Lexmark 4039 (PCL Mode)", ibm4039Info
DefPrinter PD_MANN_TALLY_905, "Mannesmann Tally 905", internalInfo
DefPrinter PD_OKI_600E, "Okidata OL600e", downloadInfo
DefPrinter PD_OKI_810E, "Okidata OL810e", laserjet4Info
DefPrinter PD_OKI_830_HP, "Okidata OL830 (HP Mode)", laserjet2CompInfo
DefPrinter PD_OLIVETTI_PG306, "Olivetti PG 306 (HP Mode)", downloadInfo
DefPrinter PD_OLIVETTI_PG308, "Olivetti PG 308 (HP Mode)", downloadInfo
DefPrinter PD_PANASONIC_KXP4410, "Panasonic KX-P4410", downloadInfo
DefPrinter PD_PANASONIC_KXP4420, "Panasonic KX-P4420", laserjet2CompInfo
DefPrinter PD_PANASONIC_KXP4430, "Panasonic KX-P4430", downloadInfo
DefPrinter PD_PANASONIC_KXP4450, "Panasonic KX-P4450", internalInfo
DefPrinter PD_PANASONIC_KXP4450I, "Panasonic KX-P4450i", internalInfo
DefPrinter PD_PANASONIC_KXP4451, "Panasonic KX-P4451", downloadInfo
DefPrinter PD_PHILIPS_NMS1481_HP, "Philips NMS 1481 (HP Mode)", laserjet2Info
DefPrinter PD_STAR_LASER_4, "Star LaserPrinter 4 (HP Mode)", downloadInfo
DefPrinter PD_STAR_LASER_8, "Star LaserPrinter 8 (HP Mode)", internalInfo
DefPrinter PD_STAR_LASER_8_II, "Star LaserPrinter 8 II (HP Mode)", downloadInfo
DefPrinter PD_TANDY_LP400, "Tandy LP 400", downloadInfo
DefPrinter PD_TANDY_LP410_HP, "Tandy LP 410 (HP Mode)", downloadInfo
DefPrinter PD_TANDY_LP800_HP, "Tandy LP 800 (HP Mode)", downloadInfo
DefPrinter PD_TANDY_LP950, "Tandy LP 950", laserjet2Info
DefPrinter PD_TANDY_LP990, "Tandy LP 990", laserjet2Info
DefPrinter PD_TANDY_LP1000, "Tandy LP 1000", internalInfo
DefPrinter PD_TOSHIBA_PL_6_HP, "Toshiba PageLaser6 (HP Mode)", laserjet2Info
endif

;----------------------------------------------------------------------------
;	Driver Info Header
;----------------------------------------------------------------------------

DriverExtendedInfoTable			 < 
					  {},			; lmem hdr
					  PrintDevice/2,	; # devices
					  offset deviceStrings, ; devices
					  offset deviceInfoTab	; info blocks
					 >

PrintDriverInfo				< 30,		;device timout
					  PR_RESEND,	;
                                          isoSubstitutions,    ;ISO sub tab.
                                          asciiTransTable,
                                          PDT_PRINTER,
                                          TRUE
					>


;----------------------------------------------------------------------------
;	Device String Table and Strings
;----------------------------------------------------------------------------

isoSubstitutions        chunk.word  0ffffh	;no ISO Subs.


        ; ASCII Translation List for Foreign Language Versions
asciiTransTable         chunk.char ";;",0


;create the Tables.....
PrinterTables



DriverInfo	ends
