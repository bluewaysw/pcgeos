##############################################################################
#
#	Copyright (c) GeoWorks 1993 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	
# FILE:		file.gp
#
# AUTHOR:	Adam de Boor, April 14, 1993
#
#
# 
#
#	$Id: megafile.gp,v 1.1 97/04/18 11:46:32 newdeal Exp $
#
##############################################################################
#
name megafile.ifsd
type driver, single system
library geos

#
# Desktop-related things
#
longname "Megafile IFS Driver"
tokenchars "IFSD"
tokenid 0

#
# Special resource definitions
#
resource Resident fixed code shared read-only
resource DriverExtendedInfo lmem shared read-only
#resource Strings lmem read-only shared fixed
resource Init code read-only shared discard-only
