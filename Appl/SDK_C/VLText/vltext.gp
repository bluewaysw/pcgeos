#####################################################################
#
#	Copyright (c) Geoworks 1994 -- All Rights Reserved.
#
# PROJECT:	GEOS Sample Applications
# MODULE:	VisLargeText
# FILE:		vltext.gp
#
# AUTHOR:	Tony Requist: January 19, 1994
#
# REVISION HISTORY:
#       Name    Date            Description
#       ----    ----            -----------
#       tony    1/19/94         Initial version
#       NF      3/26/97         Added comments, changed tokenchars,
#                               updated heapspace value.
#		RainerB	4/27/2022		Resource names adjusted for Watcom compatibility
#
# DESCRIPTION:
#       This file contains Geode definitions for the "VLText" sample
#       application. This file is read by the Glue linker to
#       build this application.
#
# RCS STAMP:
#	$Id: vltext.gp,v 1.1 97/04/04 16:40:28 newdeal Exp $
#
#####################################################################
#
# Permanent name: is required by Glue to set the permanent name and extension
# of the geode. The permanent name of a library is what goes in the imported
# library table of a client geode (along with the protocol number). It is also
# what Swat uses to name the patient.
#
name     vltext.app
#
# Long filename: this name can displayed by GeoManager. "EC " is prepended to
# this when the error-checking version is linked by Glue.
#
longname "VisLargeText"
#
# Specify geode type: is an application, and will have its own thread started
# for it by the kernel.
#
type   appl, process, single
#
# Specify class name for application thread. Messages sent to the application
# thread (aka "process" when specified as the output of a UI object) will be
# handled by the process class.
#
class  VLTextProcessClass
#
# Specify application object. This is the object that serves as the top-level
# UI object in the application.
#
appobj VLTextApp
#
# Token: this four-letter+integer name is used by GeoManager to locate the icon
# for this application in the token database.
#
tokenchars "VLTX"
tokenid    8
#
# Heapspace: This is roughly the non-discardable memory usage
# of the application and any transient libraries that it depends on,
# plus an additional amount for thread activity. To find the heapspace
# for an application, use the Swat "heapspace" command.
#
heapspace 2889
#
# Libraries: list which libraries are used by the application.
#
library geos
library ui
library ansic
library text
#
# Resources: list all resource blocks which are used by the application whose
# allocation flags can't be inferred by Glue. Usually this is needed only for
# object blocks, fixed code resources, or data resources that are read-only.
# Standard discardable code resources do not need to be mentioned.
#
resource AppResource    object
resource Interface      object
resource DialogResource object
#
# Classes defined in this application must be exported here.
#
export VLTextContentClass
export VLTextTextClass

