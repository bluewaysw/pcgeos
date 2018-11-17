##############################################################################
#
#	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Epson 48-jet Printer Driver for Pizza
# FILE:		epson48.gp
#
# AUTHOR:	owa
#
# Parameters file for: epson48.geo
#
#	$Id: epson48.gp,v 1.1 97/04/18 11:54:42 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	epson48.drvr
#
# Long name
#
longname "PZ Epson 48 Drv"
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
resource dynaPR48Info	data, shared, read-only, conforming
resource ap700Info	data, shared, read-only, conforming
resource ap700MInfo	data, shared, read-only, conforming
resource mj500Info	data, shared, read-only, conforming
resource mj1000Info	data, shared, read-only, conforming
resource bj10vInfo	data, shared, read-only, conforming
resource bj220Info	data, shared, read-only, conforming
resource bjc400jInfo	data, shared, read-only, conforming
resource bjc400jMInfo	data, shared, read-only, conforming
resource bjc600jInfo	data, shared, read-only, conforming
resource bjc600jMInfo	data, shared, read-only, conforming
resource printerFontInfo data, shared, read-only, conforming
resource CorrectInk	data, shared, read-only, conforming

resource gamma20        data, shared, read-only, conforming
resource gamma175       data, shared, read-only, conforming

resource OptionsASF1BinOnlyResource       ui-object
resource OptionsASF1BinResource       ui-object
resource OptionsASF2BinResource       ui-object
