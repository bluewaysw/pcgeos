##############################################################################
#
#	Copyright (c) Geoworks 1994 -- All Rights Reserved
#
# PROJECT:	
# MODULE:	Geode Parameters
# FILE:		pgfs.gp
#
# AUTHOR:	Adam de Boor, Oct  4, 1993
#
#
# 
#
#	$Id: pgfs.gp,v 1.1 97/04/18 11:46:39 newdeal Exp $
#
##############################################################################
#

name pgfs.drvr

type driver, system, single

longname "PCMCIA GFS Driver"

tokenchars "PCMD"

tokenid 0

library geos
library pcmcia

resource Resident fixed code shared read-only
