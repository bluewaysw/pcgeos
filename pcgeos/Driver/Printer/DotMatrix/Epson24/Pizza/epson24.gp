##############################################################################
#
#	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Epson 24-pin Printer Driver for Pizza
# FILE:		epson24.gp
#
# AUTHOR:	owa, Mar/94, from Epson24/epson24.gp
#
# Parameters file for: epson24.geo
#
#	$Id: epson24.gp,v 1.1 97/04/18 11:53:21 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	epson24.drvr
#
# Long name
#
longname "PZ Epson 24 Drv"
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
library ui
library	spool
#
# Make this module fixed so we can put the strategy routine there
#
resource Entry fixed code read-only shared
#
# Make driver info resource accessible from user-level processes
#
resource DriverInfo 	lmem, data, shared, read-only, conforming

resource inkjetInfo	shared, read-only, conforming
resource dj300JInfo	shared, read-only, conforming
resource dj505JMInfo	shared, read-only, conforming

resource printerFontInfo 	data, shared, read-only, conforming

resource OptionsASF0BinResource	ui-object
resource OptionsASF1BinResource	ui-object
resource OptionsASF2BinResource	ui-object
resource OptionsASF1BinOnlyResource	ui-object
