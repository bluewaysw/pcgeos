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
# REVISION HISTORY:
#       Name    Date            Description
#       ----    ----            -----------
#       EB   	7/96	        Initial version
#		RainerB	4/21/2022		Resource names adjusted for Watcom compatibility
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
resource AppResource object
resource Interface object
resource DoggyBitmap data read-only

#
# new classes must be exported.  
#
export DoggyClass
