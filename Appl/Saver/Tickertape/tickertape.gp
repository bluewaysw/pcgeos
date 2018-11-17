##############################################################################
#
#	Copyright (c) GeoWorks 1991 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	tickertape.geo
# FILE:		tickertape.gp
#
# AUTHOR:	Jeremy Dashe: 10/1/91
#
#
# Parameters file for: tickertape.geo
#
#	$Id: tickertape.gp,v 1.1 97/04/04 16:47:45 newdeal Exp $
#
##############################################################################

name tickertape.lib
type appl, process
longname "Ticker Tape"
tokenchars "SSAV"
tokenid 0
library saver
library ui
library geos
class	TickertapeProcessClass
appobj	TickertapeApp
export	TickertapeApplicationClass
