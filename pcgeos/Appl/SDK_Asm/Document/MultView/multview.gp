##############################################################################
#
#	Copyright (c) Geoworks 1990-1994 -- All Rights Reserved
#
# PROJECT:	GEOS
# MODULE:	MultView (Sample GEOS application)
# FILE:		multview.gp
#
# AUTHOR:	Tony Requist
#
# DESCRIPTION:	This file contains Geode definitions for the "MultView" sample
#		application. This file is read by the GLUE linker to
#		build this application.
#
# RCS STAMP:
#	$Id: multview.gp,v 1.1 97/04/04 16:33:11 newdeal Exp $
#
##############################################################################
#
name multview.app
#
longname "MultView"
#
type	appl, process
#
class	MVProcessClass
#
appobj	MVApp
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
resource DisplayUI ui-object
resource DocumentUI object
#
# Exported entry points
#
export MVDocumentClass
