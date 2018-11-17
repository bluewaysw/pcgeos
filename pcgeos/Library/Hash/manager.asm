COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Hash library
FILE:		manager.asm

AUTHOR:		Paul L. DuBois, Nov  7, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	11/ 7/94   	Initial revision


DESCRIPTION:
	Manager file for hash library.

	$Id: manager.asm,v 1.1 97/05/30 06:49:01 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include hashGeod.def

;%%%%		Code

include hMain.asm
include hC.asm
include hIndex.asm
include hIndexEC.asm
include hHeap.asm
include hHeapEC.asm
