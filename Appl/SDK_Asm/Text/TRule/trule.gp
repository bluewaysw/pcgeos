##############################################################################
#
#	Copyright (c) Geoworks 1990-1994 -- All Rights Reserved
#
# PROJECT:	GEOS
# MODULE:	TRule (Sample GEOS application)
# FILE:		trule.gp
#
# AUTHOR:	Tony Requist
#
# DESCRIPTION:	This file contains Geode definitions for the "TRule" sample
#		application. This file is read by the GLUE linker to
#		build this application.
#
# RCS STAMP:
#	$Id: trule.gp,v 1.1 97/04/04 16:33:41 newdeal Exp $
#
##############################################################################
#
name trule.app
#
longname "Text Ruler"
#
type	appl, process, single
#
class	TRProcessClass
#
appobj	TRApp
#
# This token must match both the token in the GenApplication and the token
# in the GenUIDocumentControl.
#
tokenchars "SAMP"
tokenid 8
#
library	geos
library	ui
library	text
library	ruler
#
resource AppResource ui-object
resource Interface ui-object
#
# Exported entry points
#
