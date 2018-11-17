#####################################################################
#
#	Copyright (c) Geoworks 1992 -- All Rights Reserved
#
# PROJECT:	GEOS Sample Applications
# MODULE:	Custom Geometry
# FILE:		custgeom.gp
#
# AUTHOR:	Chris Hawley: February 9, 1992
#
# REVISION HISTORY:
#       Name    Date            Description
#       ----    ----            -----------
#       chris   2/9/92          Initial version
#       NF      9/25/96         Made tokenchars unique, changed
#                               resources to ui-object, updated
#                               heapspace value
#
# DESCRIPTION:
#       This file contains Geode definitions for the "Custom Geometry"
#       sample application. This file is read by Glue to build this
#       application.
#
# RCS STAMP:
#	$Id: custgeom.gp,v 1.1 97/04/04 16:38:44 newdeal Exp $
#
#####################################################################
#
# Permanent name: This is required by Glue to set the permanent name and
# extension of the geode. The permanent name of a library is what goes in
# the imported library table of a geode (along with the protocol number).
# It is also what Swat uses to name the patient.
#
name custgeom.app
#
# Long filename: This name can displayed by GeoManager, and is used to
# identify the application for inter-application communication.
#
longname "C Custom Geometry"
#
# Token: The four-letter name is used by GeoManager to locate the
# icon for this application in the token database. The tokenid
# number corresponds to the manufacturer ID of the program's author
# for uniqueness of the token. Since this is a sample application, we
# use the manufacturer ID for the SDK, which is 8.
#
tokenchars "CUSG"
tokenid    8
#
# Specify geode type: This geode is an application, will have its own
# process (thread), and is not multi-launchable.
#
type	appl, process, single
#
# Specify the class name of the application Process object: Messages
# sent to the application's Process object will be handled by
# CustomGeomProcessClass, which is defined in custgeom.goc.
#
class	CustomGeoProcessClass
#
# Specify the application object: This is the object in the
# application's generic UI tree which serves as the top-level
# UI object for the application. See clipsamp.goc.
#
appobj	CustomGeoApp
#
# Heapspace: This is roughly the non-discardable memory usage
# of the application and any transient libraries that it depends on,
# plus an additional amount for thread activity. To find the heapspace
# for an application, use the Swat "heapspace" command.
#
heapspace 3130
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
resource INTERFACE   ui-object

