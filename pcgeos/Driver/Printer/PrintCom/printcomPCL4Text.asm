
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		LaserJet print driver
FILE:		printcomPCL4Text.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------
	PrInitFont		Set default font to courier 10 pitch
	PrintTestStyles		Test legality of printer text style word
	PrintSetStyles		Set printer text style word
	PrintText		Print a text string
	PrintRaw		Send raw bytes to the printer
	PrintSetFont		Set a new text mode font
	PrintSetURWMono12	Set text mode font to URW Mono 12 pt
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	6/92		Initial revision


DESCRIPTION:
	This file contains most of the code to implement the PCL 4
	print driver text support

	$Id: printcomPCL4Text.asm,v 1.1 97/04/18 11:50:06 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
include	Text/textGetLineSpacing.asm
include	Text/textSetLineSpacing.asm
include	Text/textPrintTextPCL4.asm
include	Text/textPrintRaw.asm
include	Text/textSetFontPCL4.asm
include	Text/textInitFontPCL4.asm
include Text/textSetSymbolSet.asm
include Text/textLoadNoISOSymbolSet.asm
include	Text/textPrintStyleRunPCL4.asm

include	Text/Font/fontTopLevelPCL4.asm
include	Text/Font/fontDownloadPCL4.asm
include	Text/Font/fontInternalPCL4.asm
include	Text/Font/fontUtilsPCL4.asm
include	Text/Font/fontPCLInfo.asm

