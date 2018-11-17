##############################################################################
#
#	Copyright (c) GeoWorks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	ATT6300 video driver
# FILE:		att6300.gp
#
# AUTHOR:	Adam, 10/89
#
#
# Parameters file for: att6300.geo
#
#	$Id: att6300.gp,v 1.1 97/04/18 11:42:37 newdeal Exp $
#
##############################################################################
#
#
# Specify permanent name first
#
name	att6300.drvr
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
ifdef WIN32
longname	"NT VDD 640x480 -color"
else
longname      "ATT6300 Monochrome Driver"
endif
tokenchars	"VIDD"
tokenid		0
#
# declare our extended info block specially
#
resource VideoDevices	lmem, shared, read-only, conforming
