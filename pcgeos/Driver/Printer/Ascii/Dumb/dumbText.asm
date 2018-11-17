COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Dumb ASCII (Unformatted) Print Driver
FILE:		dumbText.asm

AUTHOR:		Dave Durran

ROUTINES:

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
        Dave    8/30/93         Initial Revision


DESCRIPTION:
	This file contains most of the code to implement common dumb ASCII
	print driver ascii text support

	$Id: dumbText.asm,v 1.1 97/04/18 11:56:44 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	Text/textPrintStyleRunAddX.asm
include	Text/textPrintText.asm
include	Text/textPrintRaw.asm
include	Text/textSetFont.asm
include	Text/textGetLineSpacing.asm
include	Text/textSetLineSpacing.asm
include	Text/textSetSymbolSet.asm
include	Text/textLoadNoISOSymbolSet.asm
include	Text/Font/fontDumbInfo.asm
