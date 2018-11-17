##############################################################################
#
#	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	ImageWriter 9-pin Printer Driver
# FILE:		iwriter9.gp
#
# AUTHOR:	Dave Durran
#
# Parameters file for: iwriter9.geo
#
#	$Id: iwriter9.gp,v 1.1 97/04/18 11:53:38 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	iwriter9.drvr
#
# Long name
#
longname "ImageWriter 9-pin driver"
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
resource DriverInfo	data, shared, read-only, conforming
resource generInfo	data, shared, read-only, conforming
