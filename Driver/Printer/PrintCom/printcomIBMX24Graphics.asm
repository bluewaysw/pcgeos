
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		early IBM 24-pin print drivers
FILE:		printcomIBMX24Graphics.asm

AUTHOR:		Dave Durran 1 March 1990

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/1/90		Initial revision


DESCRIPTION:
	This file contains most of the code to implement the IBM 24-pin
	print driver graphics mode support

	$Id: printcomIBMX24Graphics.asm,v 1.1 97/04/18 11:50:48 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	Graphics/graphicsCommon.asm		;common graphic print routines
include	Graphics/graphics3Resolutions.asm	;PrPrintABand routine.
include	Graphics/graphicsIBMX24Common.asm	;common IBMX24 graphic rout.
include Graphics/graphicsPrintSwath72To180.asm	;PrintSwath routine.
include	Graphics/graphicsHi24IntX.asm		;Hi res routine,
include Graphics/Rotate/rotate2pass24.asm	;and rotate routine
include	Graphics/graphicsMed24.asm		;Medium res. routine,
include Graphics/Rotate/rotate24.asm		;and rotate routine.
include	Graphics/graphicsLo8.asm		;Lo res routine,
include Graphics/Rotate/rotate8.asm		;and rotate routine.
