##############################################################################
#
#	Copyright (c) GeoWorks 1991 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	
# FILE:		dri.gp
#
# AUTHOR:	Adam de Boor, Oct 31, 1991
#
#
# 
#
#	$Id: dri.gp,v 1.1 97/04/10 11:48:12 newdeal Exp $
#
##############################################################################
#
name dri.ifsd
type driver, single system
library geos

#
# Desktop-related things
#
longname "DR DOS IFS Driver"
tokenchars "IFSD"
tokenid 0

#
# Special resource definitions
#
resource Resident fixed code shared read-only
resource DriverExtendedInfo lmem shared read-only
resource Strings lmem read-only shared fixed
resource Init code read-only shared discard-only
