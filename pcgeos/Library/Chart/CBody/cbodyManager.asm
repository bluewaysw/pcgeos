COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cbodyManager.asm

AUTHOR:		John Wedgwood, Oct  8, 1991

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/18/91	Initial Revision 

DESCRIPTION:
	Manager file for the Chart Body module.

	$Id: cbodyManager.asm,v 1.1 97/04/04 17:48:14 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


include chartGeode.def

ChartClassStructures	segment	resource
	ChartBodyClass
ChartClassStructures	ends

ChartBodyCode	segment resource

include cbodyCreate.asm
include cbodyComposite.asm
include cbodyGrObj.asm		
include cbodyNotify.asm		
include cbodyRelocate.asm
include cbodySelect.asm	
include cbodySuspend.asm
include cbodyTarget.asm
include cbodyTransfer.asm
include cbodyUI.asm		

ChartBodyCode	ends
