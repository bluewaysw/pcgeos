
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Toshiba 24-pin print drivers
FILE:		printcomToshibaCursor.asm

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
	This file contains most of the code to implement the Toshiba 24pin type
	print driver cursor movement support

	The cursor position is kept in 2 words: integer 48s in Y and
	integer 72nds in X

	$Id: printcomToshibaCursor.asm,v 1.1 97/04/18 11:50:26 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	Cursor/cursorDotMatrixCommon.asm
include	Cursor/cursorSetCursorTosh.asm
include	Cursor/cursorPrLineFeedSetASCII.asm
include	Cursor/cursorPrFormFeedGuess.asm
include	Cursor/cursorConvert48.asm
