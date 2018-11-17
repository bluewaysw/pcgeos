COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Main
FILE:		mainManager.asm

AUTHOR:		Steve Scholl

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	Steve Scholl    2/9/92        Initial revision.

DESCRIPTION:

	$Id: mainManager.asm,v 1.1 97/04/04 15:51:33 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


include	drawGeode.def

idata	segment
	
	DrawProcessClass

idata	ends


include mainInit.asm
