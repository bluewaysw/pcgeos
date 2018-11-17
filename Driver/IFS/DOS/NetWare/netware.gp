##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	
# FILE:		netware.gp
#
# AUTHOR:	Adam de Boor, Mar 29, 1992
#
#
# 
#
#	$Id: netware.gp,v 1.1 97/04/10 11:55:14 newdeal Exp $
#
##############################################################################
#
name netware.ifsd
type driver, single system
library geos

#
# Desktop-related things
#
longname "NetWare IFS Driver"
tokenchars "IFSD"
tokenid 0

#
# Special resource definitions
#
resource Resident fixed code shared read-only
resource Init code read-only shared discard-only
resource DriverExtendedInfo lmem shared read-only
#resource Strings lmem read-only shared fixed
#
# XIP-enabled
#


