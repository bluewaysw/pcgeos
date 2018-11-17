##############################################################################
#
#	Copyright (c) Geoworks 1994 -- All Rights Reserved
#
# PROJECT:	Circle
# FILE:		circle.gp
#
# AUTHOR:	David Litwin, Jun 13, 1994
#
#	.gp file for the Circle
# 
#
#	$Id: circle.gp,v 1.1 97/04/04 16:35:19 newdeal Exp $
#
##############################################################################
#
name circle.app

longname "Circle"

type	appl, process

class	CircleProcessClass

appobj	CircleApp

tokenchars "CIRC"
tokenid 0

library	geos
library	ui

resource AppResource ui-object
resource Interface ui-object
resource AppObjects object

export CircleProcessClass
export CircleClass
