##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	
# FILE:		os2.gp
#
# AUTHOR:	Adam de Boor, Mar 19, 1992
#
#
# 
#
#	$Id: os2.gp,v 1.1 97/04/10 11:55:19 newdeal Exp $
#
##############################################################################
#
name os2.ifsd
type driver, single system
library geos

#
# Desktop-related things
#
longname "OS/2 2.0 IFS Driver"
tokenchars "IFSD"
tokenid 0

#
# Special resource definitions
#
ifdef GP_FULL_EXECUTE_IN_PLACE
resource Resident 		code shared read-only
resource ResidentXIP		fixed code shared read-only
else
resource Resident               fixed code shared read-only
endif
resource DriverExtendedInfo     lmem shared read-only
resource Strings                lmem read-only shared fixed
#
# XIP-enabled
#
