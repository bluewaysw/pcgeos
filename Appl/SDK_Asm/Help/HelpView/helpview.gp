##############################################################################
#
#	Copyright (c) Geoworks 1990-1994 -- All Rights Reserved
#
# PROJECT:	GEOS
# MODULE:	
# FILE:		helpview.gp
#
# AUTHOR:	Gene Anderson, Nov  6, 1992
#
# 	Geode parameters for sample help viewer application
#
#	$Id: helpview.gp,v 1.1 97/04/04 16:33:47 newdeal Exp $
#
##############################################################################
#
name helpview.app

longname "Help Viewer"

type	appl, process

appobj	HelpViewApp

tokenchars "SAMP"
tokenid 8

#
# Libraries: list which libraries are used by the application.
#
library	geos
library	ui

#
# Specify class name for process
#
class	HelpViewProcessClass

#
# Resources: list all resource blocks which are used by the application.
# (standard discardable code resources do not need to be mentioned).
#
resource AppResource object
resource Interface object















