##############################################################################
#
#	Copyright (c) Geoworks 1996.  All rights reserved.
#	GEOWORKS CONFIDENTIAL
#
# PROJECT:	PC GEOS
# FILE:		simp2bit.gp
#
# AUTHOR:	Joon Song, Oct 7, 1996
#
#
# Parameters file for: simp2bit.geo
#
#	$Id: simp2bit.gp,v 1.1 97/04/18 11:43:50 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	simp2bit.drvr
#
# Specify geode type
#
type	driver, single, system
#
# Import kernel routine definitions
#
library	geos
#
# Desktop-related things
#
longname	"Simple 4-Color Driver"
tokenchars	"VIDD"
tokenid		0
#
# declare our extended info block specially
#
resource VideoDevices	lmem, shared, read-only, conforming
resource VideoBitmap 	read-only, code, fixed
