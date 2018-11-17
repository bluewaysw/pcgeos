##############################################################################
#
#	Copyright (c) GlobalPC 1998 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Video Driver
# FILE:		cyber16.gp
#
# AUTHOR:	Jim, 10/92
#
# Parameters file for: cyber16.geo
#
#	$Id: cyber16.gp,v 1.2$
#
##############################################################################
#
# Specify permanent name first
#
name    cyber16.drvr
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
longname        "IGS CyberPro 64K-color Driver"
tokenchars	"VIDD"
tokenid		0
#
# declare our extended info block specially
#
resource VideoDevices   lmem, shared, read-only, conforming
