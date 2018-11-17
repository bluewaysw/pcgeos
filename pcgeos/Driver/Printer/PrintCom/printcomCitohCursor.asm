
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CItoh 9-pin print drivers
FILE:		printcomEpsonFXCursor.asm

AUTHOR:		Dave Durran, 14 March 1990

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/14/90		Initial revision
	Dave	3/92		moved from epson9 to printcom


DESCRIPTION:
	This file contains most of the code to implement the CItoh 8510 type
	print driver cursor movement support

	The cursor position is kept in 2 words: integer 144s in Y and
	integer 72nds in X

	$Id: printcomCitohCursor.asm,v 1.1 97/04/18 11:50:10 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	Cursor/cursorDotMatrixCommon.asm
include	Cursor/cursorSetCursorAbsPitch.asm
include	Cursor/cursorPrLineFeedSetASCII.asm
include	Cursor/cursorPrFormFeedGuess.asm
include	Cursor/cursorConvert144.asm
include	Cursor/cursor1ScanlineFeed.asm
