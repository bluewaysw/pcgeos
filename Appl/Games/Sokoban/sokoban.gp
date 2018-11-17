##############################################################################
#
#	Copyright (c) GeoWorks 1990 -- All Rights Reserved
#
# PROJECT:	PC/GEOS
# MODULE:	Sokoban
# FILE:		sokoban.gp
#
# AUTHOR:	Steve Yegge (11/10/92)
#
# DESCRIPTION:	Geode parameters file for sokoban.app
#
# RCS STAMP:
#	
#	$Id: sokoban.gp,v 1.1 97/04/04 15:13:16 newdeal Exp $
#
##############################################################################
#
# Permanent name: is required by Glue to set the permanent name and extension
# of the geode. The permanent name of a library is what goes in the imported
# library table of a geode (along with the protocol number). It is also
# what Swat uses to name the patient.
#
name sokoban.app
#
# Long filename: this name can displayed by geoManager, and is used to identify
# the application for inter-application communication.
#
longname "Sokoban"
#
# Specify geode type: is an application, will have its own process (thread),
# and is multi-launchable.
#
type	appl, process, single
#
# Specify stack size.
#
stack 2000

heapspace 60k

#
# Specify class name for application process. Methods sent to the Application's
# process will be handled by the DockProcessClass, which is defined
# in dock.asm.
#
class	SokobanProcessClass
#
# Specify application object. This is the object in the .ui file which serves
# as the top-level UI object in the application. See dock.ui.
#
appobj	SokobanApp
#
# Token: this four-letter name is used by geoManager to locate the icon for this
# application in the database.
#
tokenchars "SOKO"
tokenid 0
#
# Libraries: list which libraries are used by the application.
#
library	geos
library	ui

ifdef GP_HIGH_SCORES
library game
endif

#
# Resources: list all resource blocks which are used by the application.
# (standard discardable code resources do not need to be mentioned).
#
resource AppResource 		ui-object
resource Interface 		ui-object
resource MapResource 		object
resource Screens1To15	 	ui-object read-only shared
resource Screens16To30	 	ui-object read-only shared
resource Screens31To45	 	ui-object read-only shared
resource Screens46To60		ui-object read-only shared
resource Screens61To75		ui-object read-only shared
resource Screens76To90		ui-object read-only shared
resource Bitmaps		shared lmem read-only

ifdef GP_DOCUMENT_CONTROL
resource DocUI 			object
endif

ifdef GP_LEVEL_EDITOR
resource SokobanStrings		shared lmem read-only
endif

ifdef GP_PLAY_SOUNDS
resource StartGameSoundResource		data
resource SaveBagSoundResource		data
resource FinishLevelSoundResource	data
endif

ifdef GP_HIGH_SCORES
resource HighScoreSoundResource		data
endif

#ifndef GP_NO_COLOR
#resource AppLCMonikerResource	lmem read-only shared
#resource AppSCMonikerResource	lmem read-only shared
#resource AppYCMonikerResource	lmem read-only shared
#endif

#resource AppLMMonikerResource	lmem read-only shared
#resource AppSMMonikerResource	lmem read-only shared
#resource AppSCGAMonikerResource	lmem read-only shared
#resource AppYMMonikerResource	lmem read-only shared
#resource AppTMMonikerResource	lmem read-only shared
#resource AppTCGAMonikerResource	lmem read-only shared
resource AppMonikerResource lmem read-only shared

#
# Export classes.
#
export	MapContentClass
export	SokobanApplicationClass
export	MapViewClass

ifdef GP_HIGH_SCORES
export	SokobanHighScoreClass
endif

ifdef GP_LEVEL_EDITOR
export  EditContentClass
endif
