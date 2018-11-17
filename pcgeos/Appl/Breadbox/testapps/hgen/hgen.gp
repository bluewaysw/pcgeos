##############################################################################
#
#
# PROJECT:	Test Applications
# MODULE:	Insulin Dose Calculator
# FILE:		hgen.gp
#
# AUTHOR:		jfh, 5/04
#
#
##############################################################################
#
# Permanent name:
name hgen.app
#
# Long filename:
longname "History Generator"
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


