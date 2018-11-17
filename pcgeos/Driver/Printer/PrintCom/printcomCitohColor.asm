
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		C.Itoh Print Drivers
FILE:		printcomCitohColor.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	6/93		Initial revision


DC_ESCRIPTION:
	This file contains all the color setting routines for the C.Itoh 
	driver.
		
	$Id: printcomCitohColor.asm,v 1.1 97/04/18 11:50:08 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	Color/colorSetNextCMYK.asm
include	Color/colorSetFirstCMYK.asm
include	Color/colorGetFormat.asm
include	Color/colorSet.asm
include	Color/colorIWMapRGBToCMYK.asm
include	Color/colorSetRibbon.asm
