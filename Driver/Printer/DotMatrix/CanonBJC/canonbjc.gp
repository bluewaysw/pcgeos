##############################################################################
#
#	Copyright (c) GlobalPC 1999 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Canon BJC Printer Driver
# FILE:		canonBJC.gp
#
# AUTHOR:	Jim, 2/90, from vidmem.gp
#
# Parameters file for: canonBJC.geo
#
#	$Id$
#
##############################################################################
#
# Specify permanent name first
#
name	canonbjc.drvr
#
# Long name
#
longname "Canon BJC driver"
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
resource Entry			fixed read-only shared code
#
# Make driver info resource accessible from user-level processes
#
resource DriverInfo 		read-only shared conforming lmem data
resource monoInfo 		read-only shared conforming data
resource cmyInfo 		read-only shared conforming data
resource cmykInfo 		read-only shared conforming data
resource OptionsASF1BinResource	ui-object
