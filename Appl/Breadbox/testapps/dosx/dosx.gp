##############################################################################
#
#
# PROJECT:	Test Applications
# MODULE:	DosExec applet
# FILE:		dosx.gp
#
# AUTHOR:		jfh, 4/14
#
#
##############################################################################
#
# Permanent name:
name dosx.app
#
# Long filename:
longname "DosExec Sample"
#
# Specify geode type: ,
type	appl, process, single
#
# Specify class name for application process.
class	DosExecProcClass
#
# Specify application object.
appobj	DosExecApp
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


