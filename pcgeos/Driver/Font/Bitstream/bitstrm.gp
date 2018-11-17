##############################################################################
#
#	Copyright (c) GeoWorks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Nimbus Font Driver
# FILE:		bitstream.gp
#
# AUTHOR:	Brian Chin
#
#
# Parameters file for: bitstrm.geo
#
#	$Id: bitstrm.gp,v 1.1 97/04/18 11:45:12 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	bitstrm.drvr
#
# Specify geode type
#
type	driver, single
#
# Import kernel routine definitions
#
library	geos
# "library ansic" if PROC_TRUETYPE or PROC_TYPE1
#library ansic
# "library math" if PROC_TRUETYPE or PROC_TYPE1
#library math
# "library ui" if PROC_TRUETYPE
#library ui
#
# Desktop-related things
#
longname	"Bitstream Drv"
tokenchars	"FNTD"
tokenid		0
#usernotes	"Bitstream"
#
# Define resources other than standard discardable code
#
resource Resident fixed code read-only shared
resource InitMod code read-only shared discard-only
resource SysNotifyStrings shared lmem read-only
resource MathLong fixed code read-only shared
