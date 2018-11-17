##############################################################################
#
#	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
#
# Parameters file for: launchergcm.geo
#
#	$Id: launchergcm.gp,v 1.1 97/04/04 16:13:52 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name launcher.gcm
#
# Long name
#
longname "Launcher1"
#
# DB Token
#
tokenchars "LAU1"
tokenid 0
#
# Specify geode type
#
type	appl, process, single, has-gcm
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
# Define resources other than standard discardable code
#
resource AppUI ui-object
resource LauncherStrings read-only shared lmem
resource LauncherErrorStrings read-only shared lmem
resource LauncherCodewords read-only shared lmem

#
# Resources containing monikers
#
resource AppLCMonikerResource read-only shared lmem
resource AppLMMonikerResource read-only shared lmem
resource AppSCMonikerResource read-only shared lmem
resource AppSMMonikerResource read-only shared lmem
resource AppTCMonikerResource read-only shared lmem
resource AppTMMonikerResource read-only shared lmem

#
# Export classes
#
export LauncherClass
