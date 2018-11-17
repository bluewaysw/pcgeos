##############################################################################
#
# PROJECT:	Breadbox Test Taker
#
# AUTHOR:		John F. Howard, 01/03
#
# DESCRIPTION:	This file contains Geode definitions for the program
#
#
#
##############################################################################
#
# Permanent name:
name ttkr.app
#
# Long filename:
longname "Test Taker"
#
# Specify geode type:
type	appl, process, single
#
# Specify class name for application process.
class	TTkrProcessClass
#
# Specify application object.
appobj	TTkrApp
#
# temporary icon
tokenchars "TTa1"
tokenid 16431
#
# Heapspace: 
# To find the heapspace use the Swat "heapspace" command.
#heapspace 12k
#
# process stack space (default is 2000):
stack 4000
#

platform geos201

# Libraries:
library	geos
library	ui
library ansic
library text
library math
library basicdb

exempt basicdb

# Resources:
resource APPRESOURCE ui-object
resource INTERFACE ui-object
resource DOCUMENTUI object
resource TEXTSTRINGS data object
resource LOGORESOURCE  data object
resource APPICONRESOURCE  data object
resource DOCICONRESOURCE  data object


# classes
export TTkrDocumentClass
export TTkrQAInteractionClass
export TTkrGenDynamicListClass

usernotes "Copyright 1994 - 2003   Breadbox Computer Company LLC  All Rights Reserved"

