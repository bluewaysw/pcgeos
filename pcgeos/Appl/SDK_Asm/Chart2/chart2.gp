##############################################################################
#
#	Copyright (c) Geoworks 1994 -- All Rights Reserved
#
# PROJECT:	Chart2
# FILE:		chart2.gp
#
# AUTHOR:	David Litwin, Jun 13, 1994
#
#	.gp file for the Chart2
# 
#
#	$Id: chart2.gp,v 1.1 97/04/04 16:35:15 newdeal Exp $
#
##############################################################################
#
name chart2.app

longname "Chart2"

type	appl, process

class	ChartProcessClass

appobj	ChartApp

tokenchars "CHT2"
tokenid 0

library	geos
library	ui

resource AppResource ui-object
resource Interface ui-object
resource AppObjects object

export ChartProcessClass
export ChartClass
