##############################################################################
#
#
# PROJECT:	Test Applications
# MODULE:	Serial Number Generator
# FILE:		sngen.gp
#
# AUTHOR:		jfh, 4/02
#
#
##############################################################################
#
# Permanent name:
name sngen.app
#
# Long filename:
longname "SerNum Generator"
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

heapspace 8000
#
# process stack space (default is 2000):
stack 6000

platform geos201

# Libraries:
library	geos
library	ui
library ansic
library math

#
# Resources:
resource APPRESOURCE ui-object
resource INTERFACE ui-object


