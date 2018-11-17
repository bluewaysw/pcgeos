#####################################################################
#
#	Copyright (c) Geoworks 1991-1994 -- All Rights Reserved.
#
# PROJECT:	GEOS Sample Applications
# MODULE:	SubUI
# FILE:		subui.gp
#
# AUTHOR:	Tony Requist: 1994
#
# REVISION HISTORY:
#       Name    Date            Description
#       ----    ----            -----------
#       tony    1994            Initial version
#       NF      3/19/97         Made tokenchars unique
#
# DESCRIPTION:
#       This file contains Geode definitions for the "SubUI" sample
#       application. This file is read by the GLUE linker to
#       build this application.
#
# RCS STAMP:
#	$Id: subui.gp,v 1.1 97/04/04 16:39:20 newdeal Exp $
#
#####################################################################
#
# Permanent name: is required by Glue to set the permanent name and extension
# of the geode. The permanent name of a library is what goes in the imported
# library table of a geode (along with the protocol number). It is also
# what Swat uses to name the patient.
#
name     subui.app
#
# Long filename: this name can displayed by geoManager, and is used to identify
# the application for inter-application communication.
#
longname "C SubUI"
#
# Specify geode type: is an application, will have its own process (thread),
# and is not multi-launchable.
#
type   appl, process, single
#
# Specify class name for application process. Methods sent to the Application's
# process will be handled by the process class.
#
class  SubUIProcessClass
#
# Specify application object. This is the object in the .ui file which serves
# as the top-level UI object in the application.
#
appobj SubUIApp
#
# Token: The four-letter name is used by GeoManager to locate the
# icon for this application in the token database. The tokenid
# number corresponds to the manufacturer ID of the program's author
# for uniqueness of the token. Since this is a sample application, we
# use the manufacturer ID for the SDK, which is 8.
#
tokenchars "SBUI"
tokenid    8
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
#
# Any classes that are defined in this application must be exported here.
#
export SubUITriggerClass

