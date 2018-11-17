COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer Drivers
FILE:		ppds24Text.asm

AUTHOR:		Dave Durran

ROUTINES:

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	5/92		Initial version from parsed routines


DESCRIPTION:
	This file contains most of the code to implement common PPDS 24 pin
	print driver ascii text support

	$Id: ppds24Text.asm,v 1.1 97/04/18 11:54:27 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	Text/textPrintText.asm
include	Text/textPrintRaw.asm
include	Text/textSetFont.asm
include	Text/textPrintStyleRun.asm
include	Text/textGetLineSpacing.asm
include	Text/textSetLineSpacing.asm
include Text/textSetSymbolSet.asm
include Text/textLoadNoISOSymbolSet.asm
include	Text/Font/fontIBMPPDSInfo.asm
