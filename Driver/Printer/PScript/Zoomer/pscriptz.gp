##############################################################################
#
#	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	PostScript Printer Driver for Zoomer
# FILE:		pscriptz.gp
#
# AUTHOR:	Jim, 2/90, from epson24.gp
#
# Parameters file for: pscriptz.geo
#
#	$Id: pscriptz.gp,v 1.1 97/04/18 11:55:49 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	pscriptz.drvr
#
# Long name
#
longname "PostScript driver for Z"
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
library	eps noload
#
# Make this module fixed so we can put the strategy routine there
#
resource Entry fixed code read-only shared
#
# Make driver info resource accessible from user-level processes
#
resource DriverInfo 	data, shared, read-only, conforming, lmem
resource appleLW2NTf35Info      data, shared, read-only, conforming
resource appleLWf13Info         data, shared, read-only, conforming
resource hpLJ4psInfo            data, shared, read-only, conforming
resource ibm4019f17Info         data, shared, read-only, conforming
resource ibm4019f39Info         data, shared, read-only, conforming
resource necColor40f17Info 	data, shared, read-only, conforming
resource generf13Info 		data, shared, read-only, conforming
resource generf35Info 		data, shared, read-only, conforming

resource OptionsIBM4019PSResource	ui-object
