##############################################################################
#
#	Copyright (c) GeoWorks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	GeoWorks Poker
# FILE:		gwpoker.gp
#
# AUTHOR:	Jon Witort, Bryan Chow
#
# DESCRIPTION:
#
# RCS STAMP:
#$Id: gwpoker.gp,v 1.1 97/04/04 15:20:08 newdeal Exp $
#
##############################################################################
#
# Permanent name: is required by Glue to set the permanent name and extension
# of the geode. The permanent name of a library is what goes in the imported
# library table of a geode (along with the protocol number). It is also
# what Swat uses to name the patient.
#
name gwpoker.app
#
# Long filename: this name can displayed by geoManager, and is used to identify
# the application for inter-application communication.
#
longname "Poker"
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
# Specify class name for application process. Methods sent to the Application's
# process will be handled by the YodaProcessClass, which is defined in yoda.asm.
#
class	PokerProcessClass
#
# Specify application object. This is the object in the .ui file which serves
# as the top-level UI object in the application. See yoda.ui.
#
appobj	PokerApp
#
# Token: this four-letter name is used by geoManager to locate the icon for this
# application in the database.
#
tokenchars "GPOK"
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
resource StuffResource object
resource Interface ui-object

#resource AppSMMonikerResource ui-object read-only discardable
#resource AppLMMonikerResource ui-object read-only discardable
#resource AppSCMonikerResource ui-object read-only discardable
#resource AppLCMonikerResource ui-object read-only discardable
#resource AppSCGAMonikerResource ui-object read-only discardable
resource AppMonikerResource ui-object read-only discardable

#
# Export classes: list classes which are defined by the application here.
#
export PokerGameClass
export PayoffDisplayClass
export InstDisplayClass
export PokerHighScoreClass
export PayoffVisCompClass
export PokerInteractionClass
