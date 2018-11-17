##############################################################################
#
#	Copyright (c) GeoWorks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	RFSD (Remote File System Driver)
# FILE:		rfsd.gp
#
# AUTHOR:	Insik, 4/92
#
#
# Parameters file for: rfsd.geo
#
#	$Id: rfsd.gp,v 1.1 97/04/18 11:46:18 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	rfsd.ifsd
#
# Specify geode type
#
type	driver, single system
#
# Import kernel routine definitions
#
library	geos
library net
library ui noload
#
# Desktop-related things
#
longname	"Remote FS Driver"
tokenchars	"RFSD"
tokenid		0
#
# Define resources other than standard discardable code
#
resource Resident		fixed code read-only shared
resource DriverExtendedInfo	lmem shared read-only
resource Strings		lmem shared read-only
#
# Exported classes/routines
#
class	DispatchProcessClass
export	DispatchProcessClass


