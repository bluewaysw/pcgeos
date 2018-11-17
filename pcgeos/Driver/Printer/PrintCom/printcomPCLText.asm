COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer Drivers
FILE:		printcomPCLText.asm

AUTHOR:		Dave Durran

ROUTINES:

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	5/92		Initial version from parsed routines


DESCRIPTION:

	$Id: printcomPCLText.asm,v 1.1 97/04/18 11:50:08 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	Text/textPrintStyleRunPCL.asm
include	Text/textPrintText.asm
include	Text/textPrintRaw.asm
include	Text/textSetFontPCL.asm
include	Text/textGetLineSpacing.asm
include	Text/textSetLineSpacing.asm
include	Text/textSetSymbolSet.asm
include	Text/textLoadNoISOSymbolSet.asm
include	Text/Font/fontPCLInfo.asm
