##############################################################################
#
# Copyright (c) 2013 by YoYu-Productions
#
# PROJECT:      GeoLadder
# MODULE:       GLUE parameter file
# FILE:         LADDER.GP
#
# AUTHOR:       Andreas Bollhalder
#
##############################################################################


name ladder.app
longname "GeoLadder"

tokenchars "GLAD"
tokenid 16502

type appl, process, single

class LadderProcessClass

appobj LadderApplication

# Heapspace is unneeded (but shouldn't hurt)
# heapspace 2514

library geos
library ui
library ansic
library math
library sound

resource APPLICATION ui-object
resource INTERFACE ui-object
resource ICON ui-object read-only shared
resource PLAY lmem
resource TEXT lmem

export LadderApplicationClass

export LadderScreenClass
export LadderTextClass
export LadderValueClass
export LadderRankClass
export LadderLevelClass
export LadderActorsClass
export LadderInputClass

usernotes "The game Ladder."


# End of LADDER.GP
