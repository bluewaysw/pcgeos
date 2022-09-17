#####################################################################
#
#	Copyright (c) Geoworks 1991-92 -- All Rights Reserved.
#
# PROJECT:	Sample Applications
# MODULE:	Generic Attributes Sample
# FILE:		genattrs.gp
#
# AUTHOR:	brianc, 9/4/91
#
# REVISION HISTORY:
#       Name    Date            Description
#       ----    ----            -----------
#       brianc  9/4/91          Initial version
#       NF      9/26/96         Made tokenchars unique,
#                               corrected heapspace value
#		RainerB	4/27/2022		Resource names adjusted for Watcom compatibility
#
# DESCRIPTION:
#       This file contains Geode definitions for the
#       "GenAttrs" sample application.
#
# RCS STAMP:
#	$Id: genattrs.gp,v 1.1 97/04/04 16:37:22 newdeal Exp $
#
#####################################################################
#
# Permanent name: This is required by Glue to set the permanent name
# and extension of the geode. The permanent name of a library is what
# goes in the imported library table of a client geode (along with the
# protocol number). It is also what Swat uses to name the patient.
#
name     genattrs.app
#
# Long filename: This name can displayed by GeoManager, and is used to
# identify the application for inter-application communication.
#
longname "C GenAttrs"
#
# Token: The four-letter name is used by GeoManager to locate the
# icon for this application in the token database. The tokenid
# number corresponds to the manufacturer ID of the program's author
# for uniqueness of the token. Since this is a sample application, we
# use the manufacturer ID for the SDK, which is 8.
#
tokenchars "GATR"
tokenid    8
#
# Specify geode type: This geode is an application and will have its own
# process (thread).
#
type	appl, process, single
#
# Specify the class name of the application Process object: Messages
# sent to the application's Process object will be handled by
# GenAttrsProcessClass, which is defined in genattrs.goc.
#
class	GenAttrsProcessClass
#
# Specify the application object: This is the object in the
# application's generic UI tree which serves as the top-level
# UI object for the application. See clipsamp.goc.
#
appobj	GenAttrsApp
#
# Heapspace: This is roughly the non-discardable memory usage
# of the application and any transient libraries that it depends on,
# plus an additional amount for thread activity. To find the heapspace
# for an application, use the Swat "heapspace" command.
#
heapspace 3107
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
resource AppResource ui-object
resource Interface   ui-object

