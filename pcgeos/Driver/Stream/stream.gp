##############################################################################
#
#	Copyright (c) GeoWorks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Stream Driver
# FILE:		stream.gp
#
# AUTHOR:	Adam, 1/90
#
#
# Parameters file for: stream.geo
#
#	$Id: stream.gp,v 1.1 97/04/18 11:46:05 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	stream.drvr
#
# Specify geode type
#
type	driver, single
#
# Import kernel routine definitions
#
library	geos
#
# Desktop-related things
#
longname	"Stream Driver"
tokenchars	"STRD"
tokenid		0
#
# Define resources other than standard discardable code
#
resource Resident fixed code read-only shared
#
# Exported routines
#
export	StreamNotify
export	StreamStrategy
export	StreamWriteDataNotify
export	StreamReadDataNotify

incminor

export	StreamShutdown
export	StreamFree
#
# XIP-enabled
#
