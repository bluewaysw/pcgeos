##############################################################################
#
#	Copyright (c) Palm Computing, Inc. 1992 -- All Rights Reserved
#
# PROJECT:	PEN GEOS
# MODULE:	World Clock
# FILE:		wclock.gp
#
# AUTHOR:	Roger Flores, October 12 1992
#
#
# Parameters file for: wclock.geo
#
#	$Id: wclock.gp,v 1.1 97/04/04 16:21:57 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name wclock.app
#
# Long filename
#
longname "World Clock"
#
# Token information
#
tokenchars "WCLK"
tokenid 0
#
# Specify geode type
#
type	appl, process, single
#
# Specify stack size
#
#
# Specify heap space occupied (35280 + 30000) / 16
#
# Adjusted for new heapspace usage allocation method.  --JimG 3/17/95
#
heapspace 1600
#
# Specify class name for process
#
class	WorldClockProcessClass
#
# Specify application object
#
appobj	WorldClockApp
#
# Import library routine definitions
#
library	geos
library	ui

#
# Define resources other than standard discardable code
#
resource InitCode		code read-only shared discard-only preload

# These use to be ui-object instead of object
resource ApplicationUI		object
#resource PrimaryInterface	object
resource Interface		object
resource SelectionListResource	object
resource DialogResource		object

resource AppYMMonikerResource   lmem read-only shared


resource ErrorBlock		lmem read-only shared


#resource Strings		lmem read-only shared
#
# Define exported entry points (for object saving)
#
export WorldClockApplicationClass
export CustomApplyInteractionClass
export GenFastInteractionClass
export GenNotSmallerThanWorldMapInteractionClass
export OptionsInteractionClass
export SpecialSizePrimaryClass


