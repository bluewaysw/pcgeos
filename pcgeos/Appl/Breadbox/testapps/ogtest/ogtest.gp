##############################################################################
#
#
# PROJECT:	Test Applications
# MODULE:	Testing OGGadgets Library
# FILE:		ogtest.gp
#
# AUTHOR:		jfh, 8/04
#
#
##############################################################################
#
# Permanent name:
name ogtest.app
#
# Long filename:
longname "OG Gadgets Tester"
#
# Specify geode type: ,
type	appl, process, single
#
# Specify class name for application process.
class	TestProcessClass
#
# Specify application object.
appobj	TestApp
#
# Token:
tokenchars "OGTS"
tokenid 16431
#

#platform geos201

# Libraries:
library	geos
library	ui
library ansic
library text
library gadgets

#
# Resources:
resource APPRESOURCE ui-object
resource INTERFACE ui-object


