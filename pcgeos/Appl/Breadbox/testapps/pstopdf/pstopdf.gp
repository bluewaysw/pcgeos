##############################################################################
#
#
# PROJECT:	Test Applications
# MODULE:	PS to PDF applet
# FILE:		ps2pdf.gp
#
# AUTHOR:		jfh, 4/14
#
#
##############################################################################
#
# Permanent name:
name pstopdf.app
#
# Long filename:
longname "PS to PDF"
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
library ps2pdf
#
# Resources:
resource APPRESOURCE ui-object
resource INTERFACE ui-object


