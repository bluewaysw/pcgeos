# Geode Parameters for "MyChart Application"
# 
# REVISION HISTORY:
#       Name    Date            Description
#       ----    ----            -----------
#       ??		??		        Initial version
#		RainerB	4/27/2022		Resource names adjusted for Watcom compatibility
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

resource AppResource ui-object
resource Interface ui-object
resource Content   object read-only shared
resource Display   ui-object read-only shared
resource DocGroup  object

export MCProcessClass
export MCChartClass
export MCDocumentClass
