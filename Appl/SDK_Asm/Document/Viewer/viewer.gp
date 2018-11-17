##############################################################################
#
#	Copyright (c) Geoworks 1990-1994 -- All Rights Reserved
#
# PROJECT:	GEOS
# MODULE:	Viewer (Sample GEOS application)
# FILE:		viewer.gp
#
# AUTHOR:	Tony Requist
#
# DESCRIPTION:	This file contains Geode definitions for the "Viewer" sample
#		application. This file is read by the GLUE linker to
#		build this application.
#
# RCS STAMP:
#	$Id: viewer.gp,v 1.1 97/04/04 16:33:13 newdeal Exp $
#
##############################################################################
#
name viewer.app
#
longname "Viewer"
#
type	appl, process
#
class	VProcessClass
#
appobj	VApp
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
#
# Exported entry points
#
export VDocumentClass
