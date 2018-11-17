##############################################################################
#
#	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	citoh 9-pin Printer Driver
# FILE:		citoh9.gp
#
# AUTHOR:	Jim, 2/90, from vidmem.gp
#
# Parameters file for: citoh9.geo
#
#	$Id: citoh9.gp,v 1.1 97/04/18 11:53:30 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	citoh9.drvr
#
# Long name
#
longname "C.Itoh 9-pin driver"
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
resource DriverInfo	lmem, data, shared, read-only, conforming
resource generInfo	data, shared, read-only, conforming
resource generwInfo	data, shared, read-only, conforming
resource dmpInfo	data, shared, read-only, conforming
resource iwriter2Info	data, shared, read-only, conforming
resource printerFontInfo	data, shared, read-only, conforming
resource CorrectInk     data, shared, read-only, conforming

resource OptionsASF0BinResource ui-object
