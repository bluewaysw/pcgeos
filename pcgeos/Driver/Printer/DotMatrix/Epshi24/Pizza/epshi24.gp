##############################################################################
#
#	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Epson late model 24-pin Printer Driver
# FILE:		epshi24.gp
#
# AUTHOR:	Jim, 2/90, from vidmem.gp
#
# Parameters file for: epshi24.geo
#
#	$Id: epshi24.gp,v 1.1 97/04/18 11:54:08 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	epshi24.drvr
#
# Long name
#
longname "PZ Late Epson 24 Drv"
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

resource dynaInfo	data, shared, read-only, conforming
resource dual2Info	data, shared, read-only, conforming
resource dual34MInfo	data, shared, read-only, conforming
resource dual34Info	data, shared, read-only, conforming
resource dual5Info	data, shared, read-only, conforming
resource fb2HInfo	data, shared, read-only, conforming
resource fb5HInfo	data, shared, read-only, conforming

resource lbpInfo	data     shared, read-only, conforming
resource lbp2Info	shared, read-only, conforming
resource lbpHInfo	shared, read-only, conforming
resource lbpA3Info	shared, read-only, conforming
resource lbpA4Info	shared, read-only, conforming

resource printerFontInfo data, shared, read-only, conforming
resource gamma30	data, shared, read-only, conforming
resource CorrectInk	data, shared, read-only, conforming

resource OptionsASF0BinResource       ui-object
resource OptionsASF1BinResource       ui-object
resource OptionsASF2BinResource       ui-object
resource OptionsASF1BinOnlyResource	ui-object
