#####################################################################
#
#	Copyright (c) Geoworks 1996 -- All Rights Reserved.
#
# PROJECT:	AppIcon Sample Application
# MODULE:	Geode Parameters
# FILE:		appicon.gp
#
# AUTHOR:	Jenny Greenwood, January 26, 1994
#
# REVISION HISTORY:
#       Name    Date            Description
#       ----    ----            -----------
#       jenny   1/26/94         Initial version
#
# DESCRIPTION:
#       This file contains Geode definitions for the "AppIcon" sample
#       application. This file is read by the GLUE linker to
#       build this application.
#
#       See the HELLO sample app for more details on the gp keywords.
#
# RCS STAMP:
#       $Id: appicon.gp,v 1.1 97/04/04 16:35:58 newdeal Exp $
#
#####################################################################
#
# Permanent name: is required by Glue to set the permanent name and extension
# of the geode. The permanent name of a library is what goes in the imported
# library table of a geode (along with the protocol number). It is also
# what Swat uses to name the patient.
#
name     appicon.app
#
# Long filename: this name can displayed by geoManager, and is used to identify
# the application for inter-application communication.
#
longname "C AppIcon"
#
# Specify geode type: is an application, will have its own process (thread),
# and is not multi-launchable.
#
type   appl, process, single
#
# Specify class name for application process. Methods sent to the Application's
# process will be handled by the AppIconProcessClass, which is defined
# in appicon.asm.
#
class  AppIconProcessClass
#
# Specify application object. This is the object in the .ui file which serves
# as the top-level UI object in the application.
#
appobj AppIconApp
#
# Token: this four-letter name is used by geoManager to locate the icon for this
# application in the database.
#
tokenchars "ACON"
tokenid    8
#
# Heapspace is the amount of memory used by the application.
# Use Swat's heapspace command to get this number.
#
heapspace 2989
#
# Libraries: list which libraries are used by the application.
#
library	geos
library	ui
#
# Resources: list all resource blocks which are used by the application.
# (standard discardable code resources do not need to be mentioned).
#
resource APPRESOURCE ui-object
resource INTERFACE   ui-object
#
# These resources contain the bitmap monikers for use
# under different display types.
#
resource SAMPLEAPPICONLCMONIKERRESOURCE   ui-object
resource SAMPLEAPPICONSCMONIKERRESOURCE   ui-object
resource SAMPLEAPPICONLMMONIKERRESOURCE   ui-object
resource SAMPLEAPPICONSMMONIKERRESOURCE   ui-object
resource SAMPLEAPPICONLCGAMONIKERRESOURCE ui-object
resource SAMPLEAPPICONSCGAMONIKERRESOURCE ui-object

