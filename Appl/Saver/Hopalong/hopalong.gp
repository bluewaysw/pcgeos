##############################################################################
#
#	Copyright (c) GeoWorks 1994 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	hopalong.geo
# FILE:		hopalong.gp
#
# AUTHOR:	David Loftesness: 2/11/94
#
#
# Parameters file for: hopalong.geo
#
#	$Id: hopalong.gp,v 1.1 97/04/04 16:45:06 newdeal Exp $
#
##############################################################################

name hopalong.lib
type appl, process, single
longname "Hopalong"
tokenchars "SSAV"
tokenid 0
library saver
library ui
library geos
library math
class  HopalongProcessClass
appobj HopalongApp
export HopalongApplicationClass
