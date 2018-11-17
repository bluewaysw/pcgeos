##############################################################################
#
#	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Deskjet Printer Driver
# FILE:		dj500c.gp
#
# AUTHOR:	Dave Durran
#
# Parameters file for: dj500c.geo
#
#	$Id: dj500c.gp,v 1.1 97/04/18 11:52:27 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	dj500c.drvr
#
# Long name
#
longname "HP DeskJet CMY driver"
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
resource dj500cInfo 	data, shared, read-only, conforming
resource pjxl300Info    data, shared, read-only, conforming
resource CorrectDJ500C  data, shared, read-only, conforming

