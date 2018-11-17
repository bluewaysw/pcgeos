##############################################################################
#
#	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Diconix 9-jet Printer Driver
# FILE:		diconix9.gp
#
# AUTHOR:	Dave, 11/91, from vidmem.gp
#
# Parameters file for: diconix9.geo
#
#	$Id: diconix9.gp,v 1.1 97/04/18 11:54:30 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	diconix9.drvr
#
# Long name
#
longname "Diconix 9-jet driver"
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
resource d150Info	data, shared, read-only, conforming
resource d300wInfo	data, shared, read-only, conforming
resource printerFontInfo	data, shared, read-only, conforming

resource OptionsASF0BinResource ui-object
resource OptionsASF1BinResource ui-object
resource OptionsASF2BinResource ui-object
