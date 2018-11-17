##############################################################################
#
#	Copyright (c) Designs in Light, 2000 -- All Rights Reserved
#
# PROJECT:	APM
# FILE:		apmpwr.gp
#
# AUTHOR:	Gene Anderson
#
#	This is the basic APM power driver module
#
#	$Id$
#
##############################################################################
#
name apm11.drvr
#
longname "APM 1.1 Power Management"
#
type	driver, single, system
#
tokenchars "PWRD"
tokenid 0
#
library	geos
library	ui	noload

#
resource Resident	fixed code read-only shared

# Minor Protocol increase for additional BIOS password routines
incminor	PowerPasswordStuff

