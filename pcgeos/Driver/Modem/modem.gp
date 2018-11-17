##############################################################################
#
#	Copyright (c) Geoworks 1995 -- All Rights Reserved
#
#			GEOWORKS CONFIDENTIAL
#
# PROJECT:	Modem Driver
# FILE:		modem.gp
#
# AUTHOR:	Jennifer Wu, Mar 14, 1995
#
# DESCRIPTION:
#		Parameters file for modem.geo
#
#	$Id: modem.gp,v 1.1 97/04/18 11:47:53 newdeal Exp $
#
##############################################################################
#
# Geode's permanent name
#
name 	modem.drvr

#
# Type of geode
#
type	driver, single, discardable-dgroup

#
# Filesystem information
#
longname 	"Modem Driver"
tokenchars	"MODM"
tokenid		0


#
# Libraries used
#
library	geos


#
# Define resources other than standard discardable code
#
resource ResidentCode 		fixed code read-only shared
resource ModemClassStructures	fixed read-only shared

#
# export classes
#
export ModemProcessClass


#
# Exported routines
#
export ModemStrategy

# To allow fixes since sales release to be installed:
incminor
