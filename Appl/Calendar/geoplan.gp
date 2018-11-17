##############################################################################
#
#	Copyright (c) GeoWorks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Appl/Calendar
# FILE:		geoplan.gp
#
# AUTHOR:	Don, 10/89
#
#
# Parameters file for: geoplan.geo
#
#	$Id: geoplan.gp,v 1.2 97/07/01 12:07:46 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name geoplanner.app
#
# Long filename
#
longname "Calendar"
#
# Token information
#
tokenchars "PLNR"
tokenid 0
#
# Specify geode type
#
type	appl, process
#
# Specify stack size
#
stack	2000
#
# Specify class name for process
#
class	GeoPlannerClass
#
# Specify application object
#
appobj	Calendar
#
# Import library routine definitions
#
library	geos
library	ui
library text
library spool
library config

ifdef	GP_USE_INK
library pen
endif

#
# Define resources other than standard discardable code
#
resource FixedCode		code read-only shared fixed
resource InitCode		code read-only shared discard-only preload

resource AppResource		ui-object
resource PrimaryInterface	ui-object
resource Interface		ui-object
resource MenuBlock		ui-object
resource PrintBlock		ui-object
resource PrefBlock		ui-object
resource SetAlarmBlock		ui-object
resource RepeatBlock		ui-object
resource OptionsBlock		ui-object
resource DocumentBlock		object
resource DPResource		object
resource AlarmTemplate		ui-object read-only

ifdef DO_PIZZA
resource HolidayBlock		ui-object
resource HolidayStrings		lmem read-only shared
endif


resource AppSCMonikerResource	lmem read-only shared
resource AppTCMonikerResource	lmem read-only shared

resource DataBlock		lmem read-only shared
resource ErrorBlock		lmem read-only shared
#
# Define exported entry points (for object saving)
#
export YearClass
export MonthClass
export DayPlanClass
export DayEventClass
export PrintEventClass
export MyTextClass
export CustomSpinClass
export DateArrowsClass
export MonthValueClass
export MyPrintClass
export MySearchClass
export SizeControlClass
export ReminderClass
export CalendarPrimaryClass
export CalendarAppClass
export CalendarSRCClass
export CalendarTimeDateControlClass

ifdef DO_PIZZA
export SetHolidayInteractionClass
endif

