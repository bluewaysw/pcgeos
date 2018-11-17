COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GlobalPC 1999 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer Drivers
FILE:		printcomCanonBJCCursor.asm

AUTHOR:		Joon Song

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	1/99		Initial revision from printcomCanonCursor48.asm


DESCRIPTION:
	This file contains most of the code to implement the Canon BJC
	print driver cursor movement support

	$Id$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	Cursor/cursorDotMatrixCommon.asm
include	Cursor/cursorSetCursorAbsCanonBJC.asm
include	Cursor/cursorPrLineFeedCanonBJC.asm
include	Cursor/cursorPrFormFeedGuess.asm
include	Cursor/cursorConvert360.asm
