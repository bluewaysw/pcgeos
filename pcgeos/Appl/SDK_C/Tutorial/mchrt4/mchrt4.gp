# Geode Parameters for "MyChart Application"
# 
# $Id: mchrt4.gp,v 1.1 97/04/04 16:39:30 newdeal Exp $
name mchrt.app

longname "MyChart"

type	appl, process, single

class	MCProcessClass

appobj	MCApp

tokenchars "SAMP"
tokenid 8

heapspace 4903

library	geos
library	ui

resource APPRESOURCE ui-object
resource INTERFACE ui-object
resource CONTENT   object read-only shared
resource DISPLAY   ui-object read-only shared
resource DOCGROUP  object

export MCProcessClass
export MCChartClass
export MCDocumentClass
