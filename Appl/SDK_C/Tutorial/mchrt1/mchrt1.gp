# Geode Parameters for MyChart Application
#
# $Id: mchrt1.gp,v 1.1 97/04/04 16:39:23 newdeal Exp $

name mchrt.app

longname "MyChart"

type	appl, process

class	MCProcessClass

appobj	MCApp

tokenchars "MCht"
tokenid 0

library	geos
library	ui

resource APPRESOURCE ui-object
resource INTERFACE ui-object
