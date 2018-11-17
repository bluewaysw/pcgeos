COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		PostScript printer driver
FILE:		printcomPScriptDialog.asm

AUTHOR:		Dave Durran

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Dave	4/93	initial version

DESCRIPTION:
	This file contains the source for the PostScript printer driver UI

	$Id: printcomPScriptDialog.asm,v 1.1 97/04/18 11:51:30 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

include UI/uiGetNoMain.asm
include UI/uiGetOptions.asm
include UI/uiEval.asm
include UI/uiEvalDummyASF.asm
include UI/uiEvalIBM4019PS.asm
