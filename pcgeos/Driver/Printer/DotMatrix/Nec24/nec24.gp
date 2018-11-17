##############################################################################
#
#	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	NEC late model 24-pin Printer Driver
# FILE:		nec24.gp
#
# AUTHOR:	Dave, 3/92, from epshi24.gp
#
# Parameters file for: nec24.geo
#
#	$Id: nec24.gp,v 1.1 97/04/18 11:54:18 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	nec24.drvr
#
# Long name
#
longname "Late Model NEC 24-pin driver"
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
library	ui
library	spool
#
# Make this module fixed so we can put the strategy routine there
#
resource Entry fixed code read-only shared
#
# Make driver info resource accessible from user-level processes
#
resource DriverInfo 	lmem, data, shared, read-only, conforming
resource p2200Info 	data, shared, read-only, conforming
resource p3300Info 	data, shared, read-only, conforming
resource p6Info 	data, shared, read-only, conforming
resource p7Info 	data, shared, read-only, conforming
resource p6monoInfo 	data, shared, read-only, conforming
resource p7monoInfo 	data, shared, read-only, conforming
resource printerFontInfo 	data, shared, read-only, conforming
resource CorrectInk     data, shared, read-only, conforming

resource OptionsASF1BinResource       ui-object
