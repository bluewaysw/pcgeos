##############################################################################
#
#	Copyright (c) Geoworks 1995 -- All Rights Reserved
#
# PROJECT:	GEOS
# MODULE:	Taipei (Trivia project:  PC GEOS application)
# FILE:		taipei.gp
#
# AUTHOR:	Jason Ho, 1/23
#
# DESCRIPTION:	This file contains Geode definitions for the "Taipei" 
#		application. This file is read by the GLUE linker to
#		build this application.
#
# RCS STAMP:
#	$Id: tiles.gp,v 1.1 97/04/04 15:14:43 newdeal Exp $
#
##############################################################################
#
# Permanent name: is required by Glue to set the permanent name and extension
# of the geode. The permanent name of a library is what goes in the imported
# library table of a geode (along with the protocol number). It is also
# what Swat uses to name the patient.
#
name taipei.app
#
# Long filename: this name can displayed by geoManager, and is used to identify
# the application for inter-application communication.
#

longname "Taipei Mahjongg"

#
# Specify geode type: is an application, will have its own process (thread),
# and is multi-launchable.
#
type	appl, process, single

#
# Specify class name for application process. Methods sent to the Application's
# process will be handled by the ItemProcessClass, which is defined
# in item.asm.
#
class	TaipeiProcessClass

#
# Specify application object. This is the object in the .ui file which serves
# as the top-level UI object in the application. See taipei.ui.
#
appobj	TaipeiApp

#
# I didn't really measure this -- I just arbitrarily
# picked double the Jedi version.  If you really care
# about it, measure it yourself.
#
heapspace  46k

#
# Token: this four-letter name is used by geoManager to locate the
# icon for this application in the database.
#
tokenchars "TPMJ"
tokenid 0

#
# Libraries: list which libraries are used by the application.
#
library	geos
library	ui

library game

#
# Code Resources: these are all read-only and sharable by multiple instances
# of this application.
#
resource CommonCode		code read-only shared
#
# Resources: list all resource blocks which are used by the application.
# (standard discardable code resources do not need to be mentioned).
#
resource AppResource	ui-object
resource Interface	ui-object

#
# Notice that the AppInterface resource runs objects under the application
# thread, and therefore is not of type "ui-object".
#
resource AppInterface	object

#
# data resource in lmem, Data not read-only
#
resource DataResource	lmem shared
resource BitmapResource	lmem shared read-only
resource TaipeiClassStructures fixed read-only shared
# resource DocUI		object

resource AppMonikerResource	lmem read-only shared

#
# Must export the classes...
#
export	TaipeiContentClass
export	TaipeiTileClass
export	TaipeiApplicationClass
