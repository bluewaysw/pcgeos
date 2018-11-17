##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#	Copyright (c) New Deal 1998 -- All Rights Reserved
#
# PROJECT:	
# MODULE:	
# FILE:		ntfat.gp
#
# AUTHOR:	Gene, Janunary 23, 1998
#
#
# 
#
#	$Id: ntfat.gp,v 1.1 98/01/24 23:13:05 gene Exp $
#
##############################################################################
#
name ntfat.ifsd
type driver, single system
library geos

#
# Desktop-related things
#
longname "NT 4.0 FAT IFS Driver"
tokenchars "IFSD"
tokenid 0

#
# Special resource definitions
#
resource Resident               fixed code shared read-only
resource DriverExtendedInfo     lmem shared read-only
resource Strings                lmem read-only shared fixed
