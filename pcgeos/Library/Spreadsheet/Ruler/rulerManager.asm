COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		rulerManager.asm
FILE:		rulerManager.asm

AUTHOR:		Gene Anderson, Sep 23, 1991

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	9/23/91		Initial revision

DESCRIPTION:
	Manager file for SpreadsheetRuler classes

	$Id: rulerManager.asm,v 1.1 97/04/07 11:13:12 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	spreadsheetGeode.def

;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------

SpreadsheetClassStructures	segment	resource
	SpreadsheetRulerClass		;declare the class record
SpreadsheetClassStructures	ends

;------------------------------------------------------------------------------
;			Code
;------------------------------------------------------------------------------

include rulerConstant.def

include rulerHoriz.asm
include rulerVert.asm
include rulerCommon.asm
include rulerMouse.asm
