COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cgrobjManager.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/ 2/92   	Initial version.

DESCRIPTION:
	

	$Id: cgrobjManager.asm,v 1.1 97/04/04 17:48:06 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	chartGeode.def

ChartClassStructures	segment	resource
	ChartRectClass
	ChartSplineGuardianClass
	ChartLineClass
ChartClassStructures	ends


ChartMiscCode	segment resource

include cgrobjRect.asm
include cgrobjSpline.asm


ChartMiscCode	ends
