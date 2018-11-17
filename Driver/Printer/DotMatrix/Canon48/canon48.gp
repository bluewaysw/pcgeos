##############################################################################
#
#	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Canon BJ-130 48-jet Printer Driver
# FILE:		canon48.gp
#
# AUTHOR:	Jim, 2/90, from vidmem.gp
#
# Parameters file for: canon48.geo
#
#	$Id: canon48.gp,v 1.1 97/04/18 11:54:06 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	canon48.drvr
#
# Long name
#
longname "Canon BJ-130 48-jet driver"
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
resource generInfo 	data, shared, read-only, conforming
resource generwInfo 	data, shared, read-only, conforming
resource bj10eInfo 	data, shared, read-only, conforming
resource execjetInfo 	data, shared, read-only, conforming
resource printerFontInfo 	data, shared, read-only, conforming

resource gamma21	data, shared, read-only, conforming
resource gamma175	data, shared, read-only, conforming

resource OptionsASF1BinResource ui-object
resource OptionsASF2BinResource ui-object
