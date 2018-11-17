##############################################################################
#
#	Copyright (c) Berkeley Softworks 1993 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Laserjet Printer Driver for Zoomer
# FILE:		pcl4z.gp
#
# AUTHOR:	Dave, 1/92, from laserjet.gp
#
# Parameters file for: pcl4.geo
#
#	$Id: pcl4j.gp,v 1.1 97/04/18 11:52:17 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	pcl4j.drvr
#
# Long name
#
longname "HP PCL 4 driver for J"
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

resource laserjetJEDIInfo	 	data, shared, read-only, conforming

resource MainPcl4Resource 	ui-object
resource OptionsPcl4Resource 	ui-object
