COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		toshiba 24-pin printer driver
FILE:		toshiba24DriverInfo.asm

AUTHOR:		Dave Durran, 26 Mar 1990

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/27/90		Initial revision
	Dave	5/92		Initial 2.0 version

DESCRIPTION:
	Driver info for the toshiba 24-pin printer driver

	The file "printerDriver.def" should be included before this one
		

	$Id: toshiba24DriverInfo.asm,v 1.1 97/04/18 11:53:34 newdeal Exp $

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

DefPrinter PD_CITIZEN_T124, "Citizen Tribute 124", p321Info
DefPrinter PD_CITIZEN_T224, "Citizen Tribute 224", p351Info
DefPrinter PD_TOSHIBA_P321, "Toshiba P321", p321Info
DefPrinter PD_TOSHIBA_P341SL_T, "Toshiba P341SL", p351Info
DefPrinter PD_TOSHIBA_P351, "Toshiba P351", p351Info
DefPrinter PD_TOSHIBA_P351SX_T, "Toshiba P351SX (Tosh/Qume Mode)", p351Info

;----------------------------------------------------------------------------
;	Driver Info Header
;----------------------------------------------------------------------------

DriverExtendedInfoTable			 < {},		; lmem hdr
					   PrintDevice/2,	; # devices
					   offset deviceStrings, ; devices
					   offset deviceInfoTab	; info blocks
					   >

PrintDriverInfo				< 45,			; timeout (sec)
					   PR_RESEND,		; resend after
                                           isoSubstitutions,    ;ISO sub tab.
                                           asciiTransTable,
                                           PDT_PRINTER,
                                           TRUE
					>


;----------------------------------------------------------------------------
;	Device String Table and Strings
;----------------------------------------------------------------------------

        ;ISO Substitutions for this printer.
        ;France,Germany,UK,Denmark1,Sweden,Italy,Spain1,Japan,Norway
isoSubstitutions        chunk.word \
                2323h,2424h,4088h,5ba1h,5c8dh,5da4h,5e5eh,6060h,\
                7b8eh,7c9dh,7d8fh,7each,0000h,0000h,0000h,0000h,\
                2323h,2424h,40a4h,5b80h,5c85h,5d86h,5e5eh,6060h,\
                7b8ah,7c9ah,7d9fh,7ea7h,0000h,0000h,0000h,0000h,\
                23a3h,0000h,0000h,0000h,0000h,0000h,0000h,0000h,\
                0000h,0000h,0000h,0000h,0000h,0000h,0000h,0000h,\
                0000h,0000h,0000h,0000h,0000h,0000h,0000h,0000h,\
                0000h,0000h,0000h,0000h,0000h,0000h,0000h,0000h,\
                2323h,24dbh,4083h,5b80h,5c85h,5d81h,5e86h,608eh,\
                7b8ah,7c9ah,7d8ch,7e9fh,0000h,0000h,0000h,0000h,\
                0000h,0000h,0000h,0000h,0000h,0000h,0000h,0000h,\
                0000h,0000h,0000h,0000h,0000h,0000h,0000h,0000h,\
                2320h,2424h,4040h,5bc1h,5c84h,5dc2h,5e5eh,6060h,\
                7bach,7c96h,0000h,0000h,0000h,0000h,0000h,0000h,\
                0000h,0000h,0000h,0000h,0000h,0000h,0000h,0000h,\
                0000h,0000h,0000h,0000h,0000h,0000h,0000h,0000h,\
                2323h,24dbh,4083h,5baeh,5cafh,5d81h,5e86h,608eh,\
                7bbeh,7cbfh,7d8ch,7e9fh,0000h,0000h,0000h,0000h


        ; ASCII Translation List for Foreign Language Versions
asciiTransTable         chunk.char ";;",0


;Create the actual tables here.....
PrinterTables

DriverInfo	ends
