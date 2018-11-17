##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	
# FILE:		cdrom.gp
#
# AUTHOR:	Adam de Boor, Mar 29, 1992
#
#
# 
#
#	$Id: cdrom.gp,v 1.1 97/04/10 11:55:21 newdeal Exp $
#
##############################################################################
#
name cdrom.ifsd
type driver, single system
library geos

#
# Desktop-related things
#
longname "CD-ROM IFS Driver"
tokenchars "IFSD"
tokenid 0

#
# Special resource definitions
#
resource Resident fixed code shared read-only
resource Init code read-only shared discard-only
resource DriverExtendedInfo lmem shared read-only
#resource Strings lmem read-only shared fixed
