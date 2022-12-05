##############################################################################
#
#	Copyright (c) Geoworks 1992	 -- All Rights Reserved
#
# PROJECT:	Sample Applications
# MODULE:	GenView test app
# FILE:		viewSamp.gp
#
# AUTHOR:	Chris Hawley 8/20/91
#
# REVISION HISTORY:
#       Name    Date            Description
#       ----    ----            -----------
#       CH	8/20/91	        Initial version
#	RainerB	4/27/2022	Resource names adjusted for Watcom compatibility
#
# DESCRIPTION:	This file contains Geode definitions for the "ViewSamp" sample
#		application. This file is read by the GLUE linker to
#		build this application.
#
#IMPORTANT:
#	This example is written for the GEOS V2.0 API. 
#
# RCS STAMP:
#	$Id: viewsamp.gp,v 1.1 97/04/04 16:36:15 newdeal Exp $
#
##############################################################################
#
# Permanent name: is required by Glue to set the permanent name and extension
# of the geode. The permanent name of a library is what goes in the imported
# library table of a geode (along with the protocol number). It is also
# what Swat uses to name the patient.
#
name viewsamp.app
#
# Long filename: this name can displayed by geoManager, and is used to identify
# the application for inter-application communication.
#
longname "View Sample"
#
# Specify geode type: is an application, will have its own process (thread),
# and is not multi-launchable.
#
type	appl, process, single
#
# Specify class name for application process. Methods sent to the Application's
# process will be handled by the ViewProcessClass, which is defined
# in viewSamp.asm.
#
class	ViewSampProcessClass
#
# Specify application object. This is the object in the .ui file which serves
# as the top-level UI object in the application. See hello.ui.
#
appobj	ViewSampApp
#
# Token: The four-letter name is used by GeoManager to locate the
# icon for this application in the token database. The tokenid
# number corresponds to the manufacturer ID of the program's author
# for uniqueness of the token. Since this is a sample application, we
# use the manufacturer ID for the SDK, which is 8.
#
tokenchars "SAMP"
tokenid 8
#
# Heapspace: This is roughly the non-discardable memory usage (in words)
# of the application and any transient libraries that it depends on,
# plus an additional amount for thread activity. To find the heapspace
# for an application, use the Swat "heapspace" command.
#
heapspace 3333
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
# Other classes
#
