##############################################################################
#
#	Copyright (c) GlobalPC 1998 -- All Rights Reserved
#
# PROJECT:	File Finder Applications
# MODULE:	File Finder application
# FILE:		FFinder.gp
#
# AUTHOR:	Edwin Yu, 10/23/98
#
# REVISION HISTORY:
#       Name    Date            Description
#       ----    ----            -----------
#       edwin   10/23/98        Initial version
#
# DESCRIPTION:
#       This file contains Geode definitions for the "FFinder" 
#       application. This file is read by the GLUE linker to
#       build this application.
#
# RCS STAMP:
#	$Id:$
#
##############################################################################
#
# Permanent name: This is required by Glue to set the permanent name
# and extension of the geode. The permanent name of a library is what
# goes in the imported library table of a client geode (along with the
# protocol number). It is also what Swat uses to name the patient.
#
name     FFinder.app
#
# Long filename: This name can displayed by GeoManager, and is used to
# identify the application for inter-application communication.
#
longname "File Finder"
#
# Token: The four-letter name is used by GeoManager to locate the
# icon for this application in the token database. The tokenid
# number corresponds to the manufacturer ID of the program's author
# for uniqueness of the token.
#
tokenchars "FFNR"
tokenid    0
#
# Specify geode type: This geode is an application, will have its own
# process (thread), and is not multi-launchable.
#
type	appl, process, single
#
# Specify the class name of the application Process object: Messages
# sent to the application's Process object will be handled by
# FFinderProcessClass, which is defined in FFinder.goc.
#
class	FFinderProcessClass
#
# Specify the application object: This is the object in the
# application's generic UI tree which serves as the top-level
# UI object for the application. See FFinder.goc.
#
appobj	FFinderApp
#
# Heapspace: This is roughly the non-discardable memory usage (in words)
# of the application and any transient libraries that it depends on,
# plus an additional amount for thread activity. To find the heapspace
# for an application, use the Swat "heapspace" command.
#
heapspace 3526
#
# Libraries: list which libraries are used by the application.
#
library	geos
library	ui
library ansic
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
# resource INTERFACE2 lmem read-only shared
resource INTERFACE2   ui-object
resource FIXEDRESOURCE fixed code read-only shared
resource TINYMONIKERRESOURCE ui-object
resource APPMONIKERRESOURCE ui-object
resource ICONMONIKERRESOURCE lmem read-only shared
#resource ICONMONIKERRESOURCE ui-object
resource STRINGS lmem shared read-only

#
# Exported classes
#
export FilterFileSelectorClass
export FFResultListClass
export FFThreadClass
export FFSearchTextClass
