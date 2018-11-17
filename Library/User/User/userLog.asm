
COMMENT @-----------------------------------------------------------------------

	Copyright (c) Geoworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		userLog.asm

AUTHOR:		Cheng, 3/91

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial revision
	Doug	8/91		Functionality moved to kernel

DESCRIPTION:
	Allows the system to write stuff out to a log file.
	Belongs logically to the file module in the kernel but there's
	no need for this stuff to be in fixed memory.
		
	$Id: userLog.asm,v 1.1 97/04/07 11:45:52 newdeal Exp $

-------------------------------------------------------------------------------@


; ALL code in this file moved to the kernel 8/28/91	-- Doug

