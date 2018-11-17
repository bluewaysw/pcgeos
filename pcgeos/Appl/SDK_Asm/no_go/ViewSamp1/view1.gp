##############################################################################
#
#	Copyright (c) GeoWorks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Silly Little Programs
# FILE:		view.gp
#
# AUTHOR:	Chris 4/89
#
#
# Parameters file for: view1.geo
#
#	$Id: view1.gp,v 1.1 97/04/04 16:34:58 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name view1.app
#
# Specify geode type
#
type	appl, process
#
# Specify class name for process
#
class	view1_ProcessClass
#
# Specify application object
#
appobj	MyApp
#
# Token: this four-letter name is used by geoManager to locate the icon for 
# this application in the database.
#
tokenchars "VIW1"
tokenid 0
#
# Import library routine definitions
#
library	geos
library	ui
#
# Define resources other than standard discardable code
#
resource Interface ui-object 
#
# Other classes
#
