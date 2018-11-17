COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Deskjet printer driver
FILE:		deskjetDriverInfo.asm

AUTHOR:		Dave Durran, 27 Feb 1990

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	2/27/90		Initial revision
	Dave	6/22/92		Initial 2.0 revision

DESCRIPTION:
	Driver info for the deskJet printer driver

	The file "printerDriver.def" should be included before this one
		

	$Id: deskjetDriverInfo.asm,v 1.1 97/09/10 14:02:23 newdeal Exp $

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
DefPrinter	PD_HP_EARLY_DESKJET, "HP DeskJet B/W Compatible", deskjetdjInfo
else
;
; Default printer driver list (all known supported devices)
;
; The following models need to be officially tested:
;   HP670C HP672C HP692C HP810C HP895C HP895CSE HP895CXI
;   HP970CXI HP1120C HP1120CSE HP1220C HP1220CSE
;
;
DefPrinter	PD_HP_DESKJET, "HP DeskJet", deskjetdjInfo
DefPrinter	PD_HP_DESKJET_PLUS, "HP DeskJet PLUS", deskjetdjInfo
DefPrinter	PD_HP_DESKJET_320, "HP DeskJet 320", deskjetdjInfo
DefPrinter	PD_HP_DESKJET_340, "HP DeskJet 340", deskjetdjInfo
DefPrinter	PD_HP_DESKJET_400, "HP DeskJet 400", deskjetdjInfo
DefPrinter	PD_HP_DESKJET_500, "HP DeskJet 500", deskjetdjInfo
DefPrinter	PD_HP_DESKJET_500C_MONO, "HP DeskJet 500C (B/W)", deskjetdjInfo
DefPrinter	PD_HP_DESKJET_540C_MONO, "HP DeskJet 540C (B/W)", deskjetdjInfo
DefPrinter	PD_HP_DESKJET_550C_MONO, "HP DeskJet 550C (B/W)", deskjetdjInfo
DefPrinter	PD_HP_DESKJET_560C_MONO, "HP DeskJet 560C (B/W)", deskjetdjInfo
DefPrinter	PD_HP_DESKJET_600, "HP DeskJet 600", deskjetdjInfo
DefPrinter	PD_HP_DESKJET_660C_MONO, "HP DeskJet 660C (B/W)", deskjetdjInfo
DefPrinter	PD_HP_DESKJET_670C_MONO, "HP DeskJet 670C (B/W)", deskjetdjInfo
DefPrinter	PD_HP_DESKJET_672C_MONO, "HP DeskJet 672C (B/W)", deskjetdjInfo
DefPrinter	PD_HP_DESKJET_680C_MONO, "HP DeskJet 680C (B/W)", deskjetdjInfo
DefPrinter	PD_HP_DESKJET_682C_MONO, "HP DeskJet 682C (B/W)", deskjetdjInfo
DefPrinter	PD_HP_DESKJET_692C_MONO, "HP DeskJet 692C (B/W)", deskjetdjInfo
DefPrinter	PD_HP_DESKJET_810C_MONO, "HP DeskJet 810C (B/W)", deskjetdjInfo
DefPrinter	PD_HP_DESKJET_850C_MONO, "HP DeskJet 850C (B/W)", deskjetdjInfo
DefPrinter	PD_HP_DESKJET_895C_MONO, "HP DeskJet 895C (B/W)", deskjetdjInfo
DefPrinter	PD_HP_DESKJET_895CSE_MONO, "HP DeskJet 895Cse (B/W)", deskjetdjInfo
DefPrinter	PD_HP_DESKJET_895CXI_MONO, "HP DeskJet 895Cxi (B/W)", deskjetdjInfo
DefPrinter	PD_HP_DESKJET_970CXI_MONO, "HP DeskJet 970Cxi (B/W)", deskjetdjInfo
DefPrinter	PD_HP_DESKJET_1120C_MONO, "HP DeskJet 1120C (B/W)", deskjetdjInfo
DefPrinter	PD_HP_DESKJET_1120CSE_MONO, "HP DeskJet 1120Cse (B/W)", deskjetdjInfo
DefPrinter	PD_HP_DESKJET_1220C_MONO, "HP DeskJet 1220C (B/W)", deskjetdjInfo
DefPrinter	PD_HP_DESKJET_1220CSE_MONO, "HP DeskJet 1220Cse (B/W)", deskjetdjInfo
DefPrinter	PD_HP_DESKJET_1600C_MONO, "HP DeskJet 1600C (B/W)", deskjetdjInfo
DefPrinter	PD_HP_DESKJET_PORT, "HP DeskJet Portable", deskjetdjInfo
DefPrinter	PD_OLIVETTI_JP150, "Olivetti JP 150", deskjetdjInfo
DefPrinter	PD_OLIVETTI_JP350, "Olivetti JP 350", deskjetdjInfo
endif

;----------------------------------------------------------------------------
;	Driver Info Header
;----------------------------------------------------------------------------

DriverExtendedInfoTable			 <
					{},			; lmem hdr
					PrintDevice/2,		; # devices
					offset deviceStrings, 	; devices
					offset deviceInfoTab 	; info blocks
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

isoSubstitutions        chunk.word  0ffffh	;no ISO subs.


        ; ASCII Translation List for Foreign Language Versions
asciiTransTable         chunk.char ";;",0

;create the tables...
PrinterTables

DriverInfo	ends
