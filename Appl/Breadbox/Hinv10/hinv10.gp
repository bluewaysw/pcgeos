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
resource APPRESOURCE ui-object
resource INTERFACE ui-object
resource MENU ui-object
resource INFOANDPICK ui-object
resource DATALISTS ui-object
resource IMPORTANTINFO ui-object
resource DOCUMENTUI object
resource HILCAPPICON ui-object
resource HIDOCICONS data object
resource ROOMSMONTEXT data object
resource ITEMSMONTEXT data object
resource HOUSEMONTEXT data object
resource IMPINFMONTEXT data object
resource QTIPSRESOURCE ui-object
resource STRINGS data object

# classes
export HInvProcessClass
export PrintGenTextClass
export IPrintGenTextClass

#usernotes "Copyright 1995 Breadbox Computers & J. F. Howard"
