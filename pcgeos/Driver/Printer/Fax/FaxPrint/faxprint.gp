##############################################################################
#
#	Copyright (c) Geoworks 1994.  All rights reserved.
#	GEOWORKS CONFIDENTIAL
#
# PROJECT:	Tiramisu
# FILE:		faxprint.gp
#
# AUTHOR:	Jacob Gabrielson, Mar 10, 1993
#		Jeremy Dashe, Oct 7, 1994
#
#	$Id: faxprint.gp,v 1.1 97/04/18 11:53:02 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name    faxprint.drvr

#
# Long name
#
longname "Fax Print Driver"

#
# DB Token
#
tokenchars "FXDR"
tokenid 0

#
#
# Specify geode type
#
type    driver, single

#
#  Heapspace.  Set low to get around a system bug in calculating
#  the heapspace for libraries.
#
heapspace 1

#
# Import kernel routine definitions
#
library geos
library spool
library	faxfile


#
# Make this module fixed so we can put the strategy routine there
#
resource Entry 		fixed code read-only shared

#
# Make driver info resource accessible from user-level processes
#
resource DriverInfo     lmem, data, shared, read-only, conforming
resource DeviceInfo     data, shared, read-only, conforming

#
# UI resources
#
resource 	StringBlock	lmem, data, read-only, shared

#
# Exported classes and routines
#
