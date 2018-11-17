##############################################################################
#
#	Copyright (c) Geoworks 1990-1994 -- All Rights Reserved
#
# PROJECT:	GEOS
# MODULE:	Levels (Sample GEOS application)
# FILE:		levels.gp
#
# AUTHOR:	Tony Requist
#
# DESCRIPTION:	This file contains Geode definitions for the "Levels" sample
#		application. This file is read by the GLUE linker to
#		build this application.
#
# RCS STAMP:
#	$Id: levels.gp,v 1.1 97/04/04 16:33:38 newdeal Exp $
#
##############################################################################
#
name levels.app
#
longname "UI Levels"
#
type	appl, process
#
class	LevelsProcessClass
#
appobj	LevelsApp
#
# This token must match both the token in the GenApplication and the token
# in the GenUIDocumentControl.
#
tokenchars "SAMP"
tokenid 8
#
library	geos
library	ui
library text
#
resource AppResource ui-object
resource Strings lmem read-only shared
resource Interface ui-object
resource OptionsMenuUI ui-object
resource UserLevelUI ui-object
#
export LevelsApplicationClass
