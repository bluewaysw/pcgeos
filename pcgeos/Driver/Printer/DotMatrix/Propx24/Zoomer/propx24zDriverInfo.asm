COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		IBM Proprinter X24 24-pin printer driver for Zoomer
FILE:		propx24zDriverInfo.asm

AUTHOR:		Dave Durran, 26 Mar 1990

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/27/90		Initial revision
	Dave	5/92		Initial 2.0 version

DESCRIPTION:
	Driver info for the propx 24-pin printer driver

	The file "printerDriver.def" should be included before this one
		

	$Id: propx24zDriverInfo.asm,v 1.1 97/04/18 11:53:44 newdeal Exp $

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


DefPrinter PD_IBM_PPRINTER_X24, "IBM Proprinter X24", generInfo
DefPrinter PD_IBM_PPRINTER_XL24, "IBM Proprinter XL24", generwInfo
DefPrinter PD_IBM_PS1PRINTER, "IBM PS/1 Printer", ps1Info
DefPrinter PD_TANDY_DMP202, "Tandy DMP 202 (IBM)", generInfo
DefPrinter PD_TANDY_DMP203, "Tandy DMP 203 (IBM)", generInfo
DefPrinter PD_TANDY_DMP240_I, "Tandy DMP 240 (IBM)", generInfo
DefPrinter PD_TANDY_DMP300_I, "Tandy DMP 300 (IBM)", generInfo
DefPrinter PD_TANDY_DMP302_I, "Tandy DMP 302 (IBM)", generInfo
DefPrinter PD_TANDY_DMP310_I, "Tandy DMP 310 (IBM)", generInfo
DefPrinter PD_TANDY_DMP2102_I, "Tandy DMP 2102 (IBM)", generwInfo
DefPrinter PD_TANDY_DMP2103_I, "Tandy DMP 2103 (IBM)", generwInfo
DefPrinter PD_TANDY_DMP2104_I, "Tandy DMP 2104 (IBM)", generwInfo
DefPrinter PD_TANDY_JP250_I, "Tandy JP 250 (IBM)", bjIBMInfo


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
