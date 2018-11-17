COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Deskjet CMY printer driver
FILE:		dj500cDriverInfo.asm

AUTHOR:		Dave Durran, 27 Feb 1990

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	2/27/90		Initial revision
	Dave	6/22/92		Initial 2.0 revision

DESCRIPTION:
	Driver info for the deskJet printer driver

	The file "printerDriver.def" should be included before this one
		

	$Id: dj500cDriverInfo.asm,v 1.1 97/09/10 14:02:57 newdeal Exp $

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
DefPrinter	PD_EARLY_DESKJET_3C, "HP DeskJet 3-Color Compatible", dj500cInfo
else
;
; Default printer driver list (all known supported devices)
;
; The following models need to be officially tested:
;   HP670C HP672C HP692C HP810C HP895C HP895CSE HP895CXI
;   HP970CXI HP1120C HP1120CSE HP1220C HP1220CSE
;
;
DefPrinter	PD_DESKJET_500_C, "HP DeskJet 500C (Color)", dj500cInfo
DefPrinter	PD_DESKJET_540_C, "HP DeskJet 540C (Color)", dj500cInfo
DefPrinter	PD_DESKJET_550_3C, "HP DeskJet 550C (3 Color)", dj500cInfo
DefPrinter	PD_DESKJET_560_3C, "HP DeskJet 560C (3 Color)", dj500cInfo
DefPrinter	PD_DESKJET_600_C, "HP DeskJet 600C (Color)", dj500cInfo
DefPrinter	PD_DESKJET_660_3C, "HP DeskJet 660C (3 Color)", dj500cInfo
DefPrinter	PD_DESKJET_670_3C, "HP DeskJet 670C (3 Color)", dj500cInfo
DefPrinter	PD_DESKJET_672_3C, "HP DeskJet 672C (3 Color)", dj500cInfo
DefPrinter	PD_DESKJET_680_3C, "HP DeskJet 680C (3 Color)", dj500cInfo
DefPrinter	PD_DESKJET_682_3C, "HP DeskJet 682C (3 Color)", dj500cInfo
DefPrinter	PD_DESKJET_692_3C, "HP DeskJet 692C (3 Color)", dj500cInfo
DefPrinter	PD_DESKJET_810_3C, "HP DeskJet 810C (3 Color)", dj500cInfo
DefPrinter	PD_DESKJET_850_3C, "HP DeskJet 850C (3 Color)", dj500cInfo
DefPrinter	PD_DESKJET_895_3C, "HP DeskJet 895C (3 Color)", dj500cInfo
DefPrinter	PD_DESKJET_895_3CSE, "HP DeskJet 895Cse (3 Color)", dj500cInfo
DefPrinter	PD_DESKJET_895_3CXI, "HP DeskJet 895Cxi (3 Color)", dj500cInfo
DefPrinter	PD_DESKJET_970_3CXI, "HP DeskJet 970Cxi (3 Color)", dj500cInfo
DefPrinter	PD_DESKJET_1120_3C, "HP DeskJet 1120C (3 Color)", dj500cInfo
DefPrinter	PD_DESKJET_1120_3CSE, "HP DeskJet 1120Cse (3 Color)", dj500cInfo
DefPrinter	PD_DESKJET_1220_3C, "HP DeskJet 1220C (3 Color)", dj500cInfo
DefPrinter	PD_DESKJET_1220_3CSE, "HP DeskJet 1220Cse (3 Color)", dj500cInfo
DefPrinter	PD_DESKJET_1600_3C, "HP DeskJet 1600C (3 Color)", dj500cInfo
DefPrinter	PD_DESKJET_CMY_NCC, "HP DeskJet CMY Non Col-Corr", nccCMYInfo
DefPrinter	PD_HP_PJ_XL300_3C, "HP PaintJet XL300 (3 Color)", pjxl300Info
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
