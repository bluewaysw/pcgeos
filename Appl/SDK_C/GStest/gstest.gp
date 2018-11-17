##############################################################################
#
#	Copyright (c) Geoworks 1991-92 -- All Rights Reserved
#
# PROJECT:	Sample Applications
# MODULE:	GString test application
# FILE:		gstest.gp
#
# AUTHOR:	Josh Putnam, 5/92
#
# REVISION HISTORY:
#       Name    Date            Description
#       ----    ----            -----------
#       josh    5/92            Initial version
#       NF      9/26/96         Made tokenchars unique
#
# DESCRIPTION:
#       This file contains Geode definitions for the "Gstest" sample
#       application. This file is read by the GLUE linker to
#       build this application.
#
# RCS STAMP:
#	$Id: gstest.gp,v 1.1 97/04/04 16:38:40 newdeal Exp $
#
##############################################################################
#
# Permanent name: is required by Glue to set the permanent name and extension
# of the geode. The permanent name of a library is what goes in the imported
# library table of a geode (along with the protocol number). It is also
# what Swat uses to name the patient.
#
name     gstest.app
#
# Long filename: this name can displayed by geoManager, and is used to identify
# the application for inter-application communication.
#
longname "C Gstest"
#
# Specify geode type: is an application, will have its own process (thread),
# and is not multi-launchable.
#
type	appl, process, single
#
# Specify class name for application process. Methods sent to the Application's
# process will be handled by the GstestProcessClass, which is defined
# in Gstest.asm.
#
class	GstestProcessClass
#
# Specify application object. This is the object in the .ui file which serves
# as the top-level UI object in the application.
#
appobj	GstestApp
#
# Token: this four-letter name is used by geoManager to locate the icon for this
# application in the database.
#
tokenchars "GTST"
tokenid    8
#
# Heapspace: This is roughly the non-discardable memory usage (in words)
# of the application and any transient libraries that it depends on,
# plus an additional amount for thread activity. To find the heapspace
# for an application, use the Swat "heapspace" command.
#
heapspace 2389
#
# Libraries: list which libraries are used by the application.
#
library	geos
library	ui
#
# Resources: list all resource blocks which are used by the application.
# (standard discardable code resources do not need to be mentioned).
# Don't change these to ui-object or crash will occur.
#
resource APPRESOURCE object
resource INTERFACE   object

