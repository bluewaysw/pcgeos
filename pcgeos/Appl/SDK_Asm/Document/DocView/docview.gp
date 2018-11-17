##############################################################################
#
#	Copyright (c) Geoworks 1990-1994 -- All Rights Reserved
#
# PROJECT:	GEOS
# MODULE:	DocView (Sample GEOS application)
# FILE:		docview.gp
#
# AUTHOR:	Tony Requist
#
# DESCRIPTION:	This file contains Geode definitions for the "DocView" sample
#		application. This file is read by the GLUE linker to
#		build this application.
#
# RCS STAMP:
#	$Id: docview.gp,v 1.1 97/04/04 16:32:59 newdeal Exp $
#
##############################################################################
#
name docview.app
#
longname "DocView"
#
type	appl, process
#
class	DVProcessClass
#
appobj	DVApp
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
export DVDocumentClass
