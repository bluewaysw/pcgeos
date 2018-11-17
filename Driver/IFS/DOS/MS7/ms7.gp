##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	
# FILE:		ms4.gp
#
# AUTHOR:	Adam de Boor, Mar 19, 1992
#
#
# 
#
#	$Id: ms7.gp,v 1.1 97/04/10 11:55:37 newdeal Exp $
#
##############################################################################
#
name ms7.ifsd
type driver, single system
library geos

#
# Desktop-related things
#
longname "MS DOS 7.X IFS Driver"
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
resource Strings 		fixed lmem read-only shared 
#
# XIP-enabled
#

