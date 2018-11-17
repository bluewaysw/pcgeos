##############################################################################
#
#	Copyright (c) Geoworks 1996.  All rights reserved.
#	GEOWORKS CONFIDENTIAL
#
# PROJECT:	UtilWin test app
# FILE:		utilwin.gp
#
# AUTHOR:	Brian Chin, Nov 27, 1996
#
#
# Geode parameters file for UtilWin test app.
#
#	$Id: utilwinr.gp,v 1.1 97/04/04 16:35:43 newdeal Exp $
#
##############################################################################
#
name utilwinr.app
longname "Util Win Read App"
tokenchars "UWNR"
tokenid 0

type	appl, process
class	UtilWinProcessClass
appobj	UtilWinAppObj

library geos
library ui

resource AppResource	ui-object
resource Interface	ui-object

