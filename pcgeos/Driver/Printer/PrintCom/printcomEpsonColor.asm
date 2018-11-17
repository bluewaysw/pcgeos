
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Epson Print Drivers
FILE:		printcomEpsonColor.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	1/92		Initial revision


DC_ESCRIPTION:
	This file contains all the color setting routines for the Epson 
	drivers.
		
	$Id: printcomEpsonColor.asm,v 1.1 97/04/18 11:50:15 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	Color/colorSetNextCMYK.asm
include	Color/colorSetFirstCMYK.asm
include	Color/colorGetFormat.asm
include	Color/colorSet.asm
include	Color/colorMapRGBToCMYK.asm
include	Color/colorSetRibbon.asm
