##############################################################################
#
#	Copyright (c) Geoworks 1995 -- All Rights Reserved
#
# PROJECT:	GEOS
# FILE:		serverir.gp
#
# AUTHOR:	Chung Liu, Apr 12, 1995
#
#	Geode definitions for ServerIR test application.
#
#	$Id: serverir.gp,v 1.1 97/04/04 16:40:48 newdeal Exp $
#
##############################################################################
#
name serverir.app
longname "ServerIR"
#
# Specify geode type: is an application, will have its own process (thread)
# and is multi-launchable.
#
type	appl, process
#
class	ServerirProcessClass
#
# Specify application object. This is the object in the .ui file which serves
# as the top-level UI object in the application.
#
appobj	ServerirApp
#
# Token: this four-letter name is used by geoManager to locate the icon for this
# application in the database.
#
tokenchars "SRIR"
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
resource SERVERIRSTRINGS lmem read-only shared
