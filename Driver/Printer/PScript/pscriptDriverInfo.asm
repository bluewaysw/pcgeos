COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		PostScript printer driver
FILE:		pscriptDriverInfo.asm

AUTHOR:		Jim DeFrisco, 15 May 1990

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	5/15/90		Initial revision
   Falk	2015			Added the new Host Integration (PS2PDF) printer to the list

DESCRIPTION:
	Driver info for the PostScript printer driver

	The file "printerDriver.def" should be included before this one
		

	$Id: pscriptDriverInfo.asm,v 1.1 97/04/18 11:55:56 newdeal Exp $

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
DefPrinter PD_HPLJ_PS, "HP LaserJet with PostScript", hpLJ4psInfo
DefPrinter PD_HPLJCOLOR_PS, "HP LaserJet with PostScript (Color)", hpLJColorf35Info
DefPrinter PD_GENERIC_PS, "PostScript Compatible", generf35Info
else
;
; Default printer driver list (all known supported devices)
;
DefPrinter PD_ALJ2, "Adobe LaserJet II Cartridge (PostScript)", adobeLJ2f35Info
DefPrinter PD_ALJ2C1, "Adobe LJ II Cart w/Type Cart 1 (PostScript)", adobeLJ2fTC1Info
DefPrinter PD_ALJ2C2, "Adobe LJ II Cart w/Type Cart 2 (PostScript)", adobeLJ2fTC2Info
DefPrinter PD_AGFA9400, "Agfa-Compugraphic 9400P (PostScript) v49.3", generf13Info
DefPrinter PD_AGFACHROMA, "Agfa Matrix ChromaScript (PostScript)", necColor40f17Info
DefPrinter PD_ALW, "Apple LaserWriter v23.0 (PostScript)", appleLWf13Info
DefPrinter PD_ALWP38, "Apple LaserWriter Plus v38.0 (PostScript)", appleLW2NTf35Info
DefPrinter PD_ALWP42, "Apple LaserWriter Plus v42.2 (PostScript)", appleLW2NTf35Info
DefPrinter PD_APPLELW2NT, "Apple LaserWriter II NT (PostScript) v47.0", appleLW2NTf35Info
DefPrinter PD_APPLELW2NTX, "Apple LaserWriter II NTX (PostScript) v47.0", appleLW2NTf35Info
DefPrinter PD_ALWPNT, "Apple LaserWriter Personal NT (PostScript)", appleLW2NTf35Info
DefPrinter PD_ALWP2NT, "Apple LaserWriter Personal II NT (PostScript) v51.8", appleLW2NTf35Info
DefPrinter PD_APS6108, "APS-PS PIP with APS-6/108 (PostScript)", generf13Info
DefPrinter PD_LZR1200, "APS-PS PIP with LZR 1200 (PostScript)", generf13Info
DefPrinter PD_LZR2600, "APS-PS PIP with LZR 2600 (PostScript)", generf13Info
DefPrinter PD_APS680, "APS-PS PIP with APS-6/80 (PostScript)", generf13Info
DefPrinter PD_ASTTL, "AST TurboLaser/PS (PostScript) v47.0", generf35Info
DefPrinter PD_CANON1260, "Canon LBP-1260 (PostScript)", generf13Info
DefPrinter PD_CANON3R, "Canon LBP-8 Mark IIIR (PostScript)", generf13Info
DefPrinter PD_CANON3T, "Canon LBP-8 Mark IIIT (PostScript)", generf13Info
DefPrinter PD_CANON3, "Canon LBP-8 Mark III (PostScript)", generf13Info
DefPrinter PD_CANONCARD, "Canon LBP-8IIIR ScriptCard PS-1 (PostScript)", generf35Info
DefPrinter PD_CANONCARD2, "Canon LBP-4 ScriptCard PS-2 (PostScript)", generf35Info
DefPrinter PD_CANONIPU, "Canon PS-IPU Color Laser Copier (PostScript)", necColorf35Info
DefPrinter PD_DATA2665, "Dataproducts LZR-2665 (PostScript) v47.0", generf13Info
DefPrinter PD_DATA1260, "Dataproducts LZR 1260 (PostScript) v47.0", generf35Info
DefPrinter PD_EPSON7500, "Epson EPL-7500 (PostScript)", generf35Info
DefPrinter PD_FUJ7100, "Fujitsu RX7100PS (PostScript)", generf35Info
DefPrinter PD_GENERIC_PS, "PostScript Compatible", generf35Info
DefPrinter PD_HPLJ2D, "HP PostScript Cartridge for LaserJet IID v52.2", generf35Info
DefPrinter PD_HPLJ3, "HP PostScript Cartridge for LaserJet III v52.2", generf35Info
DefPrinter PD_HPLJ3D, "HP PostScript Cartridge for LaserJet IIID v52.2", generf35Info
DefPrinter PD_HPLJ2P, "HP PostScript Cartridge for LaserJet IIP v52.2", generf35Info
DefPrinter PD_HPLJ4, "HP LaserJet 4 (PostScript)", hpLJ4psInfo
DefPrinter PD_HPLJ5, "HP LaserJet 5 (PostScript)", hpLJ4psInfo
DefPrinter PD_HPLJCOLOR, "HP Color LaserJet (PostScript)", hpLJColorf35Info
DefPrinter PD_IBM401917, "IBM 4019 (17 Fonts) (PostScript) v52.1", ibm4019f17Info
DefPrinter PD_IBM401939, "IBM 4019 (39 Fonts) (PostScript) v52.1", ibm4019f39Info
DefPrinter PD_IBM402917, "IBM 4029 (17 Fonts) (PostScript) v52.3", ibm4019f17Info
DefPrinter PD_IBM402939, "IBM 4029 (39 Fonts) (PostScript) v52.3", ibm4019f39Info
DefPrinter PD_IBM4039_PS, "IBM 4039 LaserPrinter (PostScript)", generf35Info
DefPrinter PD_IBM407935, "IBM Color Jetprinter PS 4079 (PostScript)", ibm4079f35Info
DefPrinter PD_IBM421620, "IBM 4216-020 (PostScript) v47.0", ibm4216f43Info
DefPrinter PD_IBM421630, "IBM 4216-030 (PostScript) v50.5", ibm4216f43Info
DefPrinter PD_KY_Q8010, "Kyocera Q-8010 (PS Compat)", appleLW2NTf35Info
DefPrinter PD_LEXMARK403917, "Lexmark 4039 (17 Fonts) (PostScript)", ibm4019f17Info
DefPrinter PD_LEXMARK403939, "Lexmark 4039 (39 Fonts) (PostScript)", ibm4019f39Info
DefPrinter PD_LINO100, "Linotronic 100 (PostScript) v42.5", generf13Info
DefPrinter PD_LINO200, "Linotronic 200 (PostScript) v47.1", generf13Info
DefPrinter PD_LINO249, "Linotronic 200 (PostScript) v49.3", generf13Info
DefPrinter PD_LINO300, "Linotronic 300 (PostScript) v47.1", generf13Info
DefPrinter PD_LINO349, "Linotronic 300 (PostScript) v49.3", generf13Info
DefPrinter PD_LINO500, "Linotronic 500 (PostScript) v49.3", generf13Info
DefPrinter PD_MONOIS, "Monotype Imagesetter (PostScript) v52.2", generf13Info
DefPrinter PD_NECLS290, "NEC Silentwriter2 Model 90 (PostScript) v52.2", generf35Info
DefPrinter PD_NECLS2290, "NEC Silentwriter2 290 (PostScript) v52.0", generf35Info
DefPrinter PD_NECLC890XL, "NEC Silentwriter LC 890XL (PostScript) v50.5", generf35Info
DefPrinter PD_NECLC890, "NEC Silentwriter LC 890 (PostScript) v47.0", generf35Info
DefPrinter PD_NECCMPS, "NEC Colormate PS (PostScript) v51.9", necColorf35Info
DefPrinter PD_NECCMPS40, "NEC Colormate PS/40 (PostScript) v51.9", necColor40f17Info
DefPrinter PD_NECCMPS80, "NEC Colormate PS/80 (PostScript) v51.9", necColorf35Info
DefPrinter PD_NEWGEN480, "NewGen TurboPS/480 (PS Compat)", generf35Info
DefPrinter PD_NEWGEN400, "NewGen TurboPS/400 (PS Compat)", generf35Info
DefPrinter PD_NEWGEN360, "NewGen TurboPS/360 (PS Compat)", generf35Info
DefPrinter PD_NEWGEN300, "NewGen TurboPS/300 (PS Compat)", generf35Info
DefPrinter PD_OCEPS, "OceColor PostScript Printer", necColorf35Info
DefPrinter PD_OCEPS2, "OceColor G5242 PostScript Printer", necColorf35Info
DefPrinter PD_OKI840, "Oki OL840/PS (PostScript) v51.8", generf35Info
DefPrinter PD_OKI830, "Oki OL830/PS (PostScript) v51.8", generf13Info
DefPrinter PD_PACPAGE, "PacificPage PE LaserJet Cartridge (PS Compat)", generf35Info
DefPrinter PD_PAN4455, "Panasonic KX-P4455 (PostScript)", generf39cartInfo
DefPrinter PD_QMS2200, "QMS-PS 2200 (PostScript) v51.0", generf39cartInfo
DefPrinter PD_QMS2210, "QMS-PS 2210 (PostScript) v51.0", generf39cartInfo
DefPrinter PD_QMS2220, "QMS-PS 2220 (PostScript) v51.0", generf39cartInfo
DefPrinter PD_QMS810T, "QMS-PS 810 Turbo (PostScript) v51.7", generf39cartInfo
DefPrinter PD_QMS820T, "QMS-PS 820 Turbo (PostScript) v51.7", generf39cartInfo
DefPrinter PD_QMS820, "QMS-PS 820 (PostScript) v51.7", generf39cartInfo
DefPrinter PD_QMSCS110, "QMS ColorScript 100 Model 10 (PostScript)", generCf35Info
DefPrinter PD_QMSCS120, "QMS ColorScript 100 Model 20/30 (PostScript)", generCf35Info
DefPrinter PD_QMS810, "QMS-PS 810 (PostScript) v47.0", generf35Info
DefPrinter PD_QMS800P, "QMS-PS 800 Plus (PostScript) v46.1", generf35Info
DefPrinter PD_QMS800, "QMS-PS 800 (PostScript) v46.1", generf13Info
DefPrinter PD_QMSCS100, "QMS ColorScript 100 (PostScript) v49.3", qmsColorScriptf35Info
DefPrinter PD_QMSJETP, "QMS PS Jet Plus (PostScript) v46.1", generf35Info
DefPrinter PD_QMSJET, "QMS PS Jet (PostScript) v46.1", generf13Info
DefPrinter PD_QMSPS410, "QMS-PS 410 (PostScript)", qmsPS410f43Info
DefPrinter PD_QUMES10, "Qume ScripTEN (PostScript) v47.0", generf35Info
DefPrinter PD_RICOHPCL, "Ricoh PC Laser 6000/PS (PostScript) v50.5", generCf35Info
DefPrinter PD_SCLUM5232, "Schlumberger 5232 Color PostScript Printer", qmsColorScriptf35Info
DefPrinter PD_SCAN2030, "Scantext 2030/51 (PostScript)", generf13Info
DefPrinter PD_TANDY_LP410_PS, "Tandy LP 410 (PostScript)", generf13Info
DefPrinter PD_TANDY_LP800_PS, "Tandy LP 800 (PostScript)", generf13Info
DefPrinter PD_TI211513, "TI 2115 (13 fonts) (PostScript) v47.0", generf13Info
DefPrinter PD_TI211535, "TI 2115 (35 fonts) (PostScript) v47.0", generCf35Info
DefPrinter PD_TIOMNI, "TI OmniLaser 2108 (PostScript) v45.0", generf13Info
DefPrinter PD_TIML17, "TI microLaser PS17 (PostScript) v52.1", generf17Info
DefPrinter PD_TIMLXL17, "TI microLaser XL PS17 (PostScript) v52.1", generf17Info
DefPrinter PD_TIML35, "TI microLaser PS35 (PostScript) v52.1", generf35Info
DefPrinter PD_TIMLXL35, "TI microLaser XL PS35 (PostScript) v52.1", generf35Info
DefPrinter PD_UNI9415, "Unisys AP9415 (PostScript) v47.0", generCf35Info
DefPrinter PD_VAR4000, "Varityper Series 4000/5330 (PostScript)", generf13Info
DefPrinter PD_VAR4200, "Varityper 4200B-P (PostScript)", generf13Info
DefPrinter PD_VAR4300, "Varityper 4300P (PostScript)", generf13Info
DefPrinter PD_VAR5300, "Varityper Series 4000/5300 (PostScript)", generf13Info
DefPrinter PD_VAR5500, "Varityper Series 4000/5500 (PostScript) v52.2", generf13Info
DefPrinter PD_VAR600P, "Varityper VT-600P (PostScript) v48.0", generf13Info
DefPrinter PD_SOFTRIP, "GhostScript Software RIP B/W (PostScript)", softRIPInfo
DefPrinter PD_SOFTRIPC, "GhostScript Software RIP color (PostScript)", softRIPCInfo
DefPrinter PD_HOSTPRINTER, "Host Integration Printer", hostPrinterInfo
endif

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
					   PR_RESEND,
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
