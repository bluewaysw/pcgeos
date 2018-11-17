##############################################################################
#
#	Copyright (c) GeoWorks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	GeoWorks BlackJack
# FILE:		bjack.gp
#
# AUTHOR:	Bryan Chow
#
# DESCRIPTION:
#
# RCS STAMP:
#$Id: bjack.gp,v 1.1 97/04/04 15:46:15 newdeal Exp $
#
##############################################################################
#
# Permanent name: is required by Glue to set the permanent name and extension
# of the geode. The permanent name of a library is what goes in the imported
# library table of a geode (along with the protocol number). It is also
# what Swat uses to name the patient.
#
name bjack.app
#
# Long filename: this name can displayed by geoManager, and is used to identify
# the application for inter-application communication.
#
longname "Black Jack"
#
# Specify geode type: is an application, will have its own process (thread),
# and is not multi-launchable.
#
type	appl, process, single
#
# Specify heapspace requirement
#
heapspace 5000
#
#
# Specify class name for application process. Methods sent to the Application's
# process will be handled by the YodaProcessClass, which is defined in yoda.asm.
#
class	BJackProcessClass
#
# Specify application object. This is the object in the .ui file which serves
# as the top-level UI object in the application. See yoda.ui.
#
appobj	BJackApp
#
# Token: this four-letter name is used by geoManager to locate the icon for this
# application in the database.
#
tokenchars "BJAK"
tokenid 0
#
# Libraries: list which libraries are used by the application.
#
library	geos
library	ui
library game
library sound
library wav
library cards

#
# Resources: list all resource blocks which are used by the application.
# (standard discardable code resources can be ommitted).
#
resource AppResource ui-object
resource StuffResource object
resource Interface ui-object

#resource AppYMMonikerResource lmem shared read-only
resource AppMonikerResource	lmem read-only shared


#
# Export classes: list classes which are defined by the application here.
#
export BJackGameClass
export MyDeckClass
export BJackHighScoreClass
export BJackInteractionClass
