##############################################################################
#
#	Copyright (c) GeoWorks 1991 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Chart Library
# FILE:		chart.gp
#
# AUTHOR:	John,  10/ 8/91
#
#	$Id: chart.gp,v 1.1 97/04/04 17:45:52 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name chart.lib

#
# Imported libraries
#
library geos
library ui
library math
library text
library grobj
library spline

#
# Specify geode type
#
type	library, single

#
# Desktop-related things
#
longname	"Chart Library"
tokenchars	"CHRT"
tokenid		0

#
# Define resources other than standard discardable code
#
nosort
resource ChartCompCode		read-only code shared
resource ChartObjectCode	read-only code shared
resource ChartGroupCode		read-only code shared
resource SeriesCode		read-only code shared
resource AxisCode		read-only code shared
resource ChartBodyCode		read-only code shared
resource ChartMiscCode		read-only code shared
resource ChartUI 	object read-only shared
resource StringUI 	lmem read-only shared
resource TypeControlUI 	ui-object read-only shared
resource AppTCMonikerResource lmem read-only shared
ifndef GPC_ART
resource AppTMMonikerResource lmem read-only shared
resource AppTCGAMonikerResource lmem read-only shared
endif
resource TypeControlToolboxUI ui-object read-only shared
resource GroupControlUI	ui-object read-only shared
resource AxisControlUI	ui-object read-only shared
resource GridControlUI	ui-object read-only shared
resource ChartClassStructures	read-only fixed shared


#
# Exported Classes
#
export	AxisClass
export  ValueAxisClass
export	CategoryAxisClass
export  ChartBodyClass
export	ChartGroupClass
export	ChartCompClass
export	ChartObjectClass
export  ChartObjectDualClass
export	ChartObjectMultipleClass
export	LegendClass
export	PlotAreaClass
export	SeriesGroupClass
export	TitleClass

export	ColumnClass
export	BarClass
export	SeriesDualClass
export	LineSeriesClass
export	AreaClass
export	ScatterClass
export	PieClass
export	HighLowClass

# Controllers

export	ChartTypeControlClass
export 	ChartGroupControlClass
export  ChartAxisControlClass
export 	ChartGridControlClass

# grobj subclasses

export	ChartRectClass
export	ChartLineClass
export	ChartSplineGuardianClass


# New entry points

export	LegendPairClass
export	LegendItemClass

incminor

publish	MSGCHARTBODYCREATECHART

ifdef SPIDER_CHART
export	SpiderClass
export	SpiderAxisClass
endif

#
# XIP-enabled
#

