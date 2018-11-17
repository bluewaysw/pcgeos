
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		print drivers
FILE:		printcomPCL4Dialog.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	2/92		Initial revision


DESCRIPTION:
	This file contains most of the code to implement the 
	PCL4 evaluation routines.

	$Id: printcomPCL4Dialog.asm,v 1.1 97/04/18 11:50:51 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	UI/uiGetMain.asm		;pass tree for Main box
include	UI/uiGetOptions.asm		;pass tree for Options box
include	UI/uiEval.asm			;call the routine specified in device
					;info resource.
include	UI/uiEvalPCL4Simplex.asm	;paper input path selecting routines.
include	UI/uiEvalPCL4Duplex.asm		;paper output path selecting routines.
