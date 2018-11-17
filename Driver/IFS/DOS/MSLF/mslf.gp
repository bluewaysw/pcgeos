##############################################################################
#
#	Copyright (c) GlobalPC 1999.  All rights reserved.
#	GLOBALPC CONFIDENTIAL
#
# PROJECT:	Global PC
# FILE:		mslf.gp
#
# AUTHOR:	Allen Yuen, Jan 21, 1999
#
#
# 
#
#	$Id$
#
##############################################################################
#
name mslf.ifsd
type driver, single system
library geos

#
# Desktop-related things
#
longname "MS DOS Longname IFS Driver"
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

