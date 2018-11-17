##############################################################################
#
#	Copyright (c) Geoworks 1992 -- All Rights Reserved
#
# PROJECT:	Sample Applications
# MODULE:	Vis Object test app
# FILE:		visSamp.gp
#
# AUTHOR:	Chris Hawley 8/20/91
#
# DESCRIPTION:	This file contains Geode definitions for the "VisSamp" sample
#		application. This file is read by the GLUE linker to
#		build this application.
#
#IMPORTANT:
#	This example is written for the GEOS V2.0 API. 
#
# RCS STAMP:
#	$Id: vissamp.gp,v 1.1 97/04/04 16:37:35 newdeal Exp $
#
##############################################################################
#
# Permanent name: is required by Glue to set the permanent name and extension
# of the geode. The permanent name of a library is what goes in the imported
# library table of a geode (along with the protocol number). It is also
# what Swat uses to name the patient.
#
name vissamp.app
#
# Long filename: this name can displayed by geoManager, and is used to identify
# the application for inter-application communication.
#
longname "Vis Sample"
#
# Specify geode type: is an application, will have its own process (thread),
# and is not multi-launchable.
#
type	appl, process, single
#
# Specify class name for application process. Methods sent to the Application's
# process will be handled by the VisProcessClass, which is defined
# in visSamp.asm.
#
class	VisSampProcessClass
#
# Specify application object. This is the object in the .ui file which serves
# as the top-level UI object in the application. See hello.ui.
#
appobj	VisSampApp
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
heapspace 3353
#
# This application calls library code fixed or first written after the
# Zoomer release. Here we specify that the application expects to be
# running with Zoomer release libraries; this allows it to copy the
# necessary fixes from the relevant .ldf files into its own executable
# at compile time so that at runtime it will provide the fixed code for
# itself instead of refusing to run with the old libraries.
#
platform zoomer
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
resource INTERFACE ui-object

#
# Other classes
#
export	VisSampNumberClass
export 	VisSampCompClass
