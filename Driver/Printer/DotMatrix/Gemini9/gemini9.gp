##############################################################################
#
#	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Satr Gemini 9-pin Printer Driver
# FILE:		gemini9.gp
#
# AUTHOR:	Dave, 2/90, from vidmem.gp
#
# Parameters file for: gemini9.geo
#
#	$Id: gemini9.gp,v 1.1 97/04/18 11:54:31 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	gemini9.drvr
#
# Long name
#
longname "Gemini 9-pin driver"
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
resource Entry fixed code read-only shared
#
# Make driver info resource accessible from user-level processes
#
resource DriverInfo	lmem, data, shared, read-only, conforming
resource geminiInfo	data, shared, read-only, conforming
resource geminiwInfo	data, shared, read-only, conforming
resource printerFontInfo        data, shared, read-only, conforming

resource OptionsASF0BinResource ui-object
resource OptionsASF1BinResource ui-object
resource OptionsASF2BinResource ui-object
