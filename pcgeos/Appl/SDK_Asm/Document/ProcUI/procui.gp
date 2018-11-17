##############################################################################
#
#	Copyright (c) Geoworks 1990-1994 -- All Rights Reserved
#
# PROJECT:	GEOS
# MODULE:	ProcUI (Sample GEOS application)
# FILE:		procui.gp
#
# AUTHOR:	Tony Requist
#
# DESCRIPTION:	This file contains Geode definitions for the "ProcUI" sample
#		application. This file is read by the GLUE linker to
#		build this application.
#
# RCS STAMP:
#	$Id: procui.gp,v 1.1 97/04/04 16:33:03 newdeal Exp $
#
##############################################################################
#
name procui.app
#
longname "ProcUI"
#
type	appl, process
#
class	PUIProcessClass
#
appobj	PUIApp
#
# This token must match both the token in the GenApplication and the token
# in the GenUIDocumentControl.
#
tokenchars "SAMP"
tokenid 8
#
library	geos
library	ui
#
resource AppResource ui-object
resource Interface ui-object
resource DocumentUI object
