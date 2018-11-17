##############################################################################
#
#	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Quietjet Printer Driver
# FILE:		quietjet.gp
#
# AUTHOR:	Jim, 2/90, from vidmem.gp
#
# Parameters file for: quietjet.geo
#
#	$Id: quietjet.gp,v 1.1 97/04/18 11:52:12 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	quietjet.drvr
#
# Long name
#
longname "HP QuietJet driver"
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
resource qjetInfo 	data, shared, read-only, conforming
resource qjetpInfo 	data, shared, read-only, conforming
resource printerFontInfo 	data, shared, read-only, conforming

resource OptionsASF0BinResource ui-object
