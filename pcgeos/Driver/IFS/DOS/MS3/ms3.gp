##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	
# FILE:		ms3.gp
#
# AUTHOR:	Adam de Boor, Mar 19, 1992
#
#
# 
#
#	$Id: ms3.gp,v 1.1 97/04/10 11:54:57 newdeal Exp $
#
##############################################################################
#
name ms3.ifsd
type driver, single system
library geos

#
# Desktop-related things
#
longname "MS DOS 3.X IFS Driver"
tokenchars "IFSD"
tokenid 0

#
# Special resource definitions
#
ifdef GP_FULL_EXECUTE_IN_PLACE
resource Resident 		code shared read-only
resource ResidentXIP		fixed code shared read-only
else
resource Resident 		fixed code shared read-only
endif
resource DriverExtendedInfo 	lmem shared read-only
resource Strings 		lmem read-only shared fixed
#
# XIP-enabled
#








