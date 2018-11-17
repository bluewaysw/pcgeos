##############################################################################
#
#
# PROJECT:	Test Applications
# MODULE:	Testing CGadgets Library
# FILE:		gtest.gp
#
# AUTHOR:		jfh, 8/04
#
#
##############################################################################
#
# Permanent name:
name gtest.app
#
# Long filename:
longname "CGadgets Tester"
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
tokenchars "GTST"
tokenid 16431
#

#platform geos201

# Libraries:
library	geos
library	ui
library ansic
library text
#library gadget
library cgadget

#
# Resources:
resource APPRESOURCE ui-object
resource INTERFACE ui-object


