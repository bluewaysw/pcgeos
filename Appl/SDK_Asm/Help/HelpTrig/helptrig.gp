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
# 	Geode parameters for sample application with help
#
#	$Id: helptrig.gp,v 1.1 97/04/04 16:33:49 newdeal Exp $
#
##############################################################################
#
name helptrig.app

longname "Help Triggers"

type	appl, process

appobj	HelpTrigApp

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
class	HelpTrigProcessClass

#
# Resources: list all resource blocks which are used by the application.
# (standard discardable code resources do not need to be mentioned).
#
resource AppResource object
resource Interface object















