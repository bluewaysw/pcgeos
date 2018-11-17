# Geode parameters for "MyChart Application"
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

resource APPRESOURCE ui-object
resource INTERFACE ui-object
resource CONTENT   object

export MCProcessClass
export MCChartClass

