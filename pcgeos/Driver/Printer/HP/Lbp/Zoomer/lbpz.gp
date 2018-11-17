##############################################################################
#
#	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	LBP Printer Driver for Zoomer
# FILE:		lbpz.gp
#
# AUTHOR:	Jim, 2/90, from vidmem.gp
#
# Parameters file for: lbpz.geo
#
#	$Id: lbpz.gp,v 1.1 97/04/18 11:51:57 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	lbpz.drvr
#
# Long name
#
longname "Canon LBP driver for Z"
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

resource capsl3Info 	data, shared, read-only, conforming
resource printerFontInfo 	data, shared, read-only, conforming

resource	OptionsCapslResource	ui-object
