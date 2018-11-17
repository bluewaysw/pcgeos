##############################################################################
#
#	Copyright (c) GeoWorks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Startup/WinDemo
# FILE:		welcome.gp
#
# AUTHOR:	Don Reeves, 11/2000 (copied from original Welcome)
#
#
# Parameters file for: welcome.geo
#
#	$Id:$
#
##############################################################################
#
# Permanent name
#
name welcome.app
#
# Long filename
#
longname "Welcome"
#
# Specify geode type
#
type	appl, process, single
#
# Specify stack size - reduced on 9/23/99 by Don, because there
# does not seem to be any reason to keep it larger than normal.
#
stack   2000
#
# Specify class name for process
#
class	StartupClass
#
# Specify application object
#
appobj	StartupApp
#
#
#
#
tokenchars "WLCM"
tokenid 0
#
# Import library routine definitions
#
library	geos
library	ui

#
# Define resources other than standard discardable code
#
resource Resident		code read-only fixed
resource InitCode		code read-only shared discard-only preload

resource AppResource		object
resource OverviewRoomResource	object

resource Strings		object read-only shared
resource IniStrings		object read-only shared

resource StaticRoom1Resource	object shared
resource StaticRoom2Resource	object shared
resource StaticRoom3Resource	object shared

resource WelcomeResource	object read-only shared

#
# Moniker resources
#
resource OverviewRoomLCMonikerResource	lmem shared read-only
resource OverviewRoomLMMonikerResource	lmem shared read-only
resource OverviewRoomLCGAMonikerResource lmem shared read-only

#
# Export classes
#
export StartupApplicationClass
export StartupPrimaryClass
export StartupFieldClass
