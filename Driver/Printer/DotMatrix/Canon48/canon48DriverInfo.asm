COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Canon BJ-130 48-jet printer driver
FILE:		canon48DriverInfo.asm

AUTHOR:		Dave Durran, 26 Mar 1990

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/27/90		Initial revision
	Dave	5/92		Initial 2.0 version

DESCRIPTION:
	Driver info for the Canon 48-pin printer driver

	The file "printerDriver.def" should be included before this one
		

	$Id: canon48DriverInfo.asm,v 1.1 97/04/18 11:54:05 newdeal Exp $

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
DefPrinter PD_CANON_BJ10E_M2,  "Canon BJ-10 series", bj10eInfo
DefPrinter PD_CANON_BJ200_BJM, "Canon BJ-200 series", bj10eInfo
DefPrinter PD_CANON_BJ300_M1,  "Canon BJ-300 series", generInfo
else
;
; Default printer driver list (all known supported devices)
;
DefPrinter PD_CANON_BJ10E_M2, "Canon BJ-10e (Mode 2)", bj10eInfo
DefPrinter PD_CANON_BJ10EX_M2, "Canon BJ-10ex (Mode 2)", bj10eInfo
DefPrinter PD_CANON_BJ30_BJM, "Canon BJ-30 (Standard Mode)", bj10eInfo
DefPrinter PD_CANON_BJ130E, "Canon BJ-130e", generwInfo
DefPrinter PD_CANON_BJ200_BJM, "Canon BJ-200 (BJ Mode)", bj10eInfo
DefPrinter PD_CANON_BJ230_BJM, "Canon BJ-230 (Standard Mode)", bj10eInfo
DefPrinter PD_CANON_BJ300_M1, "Canon BJ-300 (Mode 1)", generInfo
DefPrinter PD_CANON_BJ330_M1, "Canon BJ-330 (Mode 1)", generwInfo
DefPrinter PD_IBM_4070_I, "IBM 4070 IJ (IBM Mode)", bj10eInfo
DefPrinter PD_IBM_4072, "IBM ExecJet 4072", execjetInfo
DefPrinter PD_TANDY_JP250_C, "Tandy JP 250 (Canon Mode)", bj10eInfo
endif

;----------------------------------------------------------------------------
;	Driver Info Header
;----------------------------------------------------------------------------

DriverExtendedInfoTable			 < {},		; lmem hdr
					   PrintDevice/2,	; # devices
					   offset deviceStrings, ; devices
					   offset deviceInfoTab	; info blocks
					   >

PrintDriverInfo				 < 30,			; timeout (sec)
					   PR_DONT_RESEND,	;
                                           isoSubstitutions,    ;ISO sub tab.
                                           asciiTransTable,
                                           PDT_PRINTER,
					   TRUE
					>


;----------------------------------------------------------------------------
;	Device String Table and Strings
;----------------------------------------------------------------------------
isoSubstitutions        chunk.word 0ffffh	;no ISO subs.


        ; ASCII Translation List for Foreign Language Versions
asciiTransTable         chunk.char ";;",0


;create the actual tables....
PrinterTables


DriverInfo	ends
