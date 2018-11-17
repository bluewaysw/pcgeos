##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	
# FILE:		logo.gp
#
# AUTHOR:	Don Reeves, Aug 16, 1994
#
# Geode parameters for the "Logo" screen saver
#
#	$Id: logo.gp,v 1.1 97/04/04 16:49:38 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name logosavr.lib
#
# Long filename
#
longname "Logo"
#
# Token information
#
tokenchars "SSAV"
tokenid 0
#
# Specify geode type
#
type	appl, process
#
# Specify stack size
#
stack	2000
#
# Specify class name for process
#
class	LogoProcessClass
#
# Specify application object
#
appobj	LogoApp
#
# Import library routine definitions
#
library	ui
library saver
#
# Define resources other than standard discardable code
#
resource AppResource		object
#
# Define exported entry points (for object saving)
#
export LogoProcessClass
export LogoApplicationClass
