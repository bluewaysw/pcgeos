##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Circles
# FILE:		circles.gp
#
# AUTHOR:	Gene, 2/92
#
#
# Parameters file for: circles.geo
#
#	$Id: circles.gp,v 1.1 97/04/04 16:44:39 newdeal Exp $
#
##############################################################################

name circles.lib
type appl, process
longname "Circles"
tokenchars "SSAV"
tokenid 0
library saver
library ui
library geos
class CirclesProcessClass
appobj CirclesApp
export CirclesApplicationClass
