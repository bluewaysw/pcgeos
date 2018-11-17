##############################################################################
#
#	Copyright (c) Geoworks 1990-1994 -- All Rights Reserved
#
# PROJECT:	GEOS
# MODULE:	DocUI (Sample GEOS application)
# FILE:		docui.gp
#
# AUTHOR:	Tony Requist
#
# DESCRIPTION:	This file contains Geode definitions for the "DocUI" sample
#		application. This file is read by the GLUE linker to
#		build this application.
#
# RCS STAMP:
#	$Id: docui.gp,v 1.1 97/04/04 16:33:08 newdeal Exp $
#
##############################################################################
#
name docui.app
#
longname "DocUI"
#
type	appl, process
#
class	DUIProcessClass
#
appobj	DUIApp
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
export DUIDocumentClass
