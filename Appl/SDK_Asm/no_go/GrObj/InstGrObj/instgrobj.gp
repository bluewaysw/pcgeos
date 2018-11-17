##############################################################################
#
#	Copyright (c) GeoWorks 1990 -- All Rights Reserved
#
# PROJECT:	PC/GEOS
# MODULE:	InstGrObj (Sample PC/GEOS application)
# FILE:		instgrobj.gp
#
# AUTHOR:	Tony Requist
#
# DESCRIPTION:	This file contains Geode definitions for the "IGrObj" sample
#		application. This file is read by the GLUE linker to
#		build this application.
#
# RCS STAMP:
#	$Id: instgrobj.gp,v 1.1 97/04/04 16:35:13 newdeal Exp $
#
##############################################################################
#
name instgrobj.app
#
longname "InstGrObj"
#
type	appl, process
#
class	IGProcessClass
#
appobj	IGApp
#
# This token must match both the token in the GenApplication and the token
# in the GenDocumentControl.
#
tokenchars "IGss"
tokenid 0
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
#
# Exported entry points
#
export IGDocumentClass
