##############################################################################
#
#	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
#
# Parameters file for: launcher.gp
#
#	$Id: launcher.gp,v 1.1 97/04/04 16:13:49 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name launcher.app
#
# Long name
#
ifdef DO_DBCS
	longname "DOS Launcher"
else
	longname "Default DOS Launcher"
endif
#
# DB Token
#
tokenchars "LAUN"
tokenid 0
#
# Specify geode type
#
type	appl, process, single
#
# Specify class name for process
#
class	LauncherClass

#
# Specify application object
#
appobj	LauncherApp
#
# Import library routine definitions
#
library	geos
library	ui

#
# GeoManager needs to know for sure what each resource ID is, so turn off
# resource-sorting in the linker.
#
nosort
#
# Define resources other than standard discardable code
#
#	Make sure the ordering of these resources agrees with what
#	GeoManager thinks they should be.  This is also documented in
#	launcher.def, make sure everything agrees.

# Core block					= resource #0


# dgroup					= resource #1


# Main (code)					= resource #2
resource Main read-only shared code

# LauncherStrings				= resource #3
resource LauncherStrings shared lmem

# AppUI 					= resource #4
resource AppUI ui-object

# Interface					= resource #5
resource Interface ui-object

# AppLCMonikerResource				= resource #6
resource AppLCMonikerResource ui-object read-only shared

# AppLMMonikerResource				= resource #7
resource AppLMMonikerResource ui-object read-only shared

# AppSCMonikerResource				= resource #8
resource AppSCMonikerResource ui-object read-only shared

# AppSMMonikerResource				= resource #9
resource AppSMMonikerResource ui-object read-only shared

# AppTCMonikerResource				= resource #10
resource AppTCMonikerResource ui-object read-only shared

# AppTMMonikerResource				= resource #11
resource AppTMMonikerResource ui-object read-only shared

# LauncherErrorStrings				= resource #12
resource LauncherErrorStrings read-only shared lmem

# LauncherCodewords				= resource #13
resource LauncherCodewords read-only shared lmem

#
# Export classes
#
export LauncherClass
