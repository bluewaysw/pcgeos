##############################################################################
#
#	Copyright (c) GeoWorks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Silly Little Programs
# FILE:		largedoc.gp
#
# AUTHOR:	Chris 4/89
#
#
# Parameters file for: largedoc.geo
#
#	$Id: largedoc.gp,v 1.1 97/04/04 16:34:35 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name largedoc.app
#
# Specify geode type
#
type	appl, process
#
# Specify class name for process
#
class	largedoc_ProcessClass
#
# Specify application object
#
appobj	MyApp
#
# Token: this four-letter name is used by geoManager to locate the icon for
# this application in the database.
#
tokenchars "LDOC"
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
