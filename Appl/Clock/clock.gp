##############################################################################
#
#	Copyright (c) GeoWorks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Clock
# FILE:		clock.gp
#
# AUTHOR:	Gene, 1/91
#
#
# Parameters file for: clock.geo
#
#	$Id: clock.gp,v 1.1 97/04/04 14:51:11 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name clock.app

heapspace 2500
#
# Specify geode type
#
type	process, appl, single
#
# Specify class name and application object for process
#
class	ClockClass
appobj	ClockAppObj
#
# Import library routine definitions
#
library	geos
library ui
#
# Desktop-related definitions
#
longname "Clock"
tokenchars "CLK$"
tokenid 0
#
# Special resource definitions
#
resource ApplicationUI object
resource Interface object
resource DigitalUIResource object

resource SkeletonUIResource object
resource HermanUIResource object
resource AnalogUIResource object

resource AppSCMonikerResource object read-only discardable
resource AppSMMonikerResource object read-only discardable
resource AppSCGAMonikerResource object read-only discardable
#
# Define exported entry points (for unrelocating)
#
export ClockAppClass
export VisClockClass
export VisDigitalClockClass

export VisHermanClockClass
export VisAnalogClockClass
export VisSkeletonClockClass
export ClockLocationListClass

export ClockColorSelectorClass
