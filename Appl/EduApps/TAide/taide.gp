##############################################################################
#
# PROJECT:	Breadbox Teacher's Aide - working v0.0
#
# AUTHOR:		John F. Howard, 2/99
#
# DESCRIPTION:	This file contains Geode definitions for the program
#
#
#
##############################################################################
#
# Permanent name:
name taide.app
#
# Long filename:
longname "Teacher's Aide"
#
# Specify geode type:
type	appl, process, single
#
# Specify class name for application process.
class	TAProcessClass
#
# Specify application object.
appobj	TAApp
#
# Token: use 16431 for Breadbox Apps
tokenchars "TAa1"
tokenid 16431
#
# Heapspace: 
# To find the heapspace use the Swat "heapspace" command.
heapspace 12k
#
# process stack space (default is 2000):
stack 14000
#

# Libraries:
library	geos
library	ui
library ansic
library text
library math
library spool
library basicdb
library gridlib
library treplib

# Resources:
resource AppResource ui-object
resource Interface ui-object
resource Dialogs ui-object
resource StuPickDialogs ui-object
resource SetUpDialogs ui-object
resource ConvSetUpDialogs ui-object
resource DocumentUI object
resource DisplayUI ui-object shared read-only
resource TextStrings data
resource LayoutDialogs ui-object
resource ImpExDialogs ui-object
resource TabsResource data
resource LOGORESOURCE  data object
resource AppIconResource  data object
resource DocIconResource  data object


# classes
export TADocumentClass
export VisModuleContentClass
export VisModuleCompClass
export VisCornerModuleCompClass
export TADisplayClass
export NameVisGridClass
export GTitleVisGridClass
export MainVisTextGridClass
export MainAttVisTextGridClass
export StudentSeatingVisClass

#export MyGenTextReportDialogClass


usernotes "Copyright 1994 - 2001   Breadbox Computer Company LLC  All Rights Reserved"
