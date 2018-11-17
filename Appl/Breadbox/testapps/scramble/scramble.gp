##############################################################################
#
#
# PROJECT:	Test Applications
# MODULE:	Scrambler
# FILE:		scramble.gp
#
# AUTHOR:		jfh, 6/02
#
#
##############################################################################
#
# Permanent name:
name scramble.app
#
# Long filename:
longname "Scrambler"
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


