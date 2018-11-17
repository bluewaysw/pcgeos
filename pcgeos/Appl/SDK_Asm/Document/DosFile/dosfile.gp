##############################################################################
#
#	Copyright (c) Geoworks 1990-1994 -- All Rights Reserved
#
# PROJECT:	GEOS
# MODULE:	DosFile (Sample GEOS application)
# FILE:		dosfile.gp
#
# AUTHOR:	Tony Requist
#
# DESCRIPTION:	This file contains Geode definitions for the "DosFile" sample
#		application. This file is read by the GLUE linker to
#		build this application.
#
# RCS STAMP:
#	$Id: dosfile.gp,v 1.1 97/04/04 16:33:26 newdeal Exp $
#
##############################################################################
#
name dosfile.app
#
longname "DosFile"
#
type	appl, process
#
class	DFProcessClass
#
appobj	DFApp
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
export DFDocumentClass
