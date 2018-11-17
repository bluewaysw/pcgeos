##############################################################################
#
#       Copyright (c) Derrick Renaud 1994 -- All Rights Reserved
#
# PROJECT:      Sample Applications
# MODULE:       Battle Raft app
# FILE:         battle.gp
#
# AUTHOR:       Derrick Renaud  1/94
#
# DESCRIPTION:  This file contains the geode parameters for the Battle Raft
#               application.
#
#IMPORTANT:
#       This example is written for the PC/GEOS V2.0 API. 
#
#
##############################################################################
#
# Permanent name: is required by Glue to set the permanent name and extension
# of the geode. The permanent name of a library is what goes in the imported
# library table of a geode (along with the protocol number). It is also
# what Swat uses to name the patient.
#
name battle.app
#
# Long filename: this name can displayed by geoManager, and is used to identify
# the application for inter-application communication.
#
longname "Battle Raft"
#
# Specify geode type: is an application, will have its own process (thread),
# and is not multi-launchable.
#
type    appl, process, single
#
# Specify class name for application process. Methods sent to the Application's
# process will be handled by the TicTacProcessClass, which is defined
# in tictac.goc.
#
class   BattleProcessClass
#
# Specify application object. This is the object in the .goc file which serves
# as the top-level UI object in the application. See hello.goc.
#
appobj  BattleApp
#
# Token: this four-letter name is used by geoManager to locate the icon for this
# application in the database.
#
tokenchars "Btlr"
tokenid 16431
#
# Libraries: list which libraries are used by the application.
#
platform gpc12
library geos
library ui
library math
library sound
library ansic

exempt math
exempt sound
exempt borlandc

#
# Resources: list all resource blocks which are used by the application.
# (standard discardable code resources do not need to be mentioned).
#
resource APPRESOURCE ui-object
resource INTERFACE ui-object
resource BOARDBLOCK object
resource APPMONIKERRESOURCE lmem read-only shared

#
# Other classes
#
export  BattleBoardClass
export  PlayerBattleBoardClass
export  ComputerBattleBoardClass
export  PlayerBattlePieceClass
