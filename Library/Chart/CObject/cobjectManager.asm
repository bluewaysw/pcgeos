COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cobjectManager.asm

AUTHOR:		John Wedgwood, Oct  8, 1991

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	10/ 8/91	Initial revision

DESCRIPTION:
	Manager file for the Chart Object module.

	$Id: cobjectManager.asm,v 1.1 97/04/04 17:46:17 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include chartGeode.def

ChartClassStructures	segment	resource
	ChartObjectClass
	ChartObjectMultipleClass
	ChartObjectDualClass
ChartClassStructures	ends


ChartObjectCode	segment resource

include cobjectAttrs.asm
include cobjectBuild.asm
include	cobjectEvent.asm
include cobjectGeometry.asm
include cobjectGrObj.asm
include cobjectPosition.asm
include cobjectRealize.asm
include cobjectUtils.asm
include cobjectMultiple.asm
include cobjectDual.asm
include cobjectNotify.asm
include cobjectState.asm

if ERROR_CHECK
include cobjectEC.asm
endif	

ChartObjectCode	ends



