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

resource APPRESOURCE ui-object
resource INTERFACE ui-object
resource FUNKTIONINTERFACE ui-object
resource TABELLENINTERFACE ui-object
resource DIAGRAMRESOURCE ui-object
resource TOOLMONIKERRESOURCE lmem read-only shared
resource ICONRESOURCE lmem read-only shared

export TriggerDataTriggerClass
export GCalcTextClass

usernotes "Copyright 2015 - Wilfried Konczynski"
