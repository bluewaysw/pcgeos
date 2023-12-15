##############################################################################
#
# PROJECT:	Breadbox Home Inventory
# FILE:		hinv10.gp   release version 1.0
#
# AUTHOR:	John F. Howard, 8/95
#
# DESCRIPTION:	This file contains Geode definitions for the Home Inventory
#               program
#
#
##############################################################################
#
# Permanent name:
name hinv10.app
#
# Long filename:
longname "Home Inventory Plus"
#
# Specify geode type:
type	appl, process, single
#
# Specify class name for application process.
class	HInvProcessClass
#
# Specify application object.
appobj	HInvApp
#
# Token:
tokenchars "HIP1"
tokenid 16423
#
# Heapspace: calculated after completing V0.0w (added ~1k)
# To find the heapspace use the Swat "heapspace" command.
heapspace 6500
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
resource Infoandpick ui-object
resource Datalists ui-object
resource ImportantInfo ui-object
resource DocumentUI object
resource HILCAppIcon ui-object
resource HIDocIcons data object
resource RoomsMonText data object
resource ItemsMonText data object
resource HouseMonText data object
resource ImpInfMonText data object
resource QTipsResource ui-object
resource Strings data object

# classes
export HInvProcessClass
export PrintGenTextClass
export IPrintGenTextClass

#usernotes "Copyright 1995 Breadbox Computers & J. F. Howard"
