##############################################################################
#
# PROJECT:	Breadbox Outliner
#
# AUTHOR:		John F. Howard, 05/03
#
# DESCRIPTION:	This file contains Geode definitions for the program
#
#
#
##############################################################################
#
# Permanent name:
name oliner.app
#
# Long filename:
longname "Outliner"
#
# Specify geode type:
type	appl, process, single
#
# Specify class name for application process.
class	OLProcessClass
#
# Specify application object.
appobj	OLApp
#
# temporary icon
tokenchars "OLa1"
tokenid 16431
#
# Heapspace: 
# To find the heapspace use the Swat "heapspace" command.
#heapspace 12k
#
# process stack space (default is 2000):
stack 6000
#

platform geos201

# Libraries:
library	geos
library	ui
library ansic
library text
library math
library spool
library basicdb
library treplib
library spell

exempt basicdb
exempt treplib
exempt spell

# Resources:
resource APPRESOURCE ui-object
resource INTERFACE ui-object
resource DOCUMENTUI object
resource DIALOGUI ui-object
resource BUTTONRESOURCE data
resource TOOLRESOURCE data
resource APPICONRESOURCE  data object
resource DOCICONRESOURCE  data object


# classes
export OLDocumentClass
export OLDynamicListClass
export RepeatingTriggerClass
export CardGenTextClass
export FindGenTextClass

usernotes "Copyright 1994 - 2003   Breadbox Computer Company LLC  All Rights Reserved"

