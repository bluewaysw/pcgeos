##############################################################################
#
#	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	toshiba 24-pin Printer Driver
# FILE:		toshiba24.gp
#
# AUTHOR:	Jim, 2/90, from vidmem.gp
#
# Parameters file for: epson9.geo
#
#	$Id: tosh24.gp,v 1.1 97/04/18 11:53:34 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	tosh24.drvr
# 
# Long name
#
longname "Toshiba 24-pin driver"
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
resource p321Info	data, shared, read-only, conforming
resource p351Info	data, shared, read-only, conforming
resource printerFontInfo	data, shared, read-only, conforming

resource OptionsASF1BinResource ui-object
