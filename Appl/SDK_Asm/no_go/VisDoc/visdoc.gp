##############################################################################
#
#	Copyright (c) GeoWorks 1991, 1990 -- All Rights Reserved
#
# PROJECT:	PC/GEOS
# MODULE:	VisDoc
# FILE:		visdoc.gp
#
# AUTHOR:	Eric E. Del Sesto, June 20, 1991
#
# DESCRIPTION:	This file contains Geode definitions for the "VisDoc" sample
#		application. This file is read by the GLUE linker to
#		build this application.
#
#IMPORTANT:
#	This example is written for the PC/GEOS V1.0 API. For the V2.0 API,
#	we have new ObjectAssembly and Object-C versions.
#
# RCS STAMP:
#	$Id: visdoc.gp,v 1.1 97/04/04 16:35:08 newdeal Exp $
#
##############################################################################
#
# Permanent name: is required by Glue to set the permanent name and extension
# of the geode. The permanent name of a library is what goes in the imported
# library table of a geode (along with the protocol number). It is also
# what Swat uses to name the patient.
#
name visdoc.app
#
# Long filename: this name can displayed by geoManager, and is used to identify
# the application for inter-application communication.
#
longname "VisDoc"
#
# Specify geode type: is an application, will have its own process (thread),
# and is not multi-launchable.
#
type	appl, process
#
# Specify class name for application process. Methods sent to the Application's
# process will be handled by the VisDocProcessClass, which is defined
# in visdoc.asm.
#
class	VisDocProcessClass
#
# Specify application object. This is the object in the .ui file which serves
# as the top-level UI object in the application. See visdoc.ui.
#
appobj	VisDocApp
#
# Token: this four-letter name is used by geoManager to locate the icon for this
# application in the database.
#
tokenchars "VISD"
tokenid 0
#
# Libraries: list which libraries are used by the application.
#
library	geos
library	ui
#
# Resources: list all resource blocks which are used by the application.
# (standard discardable code resources do not need to be mentioned).
#
resource AppResource ui-object
resource Interface ui-object
#
# This next resource contains objects from VisIsoContentClass and VisClass,
# and which are run by the application thread, rather than the UI thread.
# These objects must therefore be in a separate resource.
#
resource AppThreadVisObjectResource object
#
# Here we must "export" our class definition. See the SubUI sample
# application's .gp file for more info.
#
export MyVisSquareClass
