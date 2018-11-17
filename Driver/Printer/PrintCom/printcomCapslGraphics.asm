COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer Drivers
FILE:		printcomCapslGraphics.asm

AUTHOR:		Dave Durran

ROUTINES:

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	6/92		Initial version from parsed routines


DESCRIPTION:
	This file contains most of the code to implement common CAPSL
	print driver Graphics support

	$Id: printcomCapslGraphics.asm,v 1.1 97/04/18 11:51:07 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include Graphics/graphicsCommon.asm             ;common graphic print routines
include	Graphics/graphicsCapslCommon.asm	;PrPrintABand routine.
include	Graphics/graphicsAdjustForResolution.asm ;PrAdjustForResolution routine.
include	Graphics/graphicsPrintSwath300.asm	;PrintSwath routine.
