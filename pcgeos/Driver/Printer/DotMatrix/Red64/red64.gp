##############################################################################
#
#	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Canon Redwood 64-jet Printer Driver
# FILE:		red64.gp
#
# AUTHOR:	Dave Durran
#
# Parameters file for: red64.geo
#
#	$Id: red64.gp,v 1.1 97/04/18 11:55:06 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	red64.drvr
#
# Long name
#
longname "Canon Redwood 64-jet driver"
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
resource baseInfo 	data, shared, read-only, conforming

resource OptionsASF1BinResource ui-object
