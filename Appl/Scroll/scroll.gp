#####################################################################
#
#       Copyright (c) Geoworks 1996 -- All Rights Reserved.
#
# PROJECT:      GEOS Sample Applications
# MODULE:       GenContent Sample
# FILE:         gcont.gp
#
# AUTHOR:       Nathan Fiedler: November 13, 1996
#
# REVISION HISTORY:
#       Name    Date            Description
#       ----    ----            -----------
#       NF      11/13/96        Initial version
#
# DESCRIPTION:
#       This file contains Geode definitions for the "GenContent"
#       sample application. This file is read by the Glue linker to
#       build this application.
#
# RCS STAMP:
#       $Id: gcont.gp,v 1.1 97/04/04 16:41:44 newdeal Exp $
#
#####################################################################
#
# Permanent name: is required by Glue to set the permanent name and extension
# of the geode. The permanent name of a library is what goes in the imported
# library table of a client geode (along with the protocol number). It is also
# what Swat uses to name the patient.
#
name     scroll.app
#
# Long filename: this name can be displayed by GeoManager. "EC " is prepended to
# this when the error-checking version is linked by Glue.
#
longname "Scroll"
#
# Specify geode type: is an application, and will have its own thread started
# for it by the kernel. It may only be launched once.
#
type   appl, process, single
#
# Specify class name for application thread. Messages sent to the application
# thread (aka "process" when specified as the output of a UI object) will be
# handled by the HelloProcessClass, which is defined in hello.goc.
#
class  ScrollProcessClass
#
# Specify application object. This is the object that serves as the top-level
# UI object in the application. See hello3.goc.
#
appobj ScrollApp
#
# Token: The four-letter name is used by GeoManager to locate the
# icon for this application in the token database. The tokenid
# number corresponds to the manufacturer ID of the program's author
# for uniqueness of the token. Since this is a sample application, we
# use the manufacturer ID for the SDK, which is 8.
#
tokenchars "SCRL"
tokenid    8
#
# Heapspace: This is roughly the non-discardable memory usage
# of the application and any transient libraries that it depends on,
# plus an additional amount for thread activity. To find the heapspace
# for an application, use the Swat "heapspace" command.
#
heapspace 3269
#
# Libraries:  List which libraries are used by the application.
#
library geos
library ui
#
# Resources: list all resource blocks which are used by the application whose
# allocation flags can't be inferred by Glue. Usually this is needed only for
# object blocks, fixed code resources, or data resources that are read-only.
# Standard discardable code resources do not need to be mentioned.
#
resource AppResource ui-object
resource Interface   ui-object
#
# Any classes that are defined in the application should be exported here.
#
export ScrollViewClass
