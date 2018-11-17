##############################################################################
#
#	Copyright (c) GeoWorks 1990 -- All Rights Reserved
#
# PROJECT:	PC/GEOS
# MODULE:	TextUI (Sample PC/GEOS application)
# FILE:		toolsamp.gp
#
# AUTHOR:	Doug Fults
#
# DESCRIPTION:	This file contains Geode definitions for the "Tool" sample
#		application. This file is read by the GLUE linker to
#		build this application.
#
# RCS STAMP:
#	$Id: toolsamp.gp,v 1.1 97/04/04 16:34:52 newdeal Exp $
#
##############################################################################
#
name toolsamp.app
#
longname "GenToolControl Sample App"
#
type	appl, process, single
#
class	TSProcessClass
#
appobj	TSApp
#
# This token must match both the token in the GenApplication and the token
# in the GenUIDocumentControl.
#
tokenchars "ATSS"
tokenid 0
#
library	geos
library	ui
library	text
#
resource AppResource ui-object
resource Interface ui-object
