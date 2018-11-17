##############################################################################
#
#	Copyright (c) GeoWorks 1991 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	
# FILE:		noodle.gp
#
#
#
# Parameters file for: stars.geo
#
#	$Id: noodle.gp,v 1.1 97/04/04 16:46:13 newdeal Exp $
#
##############################################################################
name noodle.lib
type appl, process, single
longname "Noodle"
tokenchars "SSAV"
tokenid 0
library saver
library ui
library geos
class NoodleProcessClass
appobj NoodleApp
export NoodleApplicationClass
