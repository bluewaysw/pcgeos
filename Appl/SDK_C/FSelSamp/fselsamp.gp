##############################################################################
#
#	Copyright (c) Geoworks 1990 -- All Rights Reserved
#
# PROJECT:	FSelSamp Sample Application
# MODULE:       Geode Parameters
# FILE:		fselsamp.gp
#
# AUTHOR:	Tony Requist: April 1, 1991
#
# REVISION HISTORY:
#       Name    Date            Description
#       ----    ----            -----------
#       tony    4/1/91          Initial version
#       NF      9/26/96         Corrected heapspace value
#                               Made tokenchars unique
#		RainerB	4/27/2022		Resource names adjusted for Watcom compatibility
#
# DESCRIPTION:	This file contains Geode definitions for the "FSelSamp" sample
#		application. This file is read by the GLUE linker to
#		build this application.
#
# RCS STAMP:
#	$Id: fselsamp.gp,v 1.1 97/04/04 16:36:03 newdeal Exp $
#
##############################################################################
#
# Permanent name: This is required by Glue to set the permanent name
# and extension of the geode. The permanent name of a library is what
# goes in the imported library table of a client geode (along with the
# protocol number). It is also what Swat uses to name the patient.
#
name     fselsamp.app
#
# Long filename: This name can displayed by GeoManager, and is used to
# identify the application for inter-application communication.
#
longname "C File Selector Sample App"
#
# Token: The four-letter name is used by GeoManager to locate the
# icon for this application in the token database. The tokenid
# number corresponds to the manufacturer ID of the program's author
# for uniqueness of the token. Since this is a sample application, we
# use the manufacturer ID for the SDK, which is 8.
#
tokenchars "FSEL"
tokenid    8
#
# Specify geode type: This geode is an application, will have its own
# process (thread), and is not multi-launchable.
#
type	appl, process, single
#
# Specify the class name of the application Process object: Messages
# sent to the application's Process object will be handled by
# FSelSampProcessClass, which is defined in fselsamp.goc.
#
class	FSelSampProcessClass
#
# Specify the application object: This is the object in the
# application's generic UI tree which serves as the top-level
# UI object for the application. See fselsamp.goc.
#
appobj	FSelSampApp
#
# Heapspace: This is roughly the non-discardable memory usage (in words)
# of the application and any transient libraries that it depends on,
# plus an additional amount for thread activity. To find the heapspace
# for an application, use the Swat "heapspace" command.
#
heapspace 4040
#
# Libraries: list which libraries are used by the application.
#
library	geos
library	ui
library	ansic
#
# Resources: list all resource blocks which are used by the application.
# (standard discardable code resources do not need to be mentioned).
#
# For this application, as for most, we want a UI thread to run the
# object resources, so we mark them "ui-object". Had we wanted the
# application thread to run them, we would have marked them "object".
#
resource AppResource  ui-object
resource Interface    ui-object
resource MenuResource ui-object

