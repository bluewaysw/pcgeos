##############################################################################
#
# PROJECT:	BASICBase
# FILE:		babase.gp
#
# AUTHOR:		John F. Howard, 4/98
#
# DESCRIPTION:	This file contains Geode definitions for the BASICBase
#               program
#
#
##############################################################################
#
# Permanent name:
name babase.app
#
# Long filename:
longname "BuilderBase"
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
tokenchars "BBaa"
tokenid 16431
#
# Heapspace: 
# To find the heapspace use the Swat "heapspace" command.
heapspace 8000
#
# process stack space (default is 2000):
stack 4000
#
# Libraries:
library	geos
library	ui
library ansic
library text
#
# Resources:
resource APPRESOURCE ui-object
resource INTERFACE ui-object
resource SEARCHRESOURCE ui-object
resource MENU ui-object
resource ABOUTRESOURCE ui-object
resource DOCUMENTUI object
resource BREADBOXMONIKERRESOURCE1 data object
resource BREADBOXMONIKERRESOURCE2 data object
resource HBAPPICONS data object
resource HBDOCICONS data object
resource TEXTSTRINGS data object

# classes
export HBaseProcessClass
export TextEnableClass

usernotes "Copyright 1996-1998 Breadbox Computer Company"
