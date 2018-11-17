##############################################################################
#
#	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Deskjet Printer Driver for Zoomer
# FILE:		deskjet.gp
#
# AUTHOR:	Jim, 2/90, from vidmem.gp
#
# Parameters file for: deskjetz.geo
#
#	$Id: deskjetj.gp,v 1.1 97/04/18 11:51:52 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	deskjetj.drvr
#
# Long name
#
longname "HP DeskJet driver for J"
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
resource deskjetJEDIInfo 	data, shared, read-only, conforming
