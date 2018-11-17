##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC/GEOS
# MODULE:	Hearts (Trivia Project)
# FILE:		hearts.gp
#
# AUTHOR:	Peter Weck, Jan 19, 1993
#
# DESCRIPTION:	This file contains Geode definitions for the "Hearts"
#		application. This file is read by the GLUE linker to
#		build this application.
#
# RCS STAMP:
#	$Id: hearts.gp,v 1.1 97/04/04 15:19:20 newdeal Exp $
#
##############################################################################
#
# Permanent name: is required by Glue to set the permanent name and extension
# of the geode. The permanent name of a library is what goes in the imported
# library table of a geode (along with the protocol number). It is also
# what Swat uses to name the patient.
#
name hearts.app
#
# Long filename: this name can displayed by geoManager, and is used to identify
# the application for inter-application communication.
#
longname "Hearts"
#
# Specify geode type: is an application, will have its own process (thread),
# and is not multi-launchable.
#
type	appl, process, single
#
# Specify heapspace requirement
#
heapspace 4500
#
# Specify class name for application process. Methods sent to the Application's
# process will be handled by the HeartsProcessClass, which is defined
# in hearts.asm.
#
class	HeartsGenProcessClass
#
# Specify application object. This is the object in the .ui file which serves
# as the top-level UI object in the application. See hearts.ui.
#
appobj	HeartsApp
#
# Token: this four-letter name is used by geoManager to locate the icon for this
# application in the database.
#
tokenchars "HRTS"
tokenid 0
#
# Libraries: list which libraries are used by the application.
#
library	geos
library	ui
library sound
library wav
library cards
#
# Resources: list all resource blocks which are used by the application.
# (standard discardable code resources can be ommitted).
#
resource AppResource ui-object
resource StuffResource ui-object
resource Interface ui-object
resource StringResource 	lmem shared read-only

#resource AppYMMonikerResource read-only shared lmem
resource AppMonikerResource	lmem read-only shared

#
# Export classes: list classes which are defined by the application here.
#
export HeartsGameClass
export HeartsDeckClass
export HeartsHandClass
export HeartsApplicationClass
