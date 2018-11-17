##############################################################################
#
#	Copyright (c) Geoworks 1994 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Test Printer Driver
# FILE:		test.gp
#
# AUTHOR:	Don Reeves, July 10, 1994
#
# Parameters file for: Test Printer Driver
#
#	$Id: test.gp,v 1.1 97/04/18 11:52:31 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	testprdr.drvr
#
# Long name
#
longname "Test Printer Driver"
#
# DB Token
#
tokenchars "PRDR"
tokenid 0
#
#
# Specify geode type
#
type	driver, single
#
# Import kernel routine definitions
#
library	geos
library ui
library	spool
#
# Make this module fixed so we can put the strategy routine there
#
resource Entry fixed code read-only shared
#
# Make driver info resource accessible from user-level processes
#
resource DriverInfo 	lmem, data, shared, read-only, conforming
resource testInfo 	data, shared, read-only, conforming
#
# Exported classes
#
export TestTextClass	
export TestControlClass
