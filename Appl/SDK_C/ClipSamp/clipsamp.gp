##############################################################################
#
#	Copyright (c) Geoworks 1990 -- All Rights Reserved
#
# PROJECT:	GEOS
# MODULE:	ClipSamp (C Clipboard Sample GEOS application)
# FILE:		clipsamp.gp
#
# AUTHOR:	brianc, 3/91
#
# DESCRIPTION:	This file contains Geode definitions for the "ClipSamp" sample
#		application. This file is read by the GLUE linker to
#		build this application.
#
# RCS STAMP:
#	$Id: clipsamp.gp,v 1.1 97/04/04 16:36:06 newdeal Exp $
#
##############################################################################
#
# Permanent name: This is required by Glue to set the permanent name
# and extension of the geode. The permanent name of a library is what
# goes in the imported library table of a client geode (along with the
# protocol number). It is also what Swat uses to name the patient.
#
name     clipsamp.app
#
# Long filename: This name can displayed by GeoManager, and is used to
# identify the application for inter-application communication.
#
longname "C Clipboard"
#
# Token: The four-letter name is used by GeoManager to locate the
# icon for this application in the token database. The tokenid
# number corresponds to the manufacturer ID of the program's author
# for uniqueness of the token. Since this is a sample application, we
# use the manufacturer ID for the SDK, which is 8.
#
tokenchars "CLIP"
tokenid    8
#
# Specify geode type: This geode is an application and will have its own
# process (thread).
#
type	appl, process
#
# Specify the class name of the application Process object: Messages
# sent to the application's Process object will be handled by
# ClipSampProcessClass, which is defined in clipsamp.goc.
#
class	ClipSampProcessClass
#
# Specify the application object: This is the object in the
# application's generic UI tree which serves as the top-level
# UI object for the application. See clipsamp.goc.
#
appobj	ClipSampApp
#
# Heapspace: This is roughly the non-discardable memory usage
# of the application and any transient libraries that it depends on,
# plus an additional amount for thread activity. To find the heapspace
# for an application, use the Swat "heapspace" command.
#
heapspace 3429
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
library ansic
library text
#
# Resources: list all resource blocks which are used by the application.
# (standard discardable code resources do not need to be mentioned).
#
# For this application, as for most, we want a UI thread to run the
# object resources, so we mark them "ui-object". Had we wanted the
# application thread to run them, we would have marked them "object".
#
resource APPRESOURCE ui-object
resource INTERFACE   ui-object

