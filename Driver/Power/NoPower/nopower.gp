##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	NoPower power management driver
# FILE:		nopower.gp
#
# AUTHOR:	Tony Requist, 4/22/93
#
# DESCRIPTION:	Contains the geode definitions
#
#	$Id: nopower.gp,v 1.1 97/04/18 11:48:16 newdeal Exp $
#
##############################################################################
#
name nopower.drvr
#
longname "Empty Power Management Driver"
#
type	driver, single, system
#
tokenchars "PWRD"
tokenid 0
#
library	geos
library ui noload
library pcmcia noload
#
# Resident (fixed) code
#
resource Resident fixed code read-only shared
#
# Strings
#
resource StringsUI lmem read-only shared
