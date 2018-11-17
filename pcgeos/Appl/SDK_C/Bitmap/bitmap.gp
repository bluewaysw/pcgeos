##############################################################################
#
#	Copyright (c) Geoworks 1996 -- All Rights Reserved
#
# PROJECT:	GEOS
# MODULE:	Bitmap (Sample GEOS application)
# FILE:		bitmap.gp
#
# AUTHOR:	Ed Ballot, 7/96
#
# DESCRIPTION:	Your basic GP file for the bitmap sample application
#
# RCS STAMP:
#	$Id: bitmap.gp,v 1.1 97/04/04 16:41:25 newdeal Exp $
#
##############################################################################
#
name bmpsamp.app
#
longname "Bitmap Sample"
#
tokenchars "DBMP"
tokenid 8
#
type	appl, process, single
#
class	BitmapProcessClass
#
appobj	BitmapApp
#
heapspace 2K
#
library	geos
library	ui
library math
#
resource APPRESOURCE object
resource INTERFACE object
resource DOGGYBITMAP data read-only

#
# new classes must be exported.  
#
export DoggyClass
