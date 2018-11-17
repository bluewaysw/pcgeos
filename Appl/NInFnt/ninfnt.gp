##############################################################################
#
#	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Nimbus Font Converter
# FILE:		ninfnt.gp
#
# AUTHOR:	Gene, 4/30/91
#
# Parameters file for: ninfnt.geo
#
#	$Id: ninfnt.gp,v 1.1 97/04/04 16:16:57 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name ninfnt.app
#
# Long name
#
longname "Nimbus Font Converter"
#
# Desktop-related definitions
#
tokenchars "NFCT"
tokenid 0
#
# Specify geode type
#
type	appl, process, single
#
# Specify class name for process
#
class	NimbusFontInstallProcessClass
#
# Specify application object
#
appobj	NimbusFontInstallApp
#
# Import library routine definitions
#
library	geos
library	ui
#
# Define resources other than standard discardable code
#
resource Interface ui-object
resource AppResource ui-object
#resource AppSCMonikerResource ui-object read-only
#resource AppSMMonikerResource ui-object read-only
#resource AppLCMonikerResource ui-object read-only
#resource AppLMMonikerResource ui-object read-only
#resource AppLCGAMonikerResource ui-object read-only
#resource AppSCGAMonikerResource ui-object read-only
resource FontInstallStyleData read-only shared lmem
resource FontInstallWeightData read-only shared lmem
resource ContentResource ui-object
#
# Export classes: list classes which are defined by the application here.
#
export FontInstallListClass
export VisRectangleClass
