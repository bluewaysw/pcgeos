##############################################################################
#
#	Copyright (c) Geoworks 1991-92 -- All Rights Reserved
#
# PROJECT:	Sample Applications
# MODULE:	File Selector Filter test application
# FILE:		fsfilter.gp
#
# AUTHOR:	brianc, 9/26/91
#
# REVISION HISTORY:
#       Name    Date            Description
#       ----    ----            -----------
#       brianc  9/26/91         Initial version
#       NF      9/26/96         Corrected heapspace value
#                               Made tokenchars unique
#
# DESCRIPTION:
#       This file contains Geode definitions for the "FSFilter" sample
#       application. This file is read by the GLUE linker to
#       build this application.
#
# RCS STAMP:
#	$Id: fsfilter.gp,v 1.1 97/04/04 16:37:25 newdeal Exp $
#
##############################################################################
#
# Permanent name: This is required by Glue to set the permanent name
# and extension of the geode. The permanent name of a library is what
# goes in the imported library table of a client geode (along with the
# protocol number). It is also what Swat uses to name the patient.
#
name     fsfilter.app
#
# Long filename: This name can displayed by GeoManager, and is used to
# identify the application for inter-application communication.
#
longname "C FSFilter"
#
# Token: The four-letter name is used by GeoManager to locate the
# icon for this application in the token database. The tokenid
# number corresponds to the manufacturer ID of the program's author
# for uniqueness of the token. Since this is a sample application, we
# use the manufacturer ID for the SDK, which is 8.
#
tokenchars "FFIL"
tokenid    8
#
# Specify geode type: This geode is an application, will have its own
# process (thread), and is not multi-launchable.
#
type	appl, process, single
#
# Specify the class name of the application Process object: Messages
# sent to the application's Process object will be handled by
# FSFilterProcessClass, which is defined in fsfilter.goc.
#
class	FSFilterProcessClass
#
# Specify the application object: This is the object in the
# application's generic UI tree which serves as the top-level
# UI object for the application. See fsfilter.goc.
#
appobj	FSFilterApp
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
#
# Exported classes
#
export FilterFileSelectorClass

