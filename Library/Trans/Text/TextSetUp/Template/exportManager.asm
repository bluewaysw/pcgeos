COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	Impex
MODULE:		Template Translation Library
FILE:		exportManager.asm

AUTHOR: 	Jenny Greenwood, 2 September 1992

REVISION HISTORY:

	Name	Date		Description
	----	----		-----------
	jenny	9/2/92		Initial version

DESCRIPTION:

	This is the main include file for the export module of the 
	Template translation library

	$Id: exportManager.asm,v 1.1 97/04/07 11:40:25 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;	Common Geode stuff
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

include	templateGeode.def		; this includes the .def files

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;	Code
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

include	textCommonExport.asm		; common text export routine
include	exportMain.asm			; primary interface routines
