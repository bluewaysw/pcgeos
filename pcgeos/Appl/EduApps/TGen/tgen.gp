##############################################################################
#
# PROJECT:	Breadbox Test Generator
#
# AUTHOR:		John F. Howard, 08/02
#
# DESCRIPTION:	This file contains Geode definitions for the program
#
#
#
##############################################################################
#
# Permanent name:
name tgen.app
#
# Long filename:
longname "Test Generator"
#
# Specify geode type:
type	appl, process, single
#
# Specify class name for application process.
class	TGenProcessClass
#
# Specify application object.
appobj	TGenApp
#
# temporary icon
tokenchars "TGa1"
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
library spool
library basicdb
library treplib

exempt basicdb
exempt treplib

# Resources:
resource APPRESOURCE ui-object
resource INTERFACE ui-object
resource DOCUMENTUI object
resource TEXTSTRINGS data object
resource LOGORESOURCE  data object
resource IMPEXDIALOGS ui-object
resource GENERATEDIALOGS ui-object
resource GRADEDIALOGS ui-object
resource TALINKDIALOGS ui-object
resource ADDDATADIALOGS  ui-object
resource SELQDIALOG ui-object
resource APPICONRESOURCE  data object
resource DOCICONRESOURCE  data object


# classes
export TGenDocumentClass
export TGenQAInteractionClass
export TGenGenDynamicListClass
export TGGradeInteractionClass
export TGTAInteractionClass
export TGenDocumentGroupClass

usernotes "Copyright 1994 - 2003   Breadbox Computer Company LLC  All Rights Reserved"

