##############################################################################
#
#	Copyright (c) GeoWorks 1991 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	worm.geo
# FILE:		worm.gp
#
# AUTHOR:	Jeremy Dashe: 4/2/91
#
#
# Parameters file for: worms.geo
#
#	$Id: worms.gp,v 1.1 97/04/04 16:48:13 newdeal Exp $ 
#
##############################################################################

name worms.lib
type appl, process, single
longname "Worms"
tokenchars "SSAV"
tokenid 0
library saver
library ui
library geos
class  WormsProcessClass
appobj WormsApp
export WormsApplicationClass
