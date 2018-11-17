##############################################################################
#
#	Copyright (c) Geoworks 1994 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# FILE:		alpspen.gp
#
# AUTHOR:	Jim Guggemos, Dec  6, 1994
#
#
# Parameters file for alpspen.geo
#
#	$Id: alpspen.gp,v 1.1 97/04/18 11:48:08 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	alpspen.drvr
#
# Specify geode type
#
type	driver, single
#
# Import kernel routine definitions
#
library	geos
#
# Desktop-related things
#
longname 	"Alps Pen Driver"
tokenchars 	"MOUS"
tokenid 	0
#
# Define resources other than standard discardable code
#
resource Resident fixed shared code read-only
resource MouseExtendedInfoSeg lmem, read-only, shared, conforming
