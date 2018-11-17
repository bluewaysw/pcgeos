##############################################################################
#
#	Copyright (c) Berkeley Softworks 1994 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Brother NIKE 56-jet Printer Driver
# FILE:		nike56.gp
#
# AUTHOR:	Dave Durran
#
# Parameters file for: nike56.geo
#
#	$Id: nike56.gp,v 1.1 97/04/18 11:55:39 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	nike56.drvr
#
# Long name
#
longname "Brother NIKE 56-jet driver"
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
resource Entry			fixed code read-only shared
#
# Make driver info resource accessible from user-level processes
#
resource DriverInfo	 	lmem, data, shared, read-only, conforming
resource baseInfo 		data, shared, read-only, conforming
resource baseTranInfo 		data, shared, read-only, conforming
resource colorInfo 		data, shared, read-only, conforming
resource colorTranInfo 		data, shared, read-only, conforming
resource customStringsUI 	lmem, data, shared, read-only, conforming
resource NikeOptionsResource	ui-object

export NikePaperInputGroupClass
