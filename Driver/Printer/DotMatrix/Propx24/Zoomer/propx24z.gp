##############################################################################
#
#	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	IBM Proprinter X24 24-pin Printer Driver for Zoomer
# FILE:		propx24z.gp
#
# AUTHOR:	Dave, 2/90, from vidmem.gp
#
# Parameters file for: propx24z.geo
#
#	$Id: propx24z.gp,v 1.1 97/04/18 11:53:44 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	propx24z.drvr
#
# Long name
#
longname "IBM X24 driver for Z"
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
resource bjIBMInfo      data, shared, read-only, conforming
resource printerFontInfo 	data, shared, read-only, conforming

resource OptionsASF1BinResource ui-object
