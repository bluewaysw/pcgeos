##############################################################################
#
#	Copyright (c) GeoWorks 1993 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	File Systems
# FILE:		cvgfs.gp
#
# AUTHOR:	Adam de Boor, April 14, 1993
#
# REVISION HISTORY:
#	Name	Date	Description
#	----	----	-----------
#	cassie	6/29/93	adapted for Bullet
#	todd	9/12/94 made generic for all Vadem Platforms
#	Joon	1/19/96	Adapted for compressed GFS
#
#	$Id: cvgfs.gp,v 1.1 97/04/18 11:46:47 newdeal Exp $
#
##############################################################################
#
name cvgfs.ifsd
type driver, single system
library geos

#
# Desktop-related things
#
longname "Compressed ROM IFS Driver"
tokenchars "CFSD"
tokenid 0

#
# Special resource definitions
#
resource Resident fixed code shared read-only
resource Init code shared read-only discard-only
resource DriverExtendedInfo lmem shared read-only
