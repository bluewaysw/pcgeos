
COMMENT @-----------------------------------------------------------------------

	Copyright (c) Geoworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		

AUTHOR:		Cheng, 1/91

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial revision

DESCRIPTION:
		
	$Id: exportManager.asm,v 1.1 97/04/07 11:41:52 newdeal Exp $

-------------------------------------------------------------------------------@

_Export = 1

include lotus123Geode.def
include lotus123Constant.def
include lotus123Macro.def

ifndef DO_PIZZA
include exportHeader.asm
endif

ExportCode	segment	resource
	global	TransExport:far

	include	export.asm
ifndef DO_PIZZA
	include	exportExport.asm
	include exportUtils.asm
	include exportInfixToPostfix.asm
endif
ExportCode	ends

end
