##############################################################################
#
#	Copyright (c) GeoWorks 1991 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	GeoCalc
# FILE:		geocal.gp
#
# AUTHOR:	Gene, 2/91
#
#
# Parameters file for: stars.geo
#
#	$Id: stars.gp,v 1.1 97/04/04 16:47:17 newdeal Exp $
#
##############################################################################

name stars.lib
type appl, process, single
longname "Stars"
tokenchars "SSAV"
tokenid 0
library saver
library ui
library geos

class  StarsProcessClass
appobj StarsApp
export StarsApplicationClass
