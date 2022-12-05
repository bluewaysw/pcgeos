#####################################################################
#
#	Copyright (c) Geoworks 1994 -- All Rights Reserved.
#
# PROJECT:	GEOS Sample Applications
# MODULE:	IACP/Server
# FILE:		server.gp
#
# AUTHOR:	Ed Ballot: Feb 23, 1994
#
# REVISION HISTORY:
#       Name    Date            Description
#       ----    ----            -----------
#       EB      2/23/94         Initial version
#       NF      10/7/96         Added heapspace value and
#                               changed tokenid to 8.
#	RainerB	4/27/2022	Resource names adjusted for Watcom compatibility
#
# DESCRIPTION:
#       This file contains Geode definitions for the "Server" sample
#       application. This file is read by the Glue linker to
#       build this application.
#
# RCS STAMP:
#	$Id: server.gp,v 1.1 97/04/04 16:40:00 newdeal Exp $
#
#####################################################################
#
# Permanent name: is required by Glue to set the permanent name and extension
# of the geode. The permanent name of a library is what goes in the imported
# library table of a client geode (along with the protocol number). It is also
# what Swat uses to name the patient.
#
name     server.app
#
# Long filename: this name can displayed by GeoManager. "EC " is prepended to
# this when the error-checking version is linked by Glue.
#
longname "IACP Server"
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
class  ServerProcessClass
#
# Specify application object. This is the object that serves as the top-level
# UI object in the application.
#
appobj ServerApp
#
# Token: this four-letter+integer name is used by GeoManager to locate the icon
# for this application in the token database.
#
tokenchars "SRVR"
tokenid    8
#
# Heapspace: This is roughly the non-discardable memory usage
# of the application and any transient libraries that it depends on,
# plus an additional amount for thread activity. To find the heapspace
# for an application, use the Swat "heapspace" command.
#
heapspace 2861
#
# Libraries: list which libraries are used by the application.
#
library geos
library ui
#
# Resources: list all resource blocks which are used by the application whose
# allocation flags can't be inferred by Glue. Usually this is needed only for
# object blocks, fixed code resources, or data resources that are read-only.
# Standard discardable code resources do not need to be mentioned.
#
resource AppResource ui-object, discardable
resource Interface   ui-object, discardable
resource Strings     lmem read-only shared

