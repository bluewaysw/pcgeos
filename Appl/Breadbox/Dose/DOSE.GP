##############################################################################
#
#
# PROJECT:	Test Applications
# MODULE:	Dose
# FILE:		dose.gp
#
# AUTHOR:		jfh, 3/04
#
#
##############################################################################
#
# Permanent name:
name dose.app
#
# Long filename:
longname "Insulin Calc"
#
# Specify geode type: ,
type	appl, process, single
#
# Specify class name for application process.
class	DoseProcessClass
#
# Specify application object.
appobj	DoseApp
#
# Token:
tokenchars "TEST"
tokenid 16431
#
#stack 3000

platform geos20

# Libraries:
library	geos
library	ui
library ansic
library text
library math
library gadgets

exempt gadgets

#
# Resources:
resource APPRESOURCE ui-object
resource INTERFACE ui-object
resource SETUPRESOURCE ui-object
resource SAVERESOURCE ui-object
resource MEALRESOURCE ui-object
resource LOGRESOURCE ui-object
resource AVGRESOURCE ui-object
resource CARBSRESOURCE ui-object
resource FAVSRESOURCE ui-object
resource GRAPHRESOURCE ui-object
resource OTHERHISTRESOURCE ui-object
resource BMIRESOURCE ui-object
resource STRINGS lmem discardable read-only

# classes
export GenDoseApplicationClass
export GenLogPrimaryClass
export GenCarbsPrimaryClass
export GenFavsPrimaryClass
export GenGraphPrimaryClass
export VisGraphContentClass
export CarbsGenDynamicListClass
export FavsGenDynamicListClass
export GenDetailsInteractionClass
export GenFDetailsInteractionClass

