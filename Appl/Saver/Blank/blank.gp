##############################################################################
#
#	Copyright (c) GeoWorks 1991 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Blank
# FILE:		blank.gp
#
# AUTHOR:	Gene, 4/91
#
#
# Parameters file for: blank.geo
#
#	$Id: blank.gp,v 1.1 97/04/04 16:44:26 newdeal Exp $
#
##############################################################################

name blank.lib
type appl, process, single
longname "Blank"
tokenchars "SSAV"
tokenid 0
class BlankProcessClass
appobj BlankApp
library saver
library ui
library geos
