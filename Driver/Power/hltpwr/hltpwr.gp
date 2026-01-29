##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	HLT Power Management Driver
# FILE:		hltpwr.gp
#
# AUTHOR:	MeyerK 12/2025
#
# DESCRIPTION:	Contains the geode definitions
#
#
##############################################################################

#
# Name and Type
#
name hltpwr.drvr
longname "HLT Power Management Driver"
type	driver, single, system

#
# Token
#
tokenchars "PWRD"
tokenid 0

#
# Libs
#
library	geos

#
# Resident (fixed) code
#
resource Resident fixed code read-only shared
