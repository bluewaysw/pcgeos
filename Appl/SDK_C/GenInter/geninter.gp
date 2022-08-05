#####################################################################
#
#	Copyright (c) Geoworks 1991-92 -- All Rights Reserved
#
# PROJECT:	Sample Applications
# MODULE:	GenInteraction test application
# FILE:		geninter.gp
#
# AUTHOR:	Brian Chin: Feb, 1992
#
# REVISION HISTORY:
#       Name    Date            Description
#       ----    ----            -----------
#       brianc  2/92            Initial version
#       NF      9/27/96         Made tokenchars unique
#		RainerB	4/27/2022		Resource names adjusted for Watcom compatibility
#
# DESCRIPTION:
#       This file contains Geode definitions for the
#       "GenInter" sample application. This file is read by the
#       GLUE linker to build this application.
#
# RCS STAMP:
#	$Id: geninter.gp,v 1.1 97/04/04 16:37:46 newdeal Exp $
#
#####################################################################
#
# Permanent name: is required by Glue to set the permanent name and extension
# of the geode. The permanent name of a library is what goes in the imported
# library table of a geode (along with the protocol number). It is also
# what Swat uses to name the patient.
#
name     geninter.app
#
# Long filename: this name can displayed by geoManager, and is used
# to identify the application for inter-application communication.
#
longname "C GenInter"
#
# Specify geode type: is an application, will have its own
# process (thread), and is not multi-launchable.
#
type   appl, process, single
#
# Specify class name for application process. Methods sent to
# the Application's process will be handled by the GenInterProcessClass,
# which is defined in geninter.asm.
#
class  GenInterProcessClass
#
# Specify application object. This is the object in the .ui
# file which serves as the top-level UI object in the application.
#
appobj GenInterApp
#
# Token: this four-letter name is used by geoManager to locate
# the icon for this application in the database.
#
tokenchars "INTR"
tokenid    8
#
# Heapspace: This is roughly the non-discardable memory usage
# of the application and any transient libraries that it depends on,
# plus an additional amount for thread activity. To find the heapspace
# for an application, use the Swat "heapspace" command.
#
heapspace 3912
#
# Libraries: list which libraries are used by the application.
#
library	geos
library	ui
library ansic
#
# Resources: list all resource blocks which are used by the application.
# (standard discardable code resources do not need to be mentioned).
#
resource AppResource ui-object
resource Interface   ui-object

