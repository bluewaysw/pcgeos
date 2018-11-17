##############################################################################
#
#	Copyright (c) GeoWorks 1990 -- All Rights Reserved
#
# PROJECT:	PC/GEOS
# MODULE:	CTEdit (Sample PC/GEOS application)
# FILE:		ctedit.gp
#
# AUTHOR:	Tony Requist
#
# DESCRIPTION:	This file contains Geode definitions for the "TEdit" sample
#		application. This file is read by the GLUE linker to
#		build this application.
#
# PORT TO GOC: 10/13/04 jfh
#
##############################################################################
#
name ctedit.app
#
longname "CText File Editor"
#
type	appl, process
#
class	TEProcessClass
#
appobj	TEApp
#
# This token must match both the token in the GenApplication and the token
# in the GenUIDocumentControl.
#
tokenchars "SAMP"
tokenid 0
heapspace	18785

# Increased stack size to 5K to fix bugs 27057/27058/27128 -atw (10/28/93)
stack 5000

#
library	geos
library	ui
library	text
library	spool
library	spell

#
resource APPLCMONIKERRESOURCE lmem read-only shared
resource APPSCMONIKERRESOURCE lmem read-only shared

resource APPRESOURCE object
resource INTERFACE object
resource DISPLAYUI object read-only shared
resource DOCUMENTUI object
resource STRINGSUI lmem read-only shared
#
# Exported entry points
#
export TEDocumentClass
export TELargeTextClass


