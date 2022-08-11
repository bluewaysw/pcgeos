# Geode parameters for "MyChart Application"
#
# REVISION HISTORY:
#       Name    Date            Description
#       ----    ----            -----------
#       ??		??		        Initial version
#		RainerB	4/27/2022		Resource names adjusted for Watcom compatibility
#
# $Id: mchrt3.gp,v 1.1 97/04/04 16:39:28 newdeal Exp $
name mchrt.app

longname "MyChart"

type	appl, process, single

class	MCProcessClass

appobj	MCApp

tokenchars "MCht"
tokenid 0

library	geos
library	ui

resource AppResource ui-object
resource Interface ui-object
resource Content   object

export MCProcessClass
export MCChartClass

