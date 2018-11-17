COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Canon 48-jet print drivers
FILE:		printcomCanon48Graphics.asm

AUTHOR:		Dave Durran 1 March 1990

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/1/90		Initial revision


DESCRIPTION:
	This file contains most of the code to implement the Canon 48-jet
	print driver graphics mode support

	$Id: printcomCanon48Graphics.asm,v 1.1 97/04/18 11:50:45 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	Graphics/graphicsCommon.asm		;common graphic print routines
include	Graphics/graphics3Resolutions.asm	;PrPrintABand routine.
include	Graphics/graphicsIBMX24Common.asm	;common IBMX24 graphic rout.
include Graphics/graphicsPrintSwath72To360.asm	;PrintSwath routine.
include	Graphics/graphicsHi48.asm		;Hi res routine,
include Graphics/Rotate/rotate48.asm		;and rotate routine
include	Graphics/graphicsMed24.asm		;Medium res. routine,
include Graphics/Rotate/rotate24.asm		;and rotate routine.
include	Graphics/graphicsLo8.asm		;Lo res routine,
include Graphics/Rotate/rotate8.asm		;and rotate routine.
