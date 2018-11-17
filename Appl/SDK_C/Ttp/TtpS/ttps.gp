##############################################################################
#
#	Copyright (c) Geoworks 1995 -- All Rights Reserved
#
# PROJECT:	GEOS
# FILE:		ttps.gp
#
# AUTHOR:	Chung Liu, Apr 12, 1995
#
#	Geode definitions for TinyTP server test application.
#
#	$Id: ttps.gp,v 1.1 97/04/04 16:41:12 newdeal Exp $
#
##############################################################################
#
name ttps.app
longname "TinyTP Server"
#
# Specify geode type: is an application, will have its own process (thread)
# and is multi-launchable.
#
type	appl, process
#
class	TtpsProcessClass
#
# Specify application object. This is the object in the .ui file which serves
# as the top-level UI object in the application.
#
appobj	TtpsApp
#
# Token: this four-letter name is used by geoManager to locate the icon for this
# application in the database.
#
tokenchars "TTPS"
tokenid 8
#
# Libraries: list which libraries are used by the application.
#
library	geos
library	ui
library irlmp
library netutils

#
# Resources: list all resource blocks which are used by the application.
# (standard discardable code resources do not need to be mentioned).
#
resource APPRESOURCE ui-object
resource INTERFACE ui-object
resource TTPSSTRINGS lmem read-only shared
