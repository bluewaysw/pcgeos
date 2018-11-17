
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Citoh 8510 type 9-pin print drivers
FILE:		printcomCitohGraphics.asm

AUTHOR:		Dave Durran 1 March 1990

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/1/90		Initial revision
	Dave	3/92		moved from epson9


DESCRIPTION:
	This file contains most of the code to implement the Citoh type
	print driver graphics mode support

	$Id: printcomCitohGraphics.asm,v 1.1 97/04/18 11:50:45 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	Graphics/graphicsCommon.asm		;common graphic print routines
include	Graphics/graphics2Resolutions.asm	;PrPrintABand routine.
include	Graphics/graphicsCitohCommon.asm	;common Citoh graphic rout.
include Graphics/graphicsPrintSwath144.asm	;PrintSwath routine.
include	Graphics/graphicsHi8IntY.asm		;Hi res routine,
include	Graphics/graphicsLo8.asm		;Lo res routine,
include Graphics/Rotate/rotate8Back.asm		;and rotate routine.
