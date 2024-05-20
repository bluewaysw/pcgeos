##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC/GEOS
# MODULE:	Mine (Sample PC/GEOS application)
# FILE:		mine.gp
#
# AUTHOR:	Insik Rhee  1/92
#
# DESCRIPTION:	This file contains Geode definitions for the "Mine" sample
#		application. This file is read by the GLUE linker to
#		build this application.
#
# RCS STAMP:
#	$Id: mine.gp,v 1.1 97/04/04 14:52:02 newdeal Exp $
#
##############################################################################
#
# Permanent name: is required by Glue to set the permanent name and extension
# of the geode. The permanent name of a library is what goes in the imported
# library table of a geode (along with the protocol number). It is also
# what Swat uses to name the patient.
#
name mine.app
#
# Long filename: this name can displayed by geoManager, and is used to identify
# the application for inter-application communication.
#
longname "Mine Sweeper"
#
# Specify geode type: is an application, will have its own process (thread),
# and is not multi-launchable.
#
type	appl, process, single
#

# Specify class name for application process. Methods sent to the Application's
# process will be handled by the MineProcessClass, which is defined
# in mine.asm.
#
class	MineProcessClass
#
# Specify application object. This is the object in the .ui file which serves
# as the top-level UI object in the application. See mine.ui.
#
appobj	MineApp

heapspace 3955
#
# Token: this four-letter name is used by geoManager to locate the icon for this
# application in the database.
#
tokenchars "MINE"
tokenid 0

#
# Libraries: list which libraries are used by the application.
#
library	geos
library	game
library	ui
#
# Resources: list all resource blocks which are used by the application.
# (standard discardable code resources do not need to be mentioned).
#
resource AppResource 		object
resource Interface 		object
resource AppVisObjectResource 	object

resource AppMonikerResource lmem shared read-only

resource MineGameWonSoundBuffer          data
resource MineHitSoundBuffer              data
resource MineFlagSoundBuffer             data

export MineApplicationClass
export MineFieldClass

