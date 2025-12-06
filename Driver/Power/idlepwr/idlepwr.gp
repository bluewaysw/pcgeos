##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	IdlePower power management driver
# FILE:		IdlePower.gp
#
# AUTHOR:	Tony Requist, 4/22/93
#
# DESCRIPTION:	Contains the geode definitions
#
#	$Id: IdlePower.gp,v 1.1 97/04/18 11:48:16 newdeal Exp $
#
##############################################################################
#
name idlepwr.drvr
#
longname "Idle Power Management Driver"
#
type	driver, single, system
#
tokenchars "PWRD"
tokenid 0
#
library	geos
library ui noload
#library pcmcia noload
#
# Resident (fixed) code
#
resource Resident fixed code read-only shared
#
# Strings
#
resource StringsUI lmem read-only shared
