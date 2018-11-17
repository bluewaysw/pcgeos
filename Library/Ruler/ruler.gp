##############################################################################
#
#	Copyright () GeoWorks 1991 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Ruler
# FILE:		ruler.gp
#
# AUTHOR:	Gene, 2/91
#
#
# Parameters file for: ruler.geo
#
#	$Id: ruler.gp,v 1.1 97/04/07 10:42:48 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name ruler.lib

#
# Import other library definitions
#
library geos
library ui

#
# Specify geode type
#
type	library, single

#
# Desktop-related things
#
longname	"Ruler Library"
tokenchars	"RULE"
tokenid		0

#
# Define the library entry point
#
# We have none, as all it does is return carry clear

#
# Define resources other than standard discardable code
#
nosort
resource RulerBasicCode			code read-only shared
resource RulerGridGuideConstrainCode	code read-only shared

ifndef GP_NO_CONTROLLERS
resource RulerUICode			code read-only shared
resource RulerUICommon			code read-only shared
resource RulerTypeControlUI		ui-object read-only shared
resource ControlStrings 		lmem read-only shared
resource GuideCreateControlUI		ui-object read-only shared
resource RulerGuideControlUI		ui-object read-only shared
resource RulerGridControlUI		ui-object read-only shared
resource RulerShowControlUI		ui-object read-only shared
endif		# ndef GP_NO_CONTROLLERS

resource RulerCCode			code read-only shared
resource RulerClassStructures		fixed read-only shared

ifdef GP_FULL_EXECUTE_IN_PLACE
resource RulerControlInfoXIP		read-only shared
endif

#
# Exported Classes
#
export VisRulerClass
export RulerContentClass
export RulerViewClass
export RulerTypeControlClass
export GuideCreateControlClass
export RulerGuideControlClass
export RulerGridControlClass
export RulerShowControlClass

#
# Exported routines
#
export	RulerScaleDocToWinCoords
export	RulerScaleWinToDocCoords

incminor

#
# C stubs to export
#
publish	RULERSCALEDOCTOWINCOORDS
publish	RULERSCALEWINTODOCCOORDS
#
# XIP-enabled
#
