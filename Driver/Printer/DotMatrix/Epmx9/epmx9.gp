##############################################################################
#
#	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Epson MX 9-pin Printer Driver
# FILE:		epmx9.gp
#
# AUTHOR:	Jim, 2/90, from vidmem.gp
#
# Parameters file for: epmx9.geo
#
#	$Id: epmx9.gp,v 1.1 97/04/18 11:53:54 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	epmx9.drvr
#
# Long name
#
longname "Epson MX 9-pin driver"
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
resource DriverInfo	lmem, data, shared, read-only, conforming
resource mx80Info	data, shared, read-only, conforming
resource mx100Info	data, shared, read-only, conforming
resource printerFontInfo	data, shared, read-only, conforming
resource gamma20        data, shared, read-only, conforming

resource OptionsASF0BinResource ui-object
