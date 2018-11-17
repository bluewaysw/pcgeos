##############################################################################
#
#	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	PostScript Printer Driver
# FILE:		psb.gp
#
# AUTHOR:	Jim
#
# Parameters file for: psb.geo
#
#	$Id: psb.gp,v 1.1 97/04/18 11:52:09 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	psb.drvr
#
# Long name
#
longname "PostScript (bitmap) driver"
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
