COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer Drivers
FILE:		printcomCapslText.asm

AUTHOR:		Dave Durran

ROUTINES:

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	6/92		Initial version from parsed routines


DESCRIPTION:
	This file contains most of the code to implement common CaPSL
	print driver ascii text support

	$Id: printcomCapslText.asm,v 1.1 97/04/18 11:51:09 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	Text/textPrintStyleRun.asm
include	Text/textPrintText.asm
include	Text/textPrintRaw.asm
include	Text/textSetFontCapsl.asm
include	Text/textGetLineSpacing.asm
include	Text/textSetLineSpacing.asm
include	Text/textSetSymbolSet.asm
include	Text/textLoadNoISOSymbolSet.asm
include	Text/Font/fontCapslInfo.asm
