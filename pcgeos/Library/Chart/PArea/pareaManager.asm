COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		pareaManager.asm

AUTHOR:		John Wedgwood, Oct  8, 1991

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	10/ 8/91	Initial revision

DESCRIPTION:
	Manager file for the Plot Area module.

	$Id: pareaManager.asm,v 1.1 97/04/04 17:46:49 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	chartGeode.def

ChartClassStructures	segment	resource
	PlotAreaClass
ChartClassStructures	ends

ChartCompCode	segment resource

include	pareaBuild.asm	
include	pareaGeometry.asm
include	pareaPosition.asm
include	pareaRealize.asm

if ERROR_CHECK
include pareaEC.asm
endif


ChartCompCode	ends
