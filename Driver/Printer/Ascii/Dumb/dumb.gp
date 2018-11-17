##############################################################################
#
#	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Dumb ASCII (Unformatted) Print Driver
# FILE:		dumb.gp
#
# AUTHOR:	Dave Durran
#
# Parameters file for: dumb.geo
#
#	$Id: dumb.gp,v 1.1 97/04/18 11:56:37 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	dumb.drvr
# 
# Long name
#
longname "Dumb ASCII Only driver"
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
resource dumbInfo	data, shared, read-only, conforming
resource printerFontInfo	data, shared, read-only, conforming

resource OptionsNoSettingsResource ui-object
