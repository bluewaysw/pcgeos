##############################################################################
#
#	Copyright (c) GeoWorks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Network Stream Driver
# FILE:		netstr.gp
#
# AUTHOR:	Chris Boyke
#
#	$Id: netstr.gp,v 1.1 97/04/18 11:46:04 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	netstr.drvr
#
# Specify geode type
#
type	driver, single
#
# Import kernel routine definitions
#
library	geos
driver stream
driver parallel

#
# Desktop-related things
#

longname	"Network Stream Driver"
tokenchars	"NSTR"
tokenid		0

#
# Define resources other than standard discardable code
#

resource Resident fixed code read-only shared

#
# Exported routines
#

#
# XIP-enabled
#
