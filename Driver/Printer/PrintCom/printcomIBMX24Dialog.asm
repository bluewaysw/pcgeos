
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		print drivers
FILE:		printcomIBMX24Dialog.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	7/93		Initial revision


DESCRIPTION:
	This file contains most of the code to implement the 1 bin ASF
	+tractor and manual feed print driver UI support for IBM Proprinters

	$Id: printcomIBMX24Dialog.asm,v 1.1 97/04/18 11:50:07 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	UI/uiGetNoMain.asm		;pass no tree for Main box
include	UI/uiGetOptions.asm		;pass tree for Options box
include	UI/uiEval.asm			;call the routine specified in device
					;info resource.
include	UI/uiEval1ASFSymbol.asm		;paper input path and country code 
					;selecting routines.
include	UI/uiEval1ASFOnlySymbol.asm	;paper input path and country code 
					;selecting routines.
