##############################################################################
#
#	Copyright (c) Geoworks 1991 -- All Rights Reserved
#
# PROJECT:	GEOS V2.0
# MODULE:	Hello (Sample GEOS application)
# FILE:		hello3.gp (Hello Application Geode Parameters File)
#
# DESCRIPTION:	This file contains Geode definitions for the "Hello World" 
#		sample application. This file is read by the Glue linker to
#		build this application.
#
#	$Id: hello3.gp,v 1.1 97/04/04 16:37:56 newdeal Exp $
#
##############################################################################
#
# Permanent name: is required by Glue to set the permanent name and extension
# of the geode. The permanent name of a library is what goes in the imported
# library table of a client geode (along with the protocol number). It is also
# what Swat uses to name the patient.
#
name     hello3.app
#
# Long filename: this name can be displayed by GeoManager. 
# "EC " is prepended to
# this when the error-checking version is linked by Glue.
#
longname "Hello World"
#
# Specify geode type: is an application, and will have its own thread started
# for it by the kernel. It may only be launched once.
#
type	appl, process, single
#
# Specify class name for application thread. Messages sent to the application
# thread (aka "process" when specified as the output of a UI object) will be
# handled by the HelloProcessClass, which is defined in hello.goc.
#
class	HelloProcessClass
#
# Specify application object. This is the object that serves as the top-level
# UI object in the application. See hello3.goc.
#
appobj	HelloApp
#
# Token: The four-letter name is used by GeoManager to locate the
# icon for this application in the token database. The tokenid
# number corresponds to the manufacturer ID of the program's author
# for uniqueness of the token. Since this is a sample application, we
# use the manufacturer ID for the SDK, which is 8.
#
tokenchars "HLO3"
tokenid    8
#
# Stack:  This field designates the number of bytes to set aside for
# the process' stack.  (The type of the geode must be process, above.)
#
stack 1500
#
# Heapspace: This is roughly the non-discardable memory usage
# of the application and any transient libraries that it depends on,
# plus an additional amount for thread activity. To find the heapspace
# for an application, use the Swat "heapspace" command.
# (specified in paragraphs of 16 bytes)
heapspace 456
#
# Resources: list all resource blocks which are used by the application whose
# allocation flags can't be inferred by Glue. Usually this is needed only for
# object blocks, fixed code resources, or data resources that are read-only.
# Standard discardable code resources do not need to be mentioned.
#
# In this program, we have three object resources that should be run by our
# user-interface thread (as opposed to our application thread), so we mark
# them all as ui-object resources.
#
resource APPRESOURCE  ui-object
resource INTERFACE    ui-object
resource MENURESOURCE ui-object
#
# Libraries:  List which libraries are used by the application.
#
library	geos
library	ui
#
# User Notes:  This field allows the geode to fill its usernotes field
# (available to the user through GeoManager's File/Get Info function)
# with meaningful text.
#
usernotes "Sample application for GEOS version 2.0."
