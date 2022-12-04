##############################################################################
#
#	Copyright (c) Geoworks 1995 -- All Rights Reserved
#
# PROJECT:	GEOS
# FILE:		ttpc.gp
#
# AUTHOR:	Chung Liu, Mar 13, 1995
#
# REVISION HISTORY:
#       Name    Date            Description
#       ----    ----            -----------
#       CL	3/13/95	        Initial version
#	RainerB	6/8/2022	Resource names adjusted for Watcom compatibility
#
# Geode definitions for TtpC test application.
#
#	$Id: ttpc.gp,v 1.1 97/04/04 16:41:04 newdeal Exp $
#
##############################################################################
#
name ttpc.app
longname "Ttp Client"
#
# Specify geode type: is an application, will have its own process (thread)
# and is multi-launchable.
#
type	appl, process
#
# Specify class name for application process. Methods sent to the Application's
# process will be handled by the TtpCProcessClass
#
class	TtpCProcessClass
#
# Specify application object. This is the object in the .ui file which serves
# as the top-level UI object in the application.
#
appobj	TtpCApp
#
# Token: this four-letter name is used by geoManager to locate the icon for this
# application in the database.
#
tokenchars "TTPC"
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
resource AppResource ui-object
resource Interface ui-object
resource TtpcStrings lmem read-only shared
