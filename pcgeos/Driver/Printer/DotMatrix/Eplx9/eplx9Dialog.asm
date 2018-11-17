
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		print drivers
FILE:		eplx9Dialog.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	10/92		Initial revision


DESCRIPTION:
	This file contains most of the code to implement the Epson LX type
	+tractor and manual feed print driver UI support for countries

	$Id: eplx9Dialog.asm,v 1.1 97/04/18 11:54:40 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	UI/uiGetNoMain.asm		;pass no tree for Main box
include	UI/uiGetOptions.asm		;pass tree for Options box
include	UI/uiEval.asm			;call the routine specified in device
					;info resource.
include	UI/uiEval1ASFCountry.asm	;paper input path and country code 
					;selecting routines.
