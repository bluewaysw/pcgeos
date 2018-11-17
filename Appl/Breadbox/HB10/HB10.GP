##############################################################################
#
# PROJECT:	Breadbox HomeBase
# FILE:		hb10.gp
#
# AUTHOR:	John F. Howard, 11/96
#
# DESCRIPTION:	This file contains Geode definitions for the HomeBase
#               program
#
#
##############################################################################
#
# Permanent name:
name hbase10.app
#
# Long filename:
longname "HomeBase"
#
# Specify geode type:
type	appl, process, single
#
# Specify class name for application process.
class	HBaseProcessClass
#
# Specify application object.
appobj	HBaseApp
#
# Token:
tokenchars "HBaa"
tokenid 16431
#
# Heapspace: 
# To find the heapspace use the Swat "heapspace" command.
heapspace 8000
#
# Libraries:
library	geos
library	ui
library ansic
library text
library spool
library math
#
# Resources:
resource APPRESOURCE ui-object
resource INTERFACE ui-object
resource MENU ui-object
resource DOCUMENTUI object
resource DIALOGS ui-object
resource BREADBOXMONIKERRESOURCE2 data object
resource HBAPPICONS data object
resource HBDOCICONS data object
resource HBASEBUTTONRESOURCE data
resource TEXTSTRINGS data

# classes
export HBaseProcessClass
export HBaseApplicationClass
export HBaseTriggerClass
export HBaseContentClass
export HBaseVLTextClass

usernotes "Copyright 1996 Breadbox Computer"
