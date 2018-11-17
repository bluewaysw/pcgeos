##############################################################################
#
#	Copyright (c) GeoWorks 1994 -- All Rights Reserved
#
# PROJECT:	
# MODULE:	Geode Parameters
# FILE:		spooltd.gp
#
# AUTHOR:	Adam de Boor, Oct 27, 1994
#
#
# 
#
#	$Id: spooltd.gp,v 1.1 97/04/18 11:40:56 newdeal Exp $
#
##############################################################################
#
name spooltd.drvr
type driver, single, discardable-dgroup

longname "Print Spool Transport"
tokenchars "MBTD"
tokenid 0

library geos
library ui
library mailbox


resource Resident	fixed code shared read-only
resource ROStrings	lmem shared read-only
resource ifdef ControlInfoXIP shared data read-only
resource ifdef Bitmaps lmem shared read-only

