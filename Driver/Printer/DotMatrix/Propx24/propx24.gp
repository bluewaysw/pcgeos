##############################################################################
#
#	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	IBM Proprinter X24 24-pin Printer Driver
# FILE:		propx24.gp
#
# AUTHOR:	Dave, 2/90, from vidmem.gp
#
# Parameters file for: propx24.geo
#
#	$Id: propx24.gp,v 1.1 97/04/18 11:53:46 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	propx24.drvr
#
# Long name
#
longname "IBM Proprinter X24 24-pin driver"
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
resource generInfo 	data, shared, read-only, conforming
resource generwInfo 	data, shared, read-only, conforming
resource ps1Info 	data, shared, read-only, conforming
resource pp24pInfo 	data, shared, read-only, conforming
resource bjIBMInfo 	data, shared, read-only, conforming
resource printerFontInfo 	data, shared, read-only, conforming

resource OptionsASF1BinResource ui-object
