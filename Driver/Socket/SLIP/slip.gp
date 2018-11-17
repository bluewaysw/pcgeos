##############################################################################
#
#	Copyright (c) Geoworks 1994 -- All Rights Reserved
#
#			GEOWORKS CONFIDENTIAL
#
# PROJECT:	PC GEOS
# FILE:		slip.gp
#
# AUTHOR:	Jennifer Wu, Sep  9, 1994
#
#	$Id: slip.gp,v 1.1 97/04/18 11:57:19 newdeal Exp $
#
##############################################################################
#
name 		slip.drvr

#
type		driver, single

#
longname 	"SLIP Driver"
tokenchars	"SLIP"
tokenid		0


#
library	geos
library	netutils

#
# Resources: list all resource blocks which are used by the application.
# (standard discardable code resources can be ommitted).
#
resource ResidentCode	fixed code
resource Strings	shared lmem read-only 
resource SlipClassStructures	fixed read-only shared


