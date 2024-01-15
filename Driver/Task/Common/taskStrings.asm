COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		taskStrings.asm

AUTHOR:		Adam de Boor, Sep 21, 1991

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	9/21/91		Initial revision


DESCRIPTION:
	Strings required by us, in an lmem segment so they can be localized.
		

	$Id: taskStrings.asm,v 1.2 98/02/23 20:12:23 gene Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TaskStrings	segment	lmem	LMEM_TYPE_GENERAL

unableToSuspendMsg	chunk.char "Unable to suspend PC/GEOS: \1", 0

TaskStrings	ends
