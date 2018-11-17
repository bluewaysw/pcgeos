COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		legendManager.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/10/92   	Initial version.

DESCRIPTION:
	

	$Id: legendManager.asm,v 1.1 97/04/04 17:46:31 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	chartGeode.def

ChartClassStructures	segment	resource
	LegendClass
	LegendPairClass
	LegendItemClass

	method	LegendItemRealize, LegendItemClass, MSG_CHART_OBJECT_REALIZE
	method	LegendRealize, LegendClass, MSG_CHART_OBJECT_REALIZE
ChartClassStructures	ends

ChartMiscCode	segment resource

include legendAttrs.asm
include	legendBuild.asm
include legendGeometry.asm
include legendSelect.asm
include legendPair.asm
include legendItem.asm

ChartMiscCode	ends

