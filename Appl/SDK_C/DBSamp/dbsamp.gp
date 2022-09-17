##############################################################################
#
#	Copyright (c) Geoworks 1994 -- All Rights Reserved
#
# PROJECT:	GEOS
# MODULE:	DBSamp (Sample GEOS application)
# FILE:		dbsamp.gp
#
# AUTHOR:	David J. Noha, 3/94
#
# REVISION HISTORY:
#       Name    Date            Description
#       ----    ----            -----------
#       David  	3/94	        Initial version
#		RainerB	4/21/2022		Resource names adjusted for Watcom compatibility
#
# DESCRIPTION:	This file contains Geode definitions for the "DBSamp" sample
#		application. This file is read by the GLUE linker to
#		build this application.
#
# RCS STAMP:
#       $Id: dbsamp.gp,v 1.1 97/04/04 16:39:53 newdeal Exp $
#
##############################################################################

name     dbsamp.app
longname "C Database App"

type	appl, process, single
class	DBSampProcessClass
appobj	DBSampApp

tokenchars "SAMP"
tokenid    8

heapspace 4K

library	geos
library	ui
library ansic

resource AppResource ui-object
resource Interface   ui-object

