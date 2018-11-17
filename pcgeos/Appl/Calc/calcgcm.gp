##############################################################################
#
#	Copyright (c) GeoWorks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Screen Dump Utility
# FILE:		dump.gp
#
# AUTHOR:	Adam, 11/89
#
#
# Parameters file for: dump.geo
#
#	$Id: calcgcm.gp,v 1.1 97/04/04 14:46:54 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name calc.gcm
#
# Specify geode type
#
type	process, appl, has-gcm
#
# Don't need such a mondo stack for this thing -- we don't do much after all
#
stack	1000
#
# Specify class name and application object for process
#
class	CalcClass
appobj	Calculator
#
# Import library routine definitions
#
library	geos
library ui
#
# Desktop-related definitions
#
longname "Calculator Appliance"
tokenchars "CALc"
tokenid 0
#
# Special resource definitions
#
resource AppResource	ui-object
resource Interface	ui-object
resource Infix		ui-object
resource HelpUI		ui-object
resource AppLCMonikerResource ui-object read-only discardable
resource AppSCMonikerResource ui-object read-only discardable
resource AppLMMonikerResource ui-object read-only discardable
resource AppSMMonikerResource ui-object read-only discardable
resource AppLCGAMonikerResource ui-object read-only discardable
resource AppSCGAMonikerResource ui-object read-only discardable

#
# Export classes for state saving
#
export	CalcEngineClass
export 	CalcDisplayClass
export	CalcDataTriggerClass
export	CalcBogusInteractionClass
export	CalcBogusPrimaryClass
