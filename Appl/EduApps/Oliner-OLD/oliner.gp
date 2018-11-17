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
tokenchars "OLa0"
tokenid 8
#
# Heapspace: 
# To find the heapspace use the Swat "heapspace" command.
#heapspace 12k
#
# process stack space (default is 2000):
stack 8000
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
library extui

exempt basicdb
exempt extui

# Resources:
resource APPRESOURCE ui-object
resource INTERFACE ui-object
resource DOCUMENTUI object
#resource TEXTSTRINGS data
#resource LOGORESOURCE  data object
#resource IMPEXDIALOGS ui-object
#resource GENERATEDIALOGS ui-object
#resource DIALOGUI ui-object
#resource TALINKDIALOGS ui-object
#resource ADDDATADIALOGS  ui-object
#resource SELQDIALOG ui-object
#resource APPICONRESOURCE  data object
#resource DOCICONRESOURCE  data object


# classes
export OLDocumentClass
#export TGenQAInteractionClass
#export TGenGenDynamicListClass
#export TGGradeInteractionClass
#export TGTAInteractionClass
#export TGenDocumentGroupClass

usernotes "Copyright 1994 - 2003   Breadbox Computer Company LLC  All Rights Reserved"

