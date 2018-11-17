##############################################################################
#
#	Copyright (c) Geoworks 1990-1994 -- All Rights Reserved
#
# PROJECT:	GEOS
# MODULE:	DupGrObj (Sample GEOS application)
# FILE:		dupgrobj.gp
#
# AUTHOR:	Tony Requist
#
# DESCRIPTION:	This file contains Geode definitions for the "IGrObj" sample
#		application. This file is read by the GLUE linker to
#		build this application.
#
# RCS STAMP:
#	$Id: dupgrobj.gp,v 1.1 97/04/04 16:33:35 newdeal Exp $
#
##############################################################################
#
name dupgrobj.app
#
longname "DupGrObj"
#
type	appl, process
#
class	DGProcessClass
#
appobj	DGApp
#
# This token must match both the token in the GenApplication and the token
# in the GenDocumentControl.
#
tokenchars "SAMP"
tokenid 8
#
#Once documents have been created the order of these libraries must
#not change and any new libraries must be added at the end. Otherwise
#unrelocated class information in the documents will be invalidated.
#
library	geos
library	ui
library grobj
#
resource AppResource ui-object
resource Interface ui-object
resource DisplayUI ui-object
resource DocumentUI object
resource Head object
resource BodyGOAMRuler object

#
# Exported entry points
#
export DGDocumentClass
