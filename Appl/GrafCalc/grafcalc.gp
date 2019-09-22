name grafcalc.app
longname "GrafCalc"
tokenchars "GCal"
tokenid 16484
type	appl, process, single

class	GCalcProcessClass

appobj	GCalcApp

stack 3000
heapspace 2300

library	geos
library	ui
library 	parse
#library 	ssheet
library 	math
library 	ansic
library 	color

resource AppResource ui-object
resource Interface ui-object
resource FunktionInterface ui-object
resource TabellenInterface ui-object
resource DiagramResource ui-object
resource ToolMonikerResource lmem read-only shared
resource IconResource lmem read-only shared

export TriggerDataTriggerClass
export GCalcTextClass

usernotes "Copyright 2015 - Wilfried Konczynski"
