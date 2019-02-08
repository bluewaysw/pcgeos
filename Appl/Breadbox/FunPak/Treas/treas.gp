##############################################################################
#
#       Copyright (c) Derrick Renaud 1994 -- All Rights Reserved
#
# PROJECT:      Sample Applications
# MODULE:       Battle Raft app
# FILE:         battle.gp
#
# AUTHOR:       Derrick Renaud  1/94
#               10/00  Changed name and files to treas (Pirates Treasure Hunt)
# DESCRIPTION:  This file contains the geode parameters for the Battle Raft
#               application.
#
##############################################################################
#
# Permanent name:
name treas.app
#
# Long filename:
longname "Treasure Hunt"
#
# Specify geode type:
type    appl, process, single
#
# Specify class name for application process.
#
class   BattleProcessClass
#
# Specify application object.
appobj  BattleApp
#
# Token:
tokenchars "PTH1"
tokenid 16431
#
# Libraries:
platform gpc12
library geos
library ui
library math
library ansic
library sound

exempt math
exempt borlandc
exempt sound

#
# Resources: 
resource AppResource ui-object
resource Interface ui-object
resource BoardBlock object
resource AppMonikerResource lmem read-only shared
resource ACornersResource data
resource AUpperResource data
resource ALeftResource data
resource ARightResource data
resource ABottomResource data
resource BCornersResource data
resource BUpperResource data
resource BLeftResource data
resource BRightResource data
resource BBottomResource data
resource TreasureResource data
resource CursorResource data shared
resource QTipsResource ui-object

#
# Other classes
#
export  BorderInteractionClass
export  BattleInteractionClass
export  BattleBoardClass
export  PlayerBattleBoardClass
export  ComputerBattleBoardClass
export  PlayerBattlePieceClass
