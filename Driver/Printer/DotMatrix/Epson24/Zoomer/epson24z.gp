##############################################################################
#
#	Copyright (c) Berkeley Softworks 1993 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Epson 24-pin Printer Driver for Zoomer
# FILE:		epson24z.gp
#
# AUTHOR:	Jim, 2/90, from vidmem.gp
#
# Parameters file for: epson24z.geo
#
#	$Id: epson24z.gp,v 1.1 97/04/18 11:53:18 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	epson24z.drvr
#
# Long name
#
longname "Epson LQ driver for Z"
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
resource lq800Info 	data, shared, read-only, conforming
resource lq1000Info 	data, shared, read-only, conforming
resource lq2500Info 	data, shared, read-only, conforming
resource printerFontInfo 	data, shared, read-only, conforming
resource CorrectInk     data, shared, read-only, conforming

resource OptionsASF0BinResource	ui-object
resource OptionsASF1BinResource	ui-object
resource OptionsASF2BinResource	ui-object
