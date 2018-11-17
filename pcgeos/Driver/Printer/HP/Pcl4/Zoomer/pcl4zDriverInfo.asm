COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		LaserJet printer driver
FILE:		pcl4zDriverInfo.asm

AUTHOR:		Dave Durran

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	1/92		Initial revision from laserdwnDriverInfo.asm

DESCRIPTION:
	Driver info for the PCL 4 printer driver

	The file "printerDriver.def" should be included before this one
		

	$Id: pcl4zDriverInfo.asm,v 1.1 97/04/18 11:52:16 newdeal Exp $

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


DefPrinter PD_HP_LJ_PLUS, "HP LaserJet PLUS", internalInfo
DefPrinter PD_HP_LJ_2, "HP LaserJet II", laserjet2Info
DefPrinter PD_HP_LJ_2D, "HP LaserJet IID", downloadDuplexInfo
DefPrinter PD_HP_LJ_2P, "HP LaserJet IIP", downloadInfo
DefPrinter PD_HP_LJ_3, "HP LaserJet III", downloadInfo
DefPrinter PD_HP_LJ_3D, "HP LaserJet IIID", laserjet3DInfo
DefPrinter PD_HP_LJ_3P, "HP LaserJet IIIP", downloadInfo
DefPrinter PD_HP_LJ_4, "HP LaserJet 4 (PCL)", laserjet4Info
DefPrinter PD_HP_LJ_4L, "HP LaserJet 4L", downloadInfo
DefPrinter PD_TANDY_LP400, "Tandy LP 400 (HP)", downloadInfo
DefPrinter PD_TANDY_LP410_HP, "Tandy LP 410 (HP)", downloadInfo
DefPrinter PD_TANDY_LP800_HP, "Tandy LP 800 (HP)", downloadInfo
DefPrinter PD_TANDY_LP950, "Tandy LP 950 (HP)", laserjet2Info
DefPrinter PD_TANDY_LP990, "Tandy LP 990 (HP)", laserjet2Info
DefPrinter PD_TANDY_LP1000, "Tandy LP 1000 (HP)", internalInfo

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
