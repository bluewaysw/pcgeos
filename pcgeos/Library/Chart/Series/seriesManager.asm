COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		seriesManager.asm

AUTHOR:		John Wedgwood, Oct  8, 1991
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	10/ 8/91	Initial revision

DESCRIPTION:
	Manager file for the Series module

	$Id: seriesManager.asm,v 1.1 97/04/04 17:47:03 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	chartGeode.def
include gstring.def

ChartClassStructures	segment	resource
	ColumnClass
	BarClass
	SeriesDualClass
	LineSeriesClass
	AreaClass
	ScatterClass
	PieClass
	HighLowClass
ifdef	SPIDER_CHART
	SpiderClass
endif
ChartClassStructures	ends

SeriesCode	segment

include seriesArea.asm
include seriesColumn.asm	; bar also
include seriesDual.asm
include seriesLine.asm
include seriesPie.asm
include	seriesRealize.asm
include seriesScatter.asm
include seriesLegendRealize.asm
include seriesGroupRealize.asm
include	seriesUtils.asm
include seriesHighLow.asm
ifdef	SPIDER_CHART
include seriesSpider.asm
endif

if ERROR_CHECK
include seriesEC.asm
endif

SeriesCode	ends
