##############################################################################
#
#	Copyright (c) GeoWorks 1993 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	File stream driver
# FILE:		filestr.gp
#
# AUTHOR:	Jim, 1/93
#
#
# Parameters file for: filestr.geo
#
#	$Id: filestr.gp,v 1.1 97/04/18 11:46:07 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	filestr.drvr
#
# Specify geode type
#
type	driver, single
#
# Import kernel routine definitions
#
library	geos
driver	stream
#
# Desktop-related things
#
longname	"File Stream Driver"
tokenchars	"STRD"
tokenid		0
#
# Define resources other than standard discardable code
#
resource Resident fixed code read-only shared
#
# Exported routines
#
export FilestrStrategy

#
# XIP-enabled
#
