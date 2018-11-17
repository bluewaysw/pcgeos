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
#	$Id: irport.gp,v 1.1 97/04/18 11:46:08 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	irport.drvr
#
# Specify geode type
#
type	driver, single, discardable-dgroup
#
# Import kernel routine definitions
#
library	geos
driver	stream
library netutils
library irlmp
#
# Desktop-related things
#
longname	"IR Port Driver"
tokenchars	"STRD"
tokenid		0
#
# Define resources other than standard discardable code
#
resource Resident fixed code read-only shared

#
# XIP-enabled
#



