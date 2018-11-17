##############################################################################
#
#	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	LBP Printer Driver
# FILE:		lbp.gp
#
# AUTHOR:	Jim, 2/90, from vidmem.gp
#
# Parameters file for: lbp.geo
#
#	$Id: lbp.gp,v 1.1 97/04/18 11:52:00 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	lbp.drvr
#
# Long name
#
longname "Canon LBP driver"
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

resource capsl2Info 	data, shared, read-only, conforming
resource capsl3Info 	data, shared, read-only, conforming
resource printerFontInfo 	data, shared, read-only, conforming

resource	OptionsCapslResource	ui-object
