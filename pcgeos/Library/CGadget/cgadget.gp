##############################################################################
#
#	Copyright (c) Geoworks 1994 -- All Rights Reserved
#
# PROJECT:	Interface Gadgets
# FILE:		gadgets.gp
#
# AUTHOR:	Skarpi Hedinsson, Jun 24, 1994
#
#
# 
#
#	$Id: gadgets.gp,v 1.1 97/04/04 17:59:57 newdeal Exp $
#
##############################################################################
#
name cgadget.lib

library geos
library ui
library ansic

#
# Specify geode type
#
type library, single, c-api

#
# Desktop-related things
#
longname	"C Interface Gadgets"
tokenchars	"CXGD"
tokenid		0

#
# Define resources other than standard discardable code
#
#nosort
#resource VisMonikerUtilsCode		read-only code shared
#resource GadgetsRepeatTriggerCode	read-only code shared
#resource GadgetsSelectorCode 		read-only code shared
#resource GadgetsControlInfo		read-only shared
#resource GadgetsClassStructures		fixed read-only shared
#resource DateSelectorUI 		ui-object read-only shared
resource DATEINPUTUI			ui-object read-only shared
#resource StopwatchUI			ui-object read-only shared
resource TIMEINPUTUI			ui-object read-only shared
resource CONTROLSTRINGS 		lmem
#resource GadgetsStrings			lmem read-only shared
#resource GadgetsBatteryIndicatorCode	read-only code shared

#
# Library entry point.
#
#entry	GadgetsEntry

#
# Export classes
#
export RepeatTriggerClass
#export DateSelectorClass
export DateInputClass
export TimeInputClass
#export StopwatchClass
#export TimerClass
export DateInputTextClass
export TimeInputTextClass
#export BatteryIndicatorClass

#incminor NewFocusProtocol


