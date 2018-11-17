COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Impex- Tif Graphics Translation Library
FILE:		exportManager.asm

AUTHOR:		maryann Simmons	2/92

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jimmy	1/92		Initial revision
	maryann	2/92		copied for Tif

DESCRIPTION:
	This is the main include file for the export module of the 
	tif translation library
		

	$Id: exportManager.asm,v 1.1 97/04/07 11:27:26 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;	Common Geode stuff
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

include	tifGeode.def			; this includes the .def files

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;	Code
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

include	exportCommon.asm		; Graphics common export code
include	exportMain.asm			; primary interface routines
include	cpt.asm				; ccitt compression code














