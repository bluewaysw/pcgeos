##############################################################################
#
#	Copyright (c) Berkeley Softworks 1993 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	IBM Graphics Printer 9-pin Printer Driver
# FILE:		grpr9.gp
#
# AUTHOR:	Dave Durran
#
# Parameters file for: grpr9.geo
#
#	$Id: grpr9.gp,v 1.1 97/04/18 11:55:24 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	grpr9.drvr
#
# Long name
#
longname "IBM Graphics 9-pin driver"
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
resource grprInfo 	data, shared, read-only, conforming
resource pp1Info 	data, shared, read-only, conforming
resource printerFontInfo 	data, shared, read-only, conforming

resource OptionsASF1BinResource ui-object
