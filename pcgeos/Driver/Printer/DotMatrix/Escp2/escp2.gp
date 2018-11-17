##############################################################################
#
#	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Epson Escape P2 24-pin Printer Driver
# FILE:		escp2.gp
#
# AUTHOR:	Dave, 7/91, from epshi24.gp
#
# Parameters file for: escp2.geo
#
#	$Id: escp2.gp,v 1.1 97/04/18 11:54:21 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	escp2.drvr
#
# Long name
#
longname "Escape P2 Epson 24-pin driver"
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
