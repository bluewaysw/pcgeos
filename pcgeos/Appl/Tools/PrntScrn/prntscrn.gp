##############################################################################
#
#	Copyright (c) Geoworks 1994 -- All Rights Reserved
#
# PROJECT:	GEOS
# MODULE:	Appl/Tools/PrntScrn
# FILE:		prntscrn.gp
#
# AUTHOR:	Don Reeves, Aug 11, 1994
#
# Contains the Geode Parameters for the "Print to Screen" application
#
#	$Id: prntscrn.gp,v 1.1 97/04/04 17:15:30 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name prntscrn.app
#
# Long filename
#
longname "Print to Screen"
#
# Token information
#
tokenchars "PRSC"
tokenid 0
#
# Specify geode type
#
type	appl, process, single
#
# Specify stack size
#
stack	2000
#
# Specify class name for process
#
class	PrntScrnProcessClass
#
# Specify application object
#
appobj	PrntScrnApp
#
# Import library routine definitions
#
library	ui
library spool
#
# Define resources other than standard discardable code
#
resource AppResource		ui-object
resource Interface		ui-object
resource Strings		lmem read-only shared
#
# Define exported entry points (for object saving)
#
export PrntScrnProcessClass
