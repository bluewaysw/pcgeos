COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		axisManager.asm

AUTHOR:		John Wedgwood, Oct  7, 1991

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	10/ 7/91	Initial revision

DESCRIPTION:
	Manager file for the axis class.

	$Id: axisManager.asm,v 1.1 97/04/04 17:45:30 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include chartGeode.def


ChartClassStructures	segment	resource
	AxisClass	
	CategoryAxisClass
	ValueAxisClass
ifdef	SPIDER_CHART
	SpiderAxisClass
endif
ChartClassStructures	ends


AxisCode	segment resource

include	axisBuild.asm		; Build
include	axisGeometry.asm	; Geometry
include	axisPosition.asm	; Positioning
include	axisRealize.asm		; Realizing
include	axisAttrs.asm		; Attributes

include	axisLabels.asm		; Label related stuff
include	axisUtils.asm		; Utilities used by other modules
include	axisRange.asm		; Range related stuff

include	axisFloat.asm		; Stuff to put in float library

include axisValue.asm		; ValueAxis class
include axisCategory.asm	; CategoryAxis class
ifdef	SPIDER_CHART
include axisSpider.asm		; SpiderAxis class
endif

include axisGrObj.asm

if ERROR_CHECK
include axisEC.asm		; only include in EC version
endif


AxisCode	ends
