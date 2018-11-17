##############################################################################
#
#	Copyright (c) Geoworks 1990-1994 -- All Rights Reserved
#
# PROJECT:	GEOS
# MODULE:	SharedDB (Sample GEOS application)
# FILE:		shareddb.gp
#
# AUTHOR:	Tony Requist
#
# DESCRIPTION:	This file contains Geode definitions for the "SharedDB" sample
#		application. This file is read by the GLUE linker to
#		build this application.
#
# RCS STAMP:
#	$Id: shareddb.gp,v 1.1 97/04/04 16:33:18 newdeal Exp $
#
##############################################################################
#
name shareddb.app
#
longname "SharedDB"
#
type	appl, process
#
class	SDBProcessClass
#
appobj	SDBApp
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
resource MessageStrings lmem read-only shared
resource DocumentUI object
#
# Exported entry points
#
export SDBDocumentClass
