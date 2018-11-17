##############################################################################
#
#	Copyright (c) GeoWorks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Parallel Driver
# FILE:		parallel.gp
#
# AUTHOR:	Adam, 2/90
#
#
# Parameters file for: parallel.geo
#
#	$Id: parallel.gp,v 1.1 97/04/18 11:46:04 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	parallel.drvr
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
longname	"Parallel Driver"
tokenchars	"STRD"
tokenid		0
#
# Define resources other than standard discardable code
#
resource Resident fixed code read-only shared
#
# Exported routines
#
export ParallelStrategy

#
# XIP-enabled
#
