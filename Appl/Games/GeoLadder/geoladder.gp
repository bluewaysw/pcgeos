##############################################################################
# Copyright 2019 Andreas Bollhalder
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
##############################################################################


##############################################################################
#
# Copyright (c) 2010-2024 by YoYu-Productions
#
# PROJECT:      GeoLadder
# MODULE:       GLUE parameter file
# FILE:         geoladder.gp
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
resource GAME lmem
resource SONG_DONE lmem
resource SONG_HIGH lmem
resource TEXT lmem

export LadderApplicationClass
export LadderPrimaryClass

export SoundWorkerClass

export LadderScreenClass
export LadderTextClass
export LadderValueClass
export LadderRankClass
export LadderLevelClass
export LadderActorsClass
export LadderInputClass

usernotes "A clone of the game Ladder."


# End of 'geoladder.gp'
