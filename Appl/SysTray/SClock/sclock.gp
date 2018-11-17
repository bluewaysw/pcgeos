##############################################################################
#
#	Copyright (c) Designs in Light 2002 -- All Rights Reserved
#
# PROJECT:	sclock
# FILE:		sclock.gp
#
##############################################################################
#
name sclock.app
type appl, process, single

class	ClockProcessClass
appobj 	ClockApp

longname	"SysTray Clock"
tokenchars	"SCLK"
tokenid		0

#
# Specify stack size
#
stack	2000

library geos
library ui

resource AppResource	object
resource Code		shared, read-only, code

export	ClockApplicationClass
