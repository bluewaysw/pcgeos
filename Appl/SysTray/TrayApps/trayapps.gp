##############################################################################
#
# PROJECT:	PC/GEOS Ensemble
# MODULE:	TrayApps
# FILE:		trayapps.gp
#
# AUTHOR:	Konstantin Meyer, 02/01
# reworked in 02/2024ff for the FreeGEOS project
##############################################################################
#
name trayapps.app
#
longname "TrayApps"
#
# Token: The four-letter name is used by GeoManager to locate the
# icon for this application in the token database. The tokenid
# number corresponds to the manufacturer ID of the program's author
# for uniqueness of the token. Since this is a sample application, we
# use the manufacturer ID for the SDK, which is 8.
#
tokenchars "TRAP"
tokenid 0
#
# Specify geode type: This geode is an application, and will have its
# own process (thread).
#
type	appl, process, single
#
# Specify class name for application thread. Messages sent to the application
# thread (aka "process" when specified as the output of a UI object) will be
# handled by the WavyProcessClass, which is defined in wavy.goc.
#
class	TrayAppsProcessClass
#
# Specify application object. This is the object that serves as the top-level
# UI object in the application. See wavy.goc.
#
appobj	TrayAppsApp
#
# Heapspace: This is roughly the non-discardable memory usage (in words)
# of the application and any transient libraries that it depends on,
# plus an additional amount for thread activity. To find the heapspace
# for an application, use the Swat "heapspace" command.
#
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
resource AppResource ui-object
resource Templates ui-object
