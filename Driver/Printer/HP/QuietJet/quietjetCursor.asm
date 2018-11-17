
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		quietjet print driver
FILE:		quietjetCursor.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	9/92		Initial revision from laserplsCursor.asm


DESCRIPTION:
	This file contains most of the code to implement the quietjet
	print driver cursor movement support

	$Id: quietjetCursor.asm,v 1.1 97/04/18 11:52:14 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
include	Cursor/cursorConvert192.asm
include	Cursor/cursorPCLCommon.asm
include	Cursor/cursorSetCursorPCL.asm
