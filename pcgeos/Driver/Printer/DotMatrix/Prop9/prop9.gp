##############################################################################
#
#	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	IBM Proprinter 9-pin Printer Driver
# FILE:		prop9.gp
#
# AUTHOR:	Dave Durran
#
# Parameters file for: prop9.geo
#
#	$Id: prop9.gp,v 1.1 97/04/18 11:53:59 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	prop9.drvr
#
# Long name
#
longname "IBM Proprinter 9-pin driver"
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
resource pp2Info 	data, shared, read-only, conforming
resource xlInfo 	data, shared, read-only, conforming
resource bjInfo 	data, shared, read-only, conforming
resource pp2380Info 	data, shared, read-only, conforming
resource pp2381Info 	data, shared, read-only, conforming
resource printerFontInfo 	data, shared, read-only, conforming

resource OptionsASF1BinResource ui-object
