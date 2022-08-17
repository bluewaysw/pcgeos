##############################################################################
#
#	Copyright (c) Geoworks 1995 -- All Rights Reserved
#
# PROJECT:	
# FILE:		talk.gp
#
# AUTHOR:	Eric Weber, Dec  7, 1994
#
# REVISION HISTORY:
#       Name    Date            Description
#       ----    ----            -----------
#       EW		7/12/94	        Initial version
#		RainerB	4/27/2022		Resource names adjusted for Watcom compatibility
#
# 
#
#	$Id: talk.gp,v 1.1 97/04/04 16:40:26 newdeal Exp $
#
##############################################################################
#
# Permanent name: is required by Glue to set the permanent name and extension
# of the geode. The permanent name of a library is what goes in the imported
# library table of a client geode (along with the protocol number). It is also
# what Swat uses to name the patient.
#
name talk.app
#
# Long filename: this name can displayed by GeoManager. "EC " is prepended to
# this when the error-checking version is linked by Glue.
#
longname "Talk Demo"
#
# Token: The four-letter name is used by GeoManager to locate the
# icon for this application in the token database. The tokenid
# number corresponds to the manufacturer ID of the program's author
# for uniqueness of the token. Since this is a sample application, we
# use the manufacturer ID for the SDK, which is 8.
#
tokenchars "TALK"
tokenid 0
#
# Specify geode type: is an application, and will have its own thread started
# for it by the kernel.
#
type	appl, process
#
# Specify class name for application thread. Messages sent to the application
# thread (aka "process" when specified as the output of a UI object) will be
# handled by the HelloProcessClass, which is defined in hello2.goc.
#
class	TalkProcessClass
#
# Specify application object. This is the object that serves as the top-level
# UI object in the application. See hello2.goc.
#
appobj	TalkApp
#
# Heapspace: This is roughly the non-discardable memory usage (in words)
# of the application and any transient libraries that it depends on,
# plus an additional amount for thread activity. To find the heapspace
# for an application, use the Swat "heapspace" command.
#
heapspace 2866
#
# Libraries: list which libraries are used by the application.
#
library	geos
library	ui
library socket
library netutils noload


#
# Resources: list all resource blocks which are used by the application whose
# allocation flags can't be inferred by Glue. Usually this is needed only for
# object blocks, fixed code resources, or data resources that are read-only.
# Standard discardable code resources do not need to be mentioned.
#
resource AppResource ui-object
resource Interface ui-object

export TalkProcessClass
export TalkThreadClass
export TalkAddressClass
