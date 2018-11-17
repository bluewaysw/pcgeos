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
resource APPRESOURCE ui-object
resource INTERFACE ui-object
resource BOARDBLOCK object
resource APPMONIKERRESOURCE lmem read-only shared
resource ACORNERSRESOURCE data
resource AUPPERRESOURCE data
resource ALEFTRESOURCE data
resource ARIGHTRESOURCE data
resource ABOTTOMRESOURCE data
resource BCORNERSRESOURCE data
resource BUPPERRESOURCE data
resource BLEFTRESOURCE data
resource BRIGHTRESOURCE data
resource BBOTTOMRESOURCE data
resource TREASURERESOURCE data
resource CURSORRESOURCE data shared
resource QTIPSRESOURCE ui-object

#
# Other classes
#
export  BorderInteractionClass
export  BattleInteractionClass
export  BattleBoardClass
export  PlayerBattleBoardClass
export  ComputerBattleBoardClass
export  PlayerBattlePieceClass
