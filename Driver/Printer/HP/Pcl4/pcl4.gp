##############################################################################
#
#	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Laserjet Printer Driver
# FILE:		pcl4.gp
#
# AUTHOR:	Dave, 1/92, from laserjet.gp
#
# Parameters file for: pcl4.geo
#
#	$Id: pcl4.gp,v 1.1 97/04/18 11:52:21 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	pcl4.drvr
#
# Long name
#
longname "HP PCL Level 4 driver"
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

resource downloadInfo 		data, shared, read-only, conforming
resource laserjet2Info	 	data, shared, read-only, conforming
resource laserjet2CompInfo 	data, shared, read-only, conforming
resource ppdsInfo 		data, shared, read-only, conforming
resource laserjet3SiInfo 	data, shared, read-only, conforming
resource laserjet4Info	 	data, shared, read-only, conforming
resource ibm4019Info	 	data, shared, read-only, conforming
resource ibm4039Info	 	data, shared, read-only, conforming
resource internalInfo	 	data, shared, read-only, conforming
resource downloadDuplexInfo 	data, shared, read-only, conforming
resource laserjet3DInfo 	data, shared, read-only, conforming
resource paintjetxl300Info 	data, shared, read-only, conforming

resource MainPcl4Resource 	ui-object
resource OptionsPcl4Resource 	ui-object
