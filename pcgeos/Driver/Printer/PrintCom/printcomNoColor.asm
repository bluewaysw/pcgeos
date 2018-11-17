
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Monochrome Print Drivers
FILE:		printcomNoColor.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	5/92		Initial revision


DC_ESCRIPTION:
	This file contains all the color setting routines for the Monochrome 
	drivers.
		
	$Id: printcomNoColor.asm,v 1.1 97/04/18 11:50:15 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	Color/colorSetNextMono.asm
include	Color/colorSetFirstMono.asm
include	Color/colorGetFormat.asm
include	Color/colorSetNone.asm
