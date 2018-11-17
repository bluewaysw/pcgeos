##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	
# FILE:		bigcalc.gp
#
# AUTHOR:	Christian Puscasiu, May 11, 1992
#
#
#	$Id: bigcalc.gp,v 1.1 97/04/04 14:38:06 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name bigcalc.app
#
# Long Name
#
longname "Calculator"
#
# DB Token
#
tokenchars "BCAL"
tokenid 0
#
# Specify geode type
#
type	appl, process, single, discardable-dgroup
#
# Specify class name for process
#
class	BigCalcProcessClass
#
# Specify application object
#
appobj BigCalculatorAppObj
#
# Need some stack
#

stack	3000

# Adjusted for new heapspace usage allocation method.  --JimG 3/17/95
#
heapspace	2300	#Includes 4500 bytes of paper tape information
#
# Import library routine definitions
#
library	geos
library ui
library math
library parse

#
# Special resource definitions
#
resource AppResource 			object
resource BigCalcClassStructures		fixed	shared 	read-only
resource MainInterface			object
resource ExtraResource			object
resource MemoryResource			object
resource CalcResource			object
resource ExtensionResource		object
resource PCFResource			object
resource DescriptionResource		lmem	read-only	shared
resource DataResource			lmem	read-only	shared
resource FixedArgsPCFTemplateResource	object	read-only
resource PCFLineResource		object	read-only
resource VariableArgsPCFTemplateResource object	read-only

#
# resources for the Monikers
#
resource AppLCMonikerResource		lmem	read-only	shared
resource AppLMMonikerResource		lmem	read-only	shared
resource AppSCMonikerResource		lmem	read-only	shared
resource AppSMMonikerResource		lmem	read-only	shared
resource AppYCMonikerResource		lmem	read-only	shared
resource AppYMMonikerResource		lmem	read-only	shared
resource AppSCGAMonikerResource		lmem	read-only	shared

#
# resources for the Tools
#
#resource ModeSCMonikerResource		lmem	read-only	shared
#resource ModeSMMonikerResource		lmem	read-only	shared
#resource ModeSCGAMonikerResource	lmem	read-only	shared

#
# Export classes for state saving
#
export BigCalcProcessClass
export BigCalcApplicationClass

export PCFHolderClass

export InputFieldClass
export CalcInputFieldClass
export MemoryInputFieldClass
export PaperRollClass
export CustBoxClass
export CalcEngineClass			
export RPNEngineClass
export InfixEngineClass

export PreCannedFunctionClass
export PCFChooserClass
export FixedArgsPCFClass
export VariableArgsPCFClass
export FAPCFInputFieldClass
export VAPCFInputFieldClass
export PCFResultDisplayClass
export VAItemGroupClass
export VAItemClass

export SetExchangeRateClass
export CalcTriggerClass
export CalcBooleanClass
export CalcWorksheetListClass
