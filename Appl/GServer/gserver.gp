##############################################################################
#
#	Copyright (c) Geoworks 1990 -- All Rights Reserved
#
# PROJECT:	GEOS
# MODULE:	Fake gopher server
# FILE:		gserver.gp
#
# AUTHOR:	Alvin Cham, Dec. 5, 1994
#
# DESCRIPTION:	This file contains Geode definitions for the "Gserver" sample
#		application. This file is read by the Glue linker to
#		build this application.
#
# RCS STAMP:
#	$Id: gserver.gp,v 1.1 97/04/04 15:11:23 newdeal Exp $
#
##############################################################################

# Geode's permanent name
name gserver.app

#
# Long filename: this name can displayed by GeoManager. "EC " is prepended to
# this when the error-checking version is linked by Glue.
#
longname "C Gserver"

#
# Token: The four-letter name is used by GeoManager to locate the
# icon for this application in the token database. The tokenid
# number corresponds to the manufacturer ID of the program's author
# for uniqueness of the token. Since this is a sample application, we
# use the manufacturer ID for the SDK, which is 8.
#
tokenchars "GSVR"
tokenid 8

#
# Specify geode type: This geode is an application, and will have its
# own process (thread).
#
type	appl, process

#
# Specify class name for application thread. Messages sent to the application
# thread (aka "process" when specified as the output of a UI object) will be
# handled by the GserverProcessClass, which is defined in gserver.goc.
#
class	GserverProcessClass

#
# Specify application object. This is the object that serves as the top-level
# UI object in the application. See gserver.goc.
#
appobj	GserverApp

#
# Heapspace: This is roughly the non-discardable memory usage (in words)
# of the application and any transient libraries that it depends on,
# plus an additional amount for thread activity. To find the heapspace
# for an application, use the Swat "heapspace" command.
#
heapspace 2514

#
# Libraries: list which libraries are used by the application.
#
library	geos
library	ui
library socket
library	gopher

#
# Resources: list all resource blocks which are used by the application whose
# allocation flags can't be inferred by Glue. Usually this is needed only for
# object blocks, fixed code resources, or data resources that are read-only.
# Standard discardable code resources do not need to be mentioned.
#
resource APPRESOURCE ui-object
resource INTERFACE ui-object

export	GserverThreadClass
export	GserverTextClass







