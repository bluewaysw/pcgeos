COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		dosVariable.asm

AUTHOR:		Gene Anderson, Jan  8, 1991

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	1/ 8/91		Initial revision

DESCRIPTION:
	

	$Id: dosVariable.asm,v 1.1 97/04/05 01:16:33 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata	segment

if not DBCS_PCGEOS
;
; DOS's idea of the current code page and its handle
;
currentCodePage	DosCodePage CODE_PAGE_US
currentCodePageHandle	hptr USMap
endif

idata	ends
