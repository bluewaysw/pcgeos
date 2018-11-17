##############################################################################
#
#
# PROJECT:	Test Applications
# MODULE:	System Checker
# FILE:		systest.gp
#
# AUTHOR:		jfh, 10/04
#
#
##############################################################################
#
# Permanent name:
name systest.app
#
# Long filename:
longname "System checker"
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
tokenchars "TEST"
tokenid 16431
#

platform geos201

# Libraries:
library	geos
library	ui
library ansic
library text
#
# Resources:
resource APPRESOURCE ui-object
resource INTERFACE ui-object


