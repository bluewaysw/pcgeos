##############################################################################
#
#
# PROJECT:	Test Applications
# MODULE:	Insulin Dose Calculator
# FILE:		carbs.gp
#
# AUTHOR:		jfh, 4/04
#
#
##############################################################################
#
# Permanent name:
name carbs.app
#
# Long filename:
longname "Carbs"
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


