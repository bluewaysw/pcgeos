COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		mainManager.asm

AUTHOR:		jimmy lefkowitz

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	3/ 2/92		Initial version.

DESCRIPTION:

	$Id: mainManager.asm,v 1.1 97/04/05 01:22:53 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include mathGeode.def
include mathConstants.def


InitCode segment resource
global FloatInit:far
global FloatExit:far
InitCode ends

include mainMain.asm
include mainThread.asm
