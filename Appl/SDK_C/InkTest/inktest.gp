#####################################################################
#
#       Copyright (c) GeoWorks 1996 -- All Rights Reserved.
#
# PROJECT:      InkTest Sample Application
# MODULE:       Geode Parameters
# FILE:         inktest.gp
#
# AUTHOR:       Allen Schoonmaker: July 9, 1992
#
# REVISION HISTORY:
#       Name    Date            Description
#       ----    ----            -----------
#       AS      7/9/92          Initial version
#       NF      9/19/96         Corrected some common errors
#       NF      10/7/96         Corrected heapspace value.
#		RainerB	4/27/2022		Resource names adjusted for Watcom compatibility
#
# DESCRIPTION:
#       This file contains Geode definitions for the "InkTest" sample
#       application. This file is read by the GLUE linker to
#       build this application.
#
# RCS STAMP:
#       $Id: inktest.gp,v 1.1 97/04/04 16:39:06 newdeal Exp $
#
#####################################################################
#
# Permanent name: This is required by Glue to set the permanent name
# and extension of the geode. The permanent name of a library is what
# goes in the imported library table of a client geode (along with the
# protocol number). It is also what Swat uses to name the patient.
#
name     inktest.app
#
# Long filename: this name can displayed by GeoManager. "EC " is prepended to
# this when the error-checking version is linked by Glue.
#
longname "C Ink Test"
#
# Specify geode type: This geode is an application, and will have its
# own process (thread).
#
type   appl, process, single
#
# Specify class name for application thread. Messages sent to the application
# thread (aka "process" when specified as the output of a UI object) will be
# handled by the HelloProcessClass, which is defined in hello.goc.
#
class  InkTestProcessClass
#
# Specify application object. This is the object that serves as the top-level
# UI object in the application. See hello.goc.
#
appobj InkTestApp
#
# Token: The four-letter name is used by GeoManager to locate the
# icon for this application in the token database. The tokenid
# number corresponds to the manufacturer ID of the program's author
# for uniqueness of the token. Since this is a sample application, we
# use the manufacturer ID for the SDK, which is 8.
#
tokenchars "INKT"
tokenid    8
#
# Heapspace: This is roughly the non-discardable memory usage
# of the application and any transient libraries that it depends on,
# plus an additional amount for thread activity. To find the heapspace
# for an application, use the Swat "heapspace" command.
#
heapspace 4060
#
# Platforms that this program is to be linked for. Glue will check
# the protocols of the libraries this geode uses and make sure that
# the specified platform has the appropriate libraries.
#
platform zoomer
#
# Libraries: list which libraries are used by the application.
#
library	geos
library	ui
library pen
library inkfix
#
# Sometimes we want to use a library that is either not available
# on the platform we specified, or the .plt file is missing the
# entry for that library.
#
exempt inkfix
#
# Resources: list all resource blocks which are used by the application whose
# allocation flags can't be inferred by Glue. Usually this is needed only for
# object blocks, fixed code resources, or data resources that are read-only.
# Standard discardable code resources do not need to be mentioned.
#
resource Application ui-object
resource Interface   ui-object
resource DisplayUI   ui-object
resource DocGroup    object
#
# Classes we defined in our program.
#
export InkTestProcessClass
export InkTestDocumentClass

