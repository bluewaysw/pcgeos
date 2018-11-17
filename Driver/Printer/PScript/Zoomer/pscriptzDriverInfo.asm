COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		PostScript printer driver
FILE:		pscriptzDriverInfo.asm

AUTHOR:		Jim DeFrisco, 15 May 1990

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	5/15/90		Initial revision

DESCRIPTION:
	Driver info for the PostScript printer driver

	The file "printerDriver.def" should be included before this one
		

	$Id: pscriptzDriverInfo.asm,v 1.1 97/04/18 11:55:48 newdeal Exp $

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


DefPrinter PD_ALW, "Apple LaserWriter", appleLWf13Info
DefPrinter PD_APPLELW2NT, "Apple LaserWriter II NT", appleLW2NTf35Info
DefPrinter PD_GENERIC_PS, "PostScript Compatible", generf35Info
DefPrinter PD_HPLJ4, "HP LaserJet 4 (PostScript)", hpLJ4psInfo
DefPrinter PD_IBM401917, "IBM 4019 (17 Font PostScript)", ibm4019f17Info
DefPrinter PD_IBM401939, "IBM 4019 (39 Font PostScript)", ibm4019f39Info
DefPrinter PD_NECCMPS40, "NEC Colormate PS/40", necColor40f17Info
DefPrinter PD_OKI830, "Oki OL830/PS", generf13Info
DefPrinter PD_TANDY_LP410_PS, "Tandy LP 410 (PostScript)", generf13Info
DefPrinter PD_TANDY_LP800_PS, "Tandy LP 800 (PostScript)", generf13Info


;----------------------------------------------------------------------------
; 	Driver Info Header
;----------------------------------------------------------------------------

		DriverExtendedInfoTable < 
					   {},			; lmem header
					   PrintDevice/2,	; #devices
					   offset deviceStrings, ; devices
					   offset deviceInfoTab	; info blocks
					 >

PrintDriverInfo				 < 90,			; timeout (sec)
					   PR_DONT_RESEND,
                                           isoShme,	        ;ISO sub tab.
                                           asciiTransTable,
                                           PDT_PRINTER,
                                           FALSE
					>


;----------------------------------------------------------------------------
;	Device String Table and Strings
;----------------------------------------------------------------------------


		; Dave says I should have this here
isoShme		chunk.word	0ffffh

		; ASCII Translation list for Foreign Language Versions
asciiTransTable	chunk.char ";;", 0

;Create the actual tables here....
PrinterTables


DriverInfo	ends
