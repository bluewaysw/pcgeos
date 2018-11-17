
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Star 9-pin print drivers
FILE:		printcomStarSGGraphics.asm

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
	This file contains most of the code to implement the star SG type
	print driver graphics mode support

	$Id: printcomStarSGGraphics.asm,v 1.1 97/04/18 11:50:55 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	Graphics/graphicsCommon.asm		;common graphic print routines
include	Graphics/graphics3Resolutions.asm	;PrPrintABand routine
include	Graphics/graphicsEpsonCommon.asm	;common Epson graphic rout.
include Graphics/graphicsPrintSwath144.asm	;PrintSwath routine.
include	Graphics/graphicsHi8IntXY.asm		;Hi res routine,
include Graphics/Rotate/rotate2pass8.asm	;and rotate routine
include	Graphics/graphicsMed8IntY.asm		;Medium res. routine,
include	Graphics/graphicsLo8.asm		;Lo res routine,
include Graphics/Rotate/rotate8.asm		;and rotate routine.

