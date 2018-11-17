##############################################################################
#
#	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	PostScript Printer Driver
# FILE:		postcript.gp
#
# AUTHOR:	Jim, 2/90, from epson24.gp
#           Falk 2015, added PS 2 PDF lib and resource
#
# Parameters file for: pscript.geo
#
#	$Id: pscript.gp,v 1.1 97/04/18 11:55:58 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name	pscript.drvr
#
# Long name
#
longname "PostScript driver"
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
library ps2pdf
#
# Make this module fixed so we can put the strategy routine there
#
resource Entry fixed code read-only shared
#
# Make driver info resource accessible from user-level processes
#
resource DriverInfo 	data, shared, read-only, conforming, lmem
resource adobeLJ2f35Info 	data, shared, read-only, conforming
resource adobeLJ2fTC1Info 	data, shared, read-only, conforming
resource adobeLJ2fTC2Info 	data, shared, read-only, conforming
resource appleLW2NTf35Info 	data, shared, read-only, conforming
resource appleLWf13Info 	data, shared, read-only, conforming
resource hpLJ4psInfo	 	data, shared, read-only, conforming
resource ibm4019f17Info 	data, shared, read-only, conforming
resource ibm4019f39Info 	data, shared, read-only, conforming
resource ibm4079f35Info 	data, shared, read-only, conforming
resource ibm4216f43Info 	data, shared, read-only, conforming
resource necColor40f17Info 	data, shared, read-only, conforming
resource necColorf35Info 	data, shared, read-only, conforming
resource generCf35Info 		data, shared, read-only, conforming
resource generf13Info 		data, shared, read-only, conforming
resource generf17Info 		data, shared, read-only, conforming
resource generf35Info 		data, shared, read-only, conforming
resource generf39cartInfo	data, shared, read-only, conforming
resource qmsColorScriptf35Info 	data, shared, read-only, conforming
resource qmsPS410f43Info 	data, shared, read-only, conforming
resource softRIPInfo		data, shared, read-only, conforming
resource hostPrinterInfo	data, shared, read-only, conforming

resource OptionsIBM4019PSResource	ui-object
