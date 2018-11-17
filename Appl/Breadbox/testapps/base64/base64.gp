##############################################################################
#
#
# PROJECT:	Test Applications
# MODULE:	Base64
# FILE:		base64.gp
#
# AUTHOR:		jfh, 6/02
#
#
##############################################################################
#
# Permanent name:
name base64.app
#
# Long filename:
longname "Base-64"
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
library bbxmlib

exempt bbxmlib

#
# Resources:
resource APPRESOURCE ui-object
resource INTERFACE ui-object


