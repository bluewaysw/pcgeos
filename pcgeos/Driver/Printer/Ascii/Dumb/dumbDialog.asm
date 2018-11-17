
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Dumb ASCII (Unformatted) Print Driver
FILE:		dumbDialog.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
        Dave    8/30/93         Initial Revision


DESCRIPTION:
	This file contains most of the code to implement the 0 bin ASF
	+tractor and manual feed print driver UI support

	$Id: dumbDialog.asm,v 1.1 97/04/18 11:56:43 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	UI/uiGetNoMain.asm		;pass no tree for Main box
include	UI/uiGetOptions.asm		;pass tree for Options box
include	UI/uiEval.asm			;call the routine specified in device
					;info resource.
include	UI/uiEvalDummyTractor.asm	;paper input path
					;selecting routines.
