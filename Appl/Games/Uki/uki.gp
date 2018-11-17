##############################################################################
#
#	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Uki
# FILE:		uki.gp
#
# AUTHOR:	Jimmy, 11/90
#
#
# Parameters file for: tetris.geo
#
#	$Id: uki.gp,v 1.1 97/04/04 15:47:11 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name uki.app
#
# Long name
#
longname "Uki"
#
# DB Token
#
tokenchars "UKIJ"
tokenid 0
#
# Specify geode type
#
type	appl, process, single
#
# Specify heapspace requirement
#
heapspace 3409
#
# Specify class name for process
#
class	UkiProcessClass
#
# Specify application object
#
appobj	UkiApp
#
# Import library routine definitions
#
library	geos
library	ui
library text
library sound
#
# Define resources other than standard discardable code
#
resource UIApplication 		ui-object
resource Interface 		ui-object
resource ContentBlock 		object
resource DataBlock		lmem read-only shared

#resource AppLCMonikerResource	lmem read-only shared
#resource AppLMMonikerResource	lmem read-only shared
#resource AppSCMonikerResource	lmem read-only shared
#resource AppSMMonikerResource	lmem read-only shared
#resource AppYCMonikerResource	lmem read-only shared
#resource AppYMMonikerResource	lmem read-only shared
#resource AppSCGAMonikerResource	lmem read-only shared

resource AppMonikerResource	lmem read-only shared
#
# Export classes
#
export UkiContentClass
export UkiPrimaryClass
