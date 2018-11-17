##############################################################################
#
#	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Large Vis Tree Sample Application
# FILE:		largeVisTree.gp
#
# AUTHOR:	Doug 5/91
#
#
# Parameters file for: largeVisTree.geo
#
#	$Id: largevistree.gp,v 1.1 97/04/04 16:34:14 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name largeVS.app
#
# Specify geode type
#
type	appl, process
#
# Specify class name for process
#
class	largeVisTree_ProcessClass
#
# Specify application object
#
appobj	LargeVisTreeApp
#
# Import library routine definitions
#
library	geos
library	ui
#
# Define resources other than standard discardable code
#
#
# UI-run object resources
resource AppResource ui-object
resource PrimaryResource ui-object 
#
# APP-run object resources
resource DocResource object 
#
#
# Other classes
#
export VisLargeCompClass
