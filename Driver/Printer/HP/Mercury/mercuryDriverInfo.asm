COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Deskjet KCMY printer driver
FILE:		mercuryDriverInfo.asm

AUTHOR:		Dave Durran, 27 Feb 1990

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	2/27/90		Initial revision
	Dave	6/22/92		Initial 2.0 revision

DESCRIPTION:
	Driver info for the deskJet printer driver

	The file "printerDriver.def" should be included before this one
		

	$Id: mercuryDriverInfo.asm,v 1.1 97/09/10 14:03:22 newdeal Exp $

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
DefPrinter	PD_DESKJET_4C, "HP DeskJet 4-Color Compatible", mercuryInfo
else
;
; Default printer driver list (all known supported devices)
;
; The following models need to be officially tested:
;   HP670C HP672C HP692C HP810C HP895C HP895CSE HP895CXI
;   HP970CXI HP1120C HP1120CSE HP1220C HP1220CSE
;
;
DefPrinter	PD_DESKJET_550_4C, "HP DeskJet 550C (4 Color)", mercuryInfo
DefPrinter	PD_DESKJET_560_4C, "HP DeskJet 560C (4 Color)", mercuryInfo
DefPrinter	PD_DESKJET_660_4C, "HP DeskJet 660C (4 Color)", mercuryInfo
DefPrinter	PD_DESKJET_670_4C, "HP DeskJet 670C (4 Color)", mercuryInfo
DefPrinter	PD_DESKJET_672_4C, "HP DeskJet 672C (4 Color)", mercuryInfo
DefPrinter	PD_DESKJET_680_4C, "HP DeskJet 680C (4 Color)", mercuryInfo
DefPrinter	PD_DESKJET_682_4C, "HP DeskJet 682C (4 Color)", mercuryInfo
DefPrinter	PD_DESKJET_692_4C, "HP DeskJet 692C (4 Color)", mercuryInfo
DefPrinter	PD_DESKJET_810_4C, "HP DeskJet 810C (4 Color)", mercuryInfo
DefPrinter	PD_DESKJET_850_4C, "HP DeskJet 850C (4 Color)", mercuryInfo
DefPrinter	PD_DESKJET_895_4C, "HP DeskJet 895C (4 Color)", mercuryInfo
DefPrinter	PD_DESKJET_895_4CSE, "HP DeskJet 895Cse (4 Color)", mercuryInfo
DefPrinter	PD_DESKJET_895_4CXI, "HP DeskJet 895Cxi (4 Color)", mercuryInfo
DefPrinter	PD_DESKJET_970_4CXI, "HP DeskJet 970Cxi (4 Color)", mercuryInfo
DefPrinter	PD_DESKJET_1120_4C, "HP DeskJet 1120C (4 Color)", mercuryInfo
DefPrinter	PD_DESKJET_1120_4CSE, "HP DeskJet 1120Cse (4 Color)", mercuryInfo
DefPrinter	PD_DESKJET_1220_4C, "HP DeskJet 1220C (4 Color)", mercuryInfo
DefPrinter	PD_DESKJET_1220_4CSE, "HP DeskJet 1220Cse (4 Color)", mercuryInfo
DefPrinter	PD_DESKJET_1600_4C, "HP DeskJet 1600C (4 Color)", mercuryInfo
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
					  asciiTransTable
					>


;----------------------------------------------------------------------------
;	Device String Table and Strings
;----------------------------------------------------------------------------



        ; ASCII Translation List for Foreign Language Versions
asciiTransTable         chunk.char ";;",0

;create the tables...
PrinterTables

DriverInfo	ends
