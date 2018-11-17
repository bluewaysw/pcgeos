##############################################################################
#
#	Copyright (c) GlobalPC 1999 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Canon RGB Printer Driver
# FILE:		canonRGB.gp
#
# AUTHOR:	Jim, 2/90, from vidmem.gp
#
# Parameters file for: canonRGB.geo
#
#	$Id$
#
##############################################################################
#
# Specify permanent name first
#
name	canonrgb.drvr
#
# Long name
#
longname "Canon BJC-1000/2000 driver"
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
library rgb2cmyk
#
# Make this module fixed so we can put the strategy routine there
#
resource Entry			fixed read-only shared code
#
# Make driver info resource accessible from user-level processes
#
resource DriverInfo 		read-only shared conforming lmem data
resource rgbInfo 		read-only shared conforming data
resource monoInfo 		read-only shared conforming data
resource OptionsASF1BinResource	ui-object
