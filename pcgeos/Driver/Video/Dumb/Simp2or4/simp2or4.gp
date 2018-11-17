##############################################################################
#
#	Copyright (c) Geoworks 1997.  All rights reserved.
#	GEOWORKS CONFIDENTIAL
#
# PROJECT:	Video Drivers
# FILE:		simp2or4.gp
#
# AUTHOR:	Eric Weber, Feb 12, 1997
#
#
# 
#
#	$Id: simp2or4.gp,v 1.1 97/04/18 11:43:57 newdeal Exp $
#
##############################################################################
#
#
# Specify permanent name first
#
name	simp2or4.drvr
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
longname	"Simple 2 or 4 bit driver"
tokenchars	"VD24"
tokenid		0

#
# declare our extended info block specially
#
resource VideoDevices	lmem, shared, read-only, conforming
