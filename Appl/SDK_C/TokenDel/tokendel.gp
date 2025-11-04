#####################################################################
#
#       Copyright (c) Geoworks 1997 -- All Rights Reserved.
#
# PROJECT:      GEOS Sample Applications
# MODULE:       Token Deleter
# FILE:         tokendel.gp
#
# AUTHOR:       Marcus Groeber
#
# REVISION HISTORY:
#       Name    Date            Description
#       ----    ----            -----------
#       MG      ?               Initial version
#       NF      2/25/97         Made a "derivative work" - turned
#                               it into an SDK sample application
#
# DESCRIPTION:
#       This file contains Geode definitions for the "TokenDel" sample
#       application. This file is read by the Glue linker to
#       build this application.
#
# RCS STAMP:
#       $Id: tokendel.gp,v 1.1.2.1 97/06/16 19:01:34 eballot Exp $
#
#####################################################################
#
# Permanent name: This is required by Glue to set the permanent name
# and extension of the geode. The permanent name of a library is what
# goes in the imported library table of a client geode (along with the
# protocol number). It is also what Swat uses to name the patient.
#
name     tokendel.app
#
# Long filename: this name can displayed by GeoManager. "EC " is prepended to
# this when the error-checking version is linked by Glue.
#
longname "Token Deleter"
#
# Specify geode type: This geode is an application, and will have its
# own process (thread).
#
type   appl, process, single
#
# Specify class name for application thread. Messages sent to the application
# thread (aka "process" when specified as the output of a UI object) will be
# handled by the process class.
#
class  TokenDelProcessClass
#
# Specify application object. This is the object that serves as the top-level
# UI object in the application.
#
appobj TokenDelApp
#
# Token: The four-letter name is used by GeoManager to locate the
# icon for this application in the token database. The tokenid
# number corresponds to the manufacturer ID of the program's author
# for uniqueness of the token. Since this is a sample application, we
# use the manufacturer ID for the SDK, which is 8.
#
tokenchars "TOKD"
tokenid    8
#
# Heapspace: This is roughly the non-discardable memory usage
# of the application and any transient libraries that it depends on,
# plus an additional amount for thread activity. To find the heapspace
# for an application, use the Swat "heapspace" command.
#
heapspace 2929
#
# Specifies the platform for which to link this geode. Tells the
# linker which library protocols to use for the libraries listed below.
#
platform geos20
#
# Libraries: list which libraries are used by the application.
#
library	geos
library	ui
library ansic
#
# Resources: list all resource blocks which are used by the application whose
# allocation flags can't be inferred by Glue. Usually this is needed only for
# object blocks, fixed code resources, or data resources that are read-only.
# Standard discardable code resources do not need to be mentioned.
#
resource AppResource ui-object
resource Interface   ui-object

