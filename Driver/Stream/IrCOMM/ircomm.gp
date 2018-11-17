##############################################################################
#
#	Copyright (c) Geoworks 1995 -- All Rights Reserved
#
# PROJECT:	GEOS
# MODULE:	IrCOMM
# FILE:		ircomm.gp
#
# AUTHOR:	Greg Grisco, Dec  4, 1995
#
#
# Parameters file for ircomm.geo
#
#	$Id: ircomm.gp,v 1.1 97/04/18 11:46:14 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	ircomm.drvr
#
# Specify geode type
#
type	driver, single, discardable-dgroup
#
# Import kernel routine definitions
#
library	geos
driver	stream
library	netutils
library	irlmp
#
# Desktop-related things
#
longname	"IrCOMM Driver"
tokenchars	"IRCM"
tokenid		0
#
# Define resources other than standard discardable code
#
resource ResidentCode 		fixed code read-only shared
resource IrCommClassStructure	fixed read-only shared
#
# Exported classes
#
export	IrCommProcessClass
