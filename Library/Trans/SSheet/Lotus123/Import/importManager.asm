
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
		
	$Id: importManager.asm,v 1.1 97/04/07 11:41:44 newdeal Exp $

-------------------------------------------------------------------------------@

_Import =1

include lotus123Geode.def
include lotus123Constant.def
include lotus123Macro.def

ImportCode	segment	resource
	global	TransImport:far

	include	import.asm
	include	importCell.asm
	include	importUtils.asm
	include	importPostfixToInfix.asm
	include	importTraverseTree.asm
ImportCode	ends

end
