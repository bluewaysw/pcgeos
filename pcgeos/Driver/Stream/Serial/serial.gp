##############################################################################
#
#	Copyright (c) GeoWorks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Serial Driver
# FILE:		serial.gp
#
# AUTHOR:	Adam, 2/90
#
#
# Parameters file for: serial.geo
#
#	$Id: serial.gp,v 1.1 97/04/18 11:46:02 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	serial.drvr
#
# Specify geode type
#
type	driver, single, discardable-dgroup
#
# Import kernel routine definitions
#
library	geos
driver	stream


#
# Desktop-related things
#
longname	"Serial Driver"
tokenchars	"STRD"
tokenid		0
#
# Define resources other than standard discardable code
#
resource Resident fixed code read-only shared
#
# Exported routines
#
incminor	SerialPCMCIASupport
incminor	SerialPassivePortSupport
incminor	SerialMediumSupport
incminor	SerialResizeSupport
incminor	SerialRoleSupport
#
# XIP-enabled
#
