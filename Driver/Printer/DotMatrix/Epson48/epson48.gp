##############################################################################
#
#	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Epson 48-jet Printer Driver
# FILE:		epson48.gp
#
# AUTHOR:	Dave Durran
#
# Parameters file for: epson48.geo
#
#	$Id: epson48.gp,v 1.1 97/04/18 11:54:52 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	epson48.drvr
#
# Long name
#
longname "Epson 48-jet driver"
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
resource stylus800Info 	data, shared, read-only, conforming
resource sq870Info 	data, shared, read-only, conforming
resource sq1170Info 	data, shared, read-only, conforming
resource bjc800Info 	data, shared, read-only, conforming
resource bjc800MInfo 	data, shared, read-only, conforming
resource printerFontInfo data, shared, read-only, conforming
resource CorrectInk	data, shared, read-only, conforming

resource gamma20        data, shared, read-only, conforming
resource gamma175       data, shared, read-only, conforming

resource OptionsASF1BinOnlyResource       ui-object
resource OptionsASF1BinResource       ui-object
resource OptionsASF2BinResource       ui-object
