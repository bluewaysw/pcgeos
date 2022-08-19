#####################################################################
#
#	Copyright (c) Geoworks 1993-96 -- All Rights Reserved.
#
# PROJECT:	GEOS Sample Applications
# MODULE:	HelpSamp sample application
# FILE:		helpsamp.gp
#
# AUTHOR:	Peter Dudley, 22 January 1993
#
# REVISION HISTORY:
#       Name    Date            Description
#       ----    ----            -----------
#       PjD     1/22/93         Initial version
#       NF      10/7/96         Corrected heapspace value
#
# RCS STAMP:
#	$Id: helpsamp.gp,v 1.1 97/04/04 16:38:56 newdeal Exp $
#
#####################################################################
#
# Permanent name: This is required by Glue to set the permanent name
# and extension of the geode. The permanent name of a library is what
# goes in the imported library table of a client geode (along with the
# protocol number). It is also what Swat uses to name the patient.
#
name     helpsamp.app
#
# Long filename: this name can displayed by GeoManager. "EC " is prepended
# to this when the error-checking version is linked by Glue.
#
longname "C Help Sample"
#
# Token: The four-letter name is used by GeoManager to locate the
# icon for this application in the token database. The tokenid
# number corresponds to the manufacturer ID of the program's author
# for uniqueness of the token. Since this is a sample application, we
# use the manufacturer ID for the SDK, which is 8.
#
tokenchars "HLPS"
tokenid    8
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
class  HelpSampProcessClass
#
# Specify application object. This is the object that serves as the top-level
# UI object in the application. See hello.goc.
#
appobj HelpSampApp
#
# Heapspace: This is roughly the non-discardable memory usage
# of the application and any transient libraries that it depends on,
# plus an additional amount for thread activity. To find the heapspace
# for an application, use the Swat "heapspace" command.
#
heapspace 3100
#
# Libraries: list which libraries are used by the application.
#
library	geos
library	ui
#
# Resources: list all resource blocks which are used by the application whose
# allocation flags can't be inferred by Glue. Usually this is needed only for
# object blocks, fixed code resources, or data resources that are read-only.
# Standard discardable code resources do not need to be mentioned.
#
resource APPRESOURCE object
resource INTERFACE   object

