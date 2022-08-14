##############################################################################
#
#	Copyright (c) Geoworks 1995 -- All Rights Reserved
#
# PROJECT:	GEOS
# FILE:		clientir.gp
#
# AUTHOR:	Chung Liu, Mar 13, 1995
#
#       Name    Date            Description
#       ----    ----            -----------
#       ??		??		        Initial version
#		RainerB	4/21/2022		Resource names adjusted for Watcom compatibility
#
# Geode definitions for ClientIR test application.
#
#	$Id: clientir.gp,v 1.1 97/04/04 16:40:39 newdeal Exp $
#
##############################################################################
#
name clientir.app
longname "ClientIR"
#
# Specify geode type: is an application, will have its own process (thread)
# and is multi-launchable.
#
type	appl, process
#
# Specify class name for application process. Methods sent to the Application's
# process will be handled by the ClientirProcessClass
#
class	ClientirProcessClass
#
# Specify application object. This is the object in the .ui file which serves
# as the top-level UI object in the application.
#
appobj	ClientirApp
#
# Token: this four-letter name is used by geoManager to locate the icon for this
# application in the database.
#
tokenchars "CLIR"
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
resource ClientirStrings lmem read-only shared
