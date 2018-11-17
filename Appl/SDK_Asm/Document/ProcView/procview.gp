##############################################################################
#
#	Copyright (c) Geoworks 1990-1994 -- All Rights Reserved
#
# PROJECT:	GEOS
# MODULE:	ProcView (Sample GEOS application)
# FILE:		procview.gp
#
# AUTHOR:	Tony Requist
#
# DESCRIPTION:	This file contains Geode definitions for the "ProcView" sample
#		application. This file is read by the GLUE linker to
#		build this application.
#
# RCS STAMP:
#	$Id: procview.gp,v 1.1 97/04/04 16:32:57 newdeal Exp $
#
##############################################################################
#
name procview.app
#
longname "ProcView"
#
type	appl, process
#
class	PVProcessClass
#
appobj	PVApp
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
