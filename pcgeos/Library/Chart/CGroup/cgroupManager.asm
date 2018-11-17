COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cgroupManager.asm

AUTHOR:		John Wedgwood, Oct  8, 1991

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	10/ 8/91	Initial revision

DESCRIPTION:
	Manager file for the Chart Group module.

	$Id: cgroupManager.asm,v 1.1 97/04/04 17:45:38 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	chartGeode.def


ChartClassStructures	segment	resource
ChartGroupClass
ChartClassStructures	ends



ChartGroupCode	segment resource


include cgroupAttrs.asm		
include	cgroupBuild.asm		
include cgroupGeometry.asm	
include cgroupGrObj.asm		

include cgroupData.asm
include cgroupPosition.asm
include cgroupRealize.asm
include cgroupSelect.asm
include cgroupState.asm
include	cgroupUtils.asm
include cgroupOrder.asm

if ERROR_CHECK
include cgroupEC.asm
endif

ChartGroupCode	ends


