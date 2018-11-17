##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Double-Scan CGA Video Driver
# FILE:		dscga.gp
#
# AUTHOR:	Don Reeves, Sep 27, 1993
#
# Parameters for DSCGA.GEO
#
#	$Id: dscga.gp,v 1.1 97/04/18 11:43:24 newdeal Exp $
#
##############################################################################
#
#
# Specify permanent name first
#
name	dscga.drvr
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
longname	"Double-Scan CGA"
tokenchars	"VIDD"
tokenid		0
#
# declare our extended info block specially
#
resource VideoDevices	lmem, shared, read-only, conforming
