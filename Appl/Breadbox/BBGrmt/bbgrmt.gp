##############################################################################
#
# PROJECT:	Breadbox Gourmet (nee Recipe Box)
#
# AUTHOR:	John F. Howard, 12/95
#
# DESCRIPTION:	This file contains Geode definitions for the Recipe Box
#               program
#
#
##############################################################################
#
# Permanent name:
name bbg10.app
#
# Long filename:
longname "Gourmet"
#
# Specify geode type:
type	appl, process, single
#
# Specify class name for application process.
class	RBoxProcessClass
#
# Specify application object.
appobj	RBoxApp
#
# Token: use 16431 for Breadbox Apps
tokenchars "BGa1"
tokenid 16431
#
# Heapspace: 
# To find the heapspace use the Swat "heapspace" command.
heapspace 4717
#
# Libraries:
platform gpc12
library	geos
library	ui
library ansic
library text
library spool
#
# Resources:
resource AppResource ui-object
resource Interface ui-object
resource Menu ui-object
resource DocumentUI object
#resource BREADBOXMONIKERRESOURCE2 data object
resource RBAppIcons data object
resource RBDocIcons data object

# classes
export RBoxProcessClass
export RBoxContentClass
export RBoxVLTextClass

#usernotes "Copyright 1995 by Breadbox Computer & J. F. Howard"
