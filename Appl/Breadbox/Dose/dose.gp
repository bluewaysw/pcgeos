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

platform geos201

# Libraries:
library geos
library ui
library ansic
library text
library math
library gadgets

exempt gadgets

#
# Resources:
resource AppResource ui-object
resource Interface ui-object
resource SetupResource ui-object
resource SaveResource ui-object
resource MealResource ui-object
resource LogResource ui-object
resource AvgResource ui-object
resource CarbsResource ui-object
resource FavsResource ui-object
resource GraphResource ui-object
resource OtherHistResource ui-object
resource BMIResource ui-object
resource Strings lmem discardable read-only

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

