##############################################################################
#
#	Copyright (c) GeoWorks 1991 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	CCom Fax Driver
# FILE:		ccom.gp
#
# AUTHOR:	Adam de Boor, Feb  1, 1991
#
#
# Geode Parameters for the Complete Communicator FAX driver
#
#	$Id: ccomrem.gp,v 1.1 97/04/18 11:52:47 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name ccomrem.drvr
#
# Long name
#
longname "Remote CCom FAX Driver"
#
# DB Token
#
tokenchars "FXDR"
tokenid 0
#
# Specify geode type
#
type	driver, single
#
# Import routine definitions
#
library	geos
library ui
library text
library spool
#
# Make this module fixed so we can put the strategy routine there
#
resource Entry		fixed code read-only shared
#
# Make the driver info resources accessible from user-level
#
resource DriverInfo	lmem, data, shared, read-only conforming
resource ccomDeviceInfo	data, shared, read-only, conforming
resource FaxUI		ui-object
resource FaxOptionsUI	ui-object
#
# Exported items
#
export	FaxInfoClass
export 	FaxServerListClass
