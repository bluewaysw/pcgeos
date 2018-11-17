
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		PostScript Translation Library
FILE:		exportManager.asm

AUTHOR:		Jim DeFrisco, 12 Feb 1991

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	2/91		Initial revision


DESCRIPTION:
	This is the main include file for the export module of the 
	PostScript translation library
		

	$Id: exportManager.asm,v 1.1 97/04/07 11:25:38 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;	Common Geode stuff
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

; This enables code in fontID.def to create a table in a resource called
; FontMapping.  See fontID.def for more details.
FID_MAPPING_CODE	= 1

ACCESS_GSTATE	=	1
include	epsGeode.def			; this includes the .def files

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;	Constants/Variables
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

include	exportConstant.def
include	exportMacro.def

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;	Code
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

include	exportMain.asm			; primary interface routines
include	exportGString.asm		; guts of the translation
include	exportText.asm			; guts of the translation, part 2
include	exportBitmap.asm		; guts of the translation, part 3
include	exportArc.asm			; guts of the translation, part 4
include	exportPath.asm			; path support
include	exportUtils.asm			; misc support routines
include	exportTables.asm		; tables of info
include	exportHeader.asm		; tables of info

include	exportFontMap.asm		; -> PostScript font xlation code
include	exportFontTables.asm		; -> PostScript font xlation tables
include	exportMoreFonts.asm		; -> PostScript font xlation tables

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;	PostScript Snippets
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

include	exportProlog.asm		; PCGEOS prolog
include	exportType3Fonts.asm		; more postscript stuff
include	exportComments.asm		; Document Structuring Conventions
include	exportPSCode.asm		; emitted code snippets
