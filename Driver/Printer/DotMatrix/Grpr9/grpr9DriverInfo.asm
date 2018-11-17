COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		IBM Graphics Printer 9-pin printer driver
FILE:		grpr9DriverInfo.asm

AUTHOR:		Dave Durran

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	2/93		Initial 2.0 version

DESCRIPTION:
	Driver info for the graphics printer 9-pin printer driver

	The file "printerDriver.def" should be included before this one
		

	$Id: grpr9DriverInfo.asm,v 1.1 97/04/18 11:55:26 newdeal Exp $

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


DefPrinter PD_IBM_GP, "IBM Graphics Printer", grprInfo
DefPrinter PD_IBM_3812, "IBM Pageprinter 3812", grprInfo
DefPrinter PD_IBM_PP, "IBM Proprinter", pp1Info
DefPrinter PD_INFOSCRIBE_1100_I, "Infoscribe 1100 (IBM Mode)", grprInfo
DefPrinter PD_INFOSCRIBE_1400_I, "Infoscribe 1400 (IBM Mode)", grprInfo
DefPrinter PD_OLIVETTI_DM109_I, "Olivetti DM 109 (IBM Mode)", pp1Info
DefPrinter PD_OLIVETTI_DM99_I, "Olivetti DM 99 (IBM Mode)", pp1Info
DefPrinter PD_PANASONIC_KXP1080I_I, "Panasonic KX-P1080i (IBM Mode)", grprInfo
DefPrinter PD_PANASONIC_KXP1091_I, "Panasonic KX-P1091 (IBM Mode)", grprInfo
DefPrinter PD_PANASONIC_KXP1091I_I, "Panasonic KX-P1091i (IBM Mode)", grprInfo
DefPrinter PD_PANASONIC_KXP1092I_I, "Panasonic KX-P1092i (IBM Mode)", pp1Info
DefPrinter PD_TANDY_DMP106_I, "Tandy DMP 106 (IBM Mode)", grprInfo
DefPrinter PD_TANDY_DMP107_I, "Tandy DMP 107 (IBM Mode)", grprInfo
DefPrinter PD_TANDY_DMP130A_I, "Tandy DMP 130A (IBM Mode)", grprInfo
DefPrinter PD_TANDY_DMP132_I, "Tandy DMP 132 (IBM Mode)", grprInfo
DefPrinter PD_TANDY_DMP133_I, "Tandy DMP 133 (IBM Mode)", grprInfo
DefPrinter PD_TANDY_DMP2120_I, "Tandy DMP 2120 (IBM Mode)", grprInfo

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
