##############################################################################
#
#	Copyright (c) GeoWorks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	IStartup
# FILE:		istartup.gp
#
# AUTHOR:	Tony, 10/89
#
#
# Parameters file for: istartup.geo
#
#	$Id: istartup.gp,v 1.1 97/04/04 16:52:54 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name istartup.app
#
# Long filename
#
longname "ICLAS Startup"
#
# Specify geode type
#
type	appl, process, single
#
# Specify stack size
#
stack   1500
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
tokenchars "STRT"
tokenid 0
#
# Import library routine definitions
#
library	geos
library	ui
library iclas
library net
library spool noload

#
# Define resources other than standard discardable code
#
resource Resident		code read-only fixed
resource InitCode		code read-only shared discard-only preload

resource AppResource			object
resource OverviewRoomResource		object
resource EditDialogResource		object

resource Strings			object read-only shared
resource IniStrings			object read-only shared

resource StaticRoom1Resource		object shared
resource StaticRoom2Resource		object shared
resource StaticRoom3Resource		object shared
resource StaticLoginRoomResource	object shared
#resource StaticMouseRoomResource	object shared

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
export StartupRoomTriggerClass
export StartupFieldClass
export QuizDialogClass
export IStartupFieldClass

