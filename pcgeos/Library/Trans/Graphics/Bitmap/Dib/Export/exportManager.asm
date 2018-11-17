COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Impex- DIB Graphics Translation Library
FILE:		exportManager.asm

AUTHOR:		maryann Simmons	2/92

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------

DESCRIPTION:
	This is the main include file for the export module of the 
	DIB translation library
		

	$Id: exportManager.asm,v 1.1 97/04/07 11:29:09 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ExportCode	segment	Resource

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;	Common Geode stuff
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

include	dibGeode.def			; this includes the .def files
include	thread.def			; for getting thread handle
UseDriver Internal/videoDr.def		; for EditableBitmap struct

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;	Code
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

include	exportMain.asm			; primary interface routines
include exportDIB.asm

ExportCode	ends













