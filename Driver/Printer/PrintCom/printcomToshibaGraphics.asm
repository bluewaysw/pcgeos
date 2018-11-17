
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		early Epson 24-pin print drivers
FILE:		printcomToshibaGraphics.asm

AUTHOR:		Dave Durran 1 March 1990

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/1/90		Initial revision


DESCRIPTION:
	This file contains most of the code to implement the Toshiba 24-pin
	print driver graphics mode support

	$Id: printcomToshibaGraphics.asm,v 1.1 97/04/18 11:50:55 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	Graphics/graphicsCommon.asm		;common graphic print routines
include	Graphics/graphics2ResHigh.asm		;PrPrintABand routine.
include	Graphics/graphicsCitohCommon.asm	;common Citoh graphic rout.
include Graphics/graphicsPrintSwath48.asm	;PrintSwath routine.
include	Graphics/graphicsHi24IntX.asm		;Hi res routine,
include Graphics/Rotate/rotate2pass24Into4.asm	;and rotate routine
include	Graphics/graphicsMed24.asm		;Medium res. routine,
include Graphics/Rotate/rotate24Into4.asm	;and rotate routine.
