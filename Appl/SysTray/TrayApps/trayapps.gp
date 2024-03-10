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
# icon for this application in the token database.
#
tokenchars "TRAP"
tokenid 0
#
# Specify geode type: This geode is an application, and will have its
# own process (thread).
#
type	appl, process, single
#
# Specify class name for application thread.
#
class	TrayAppsProcessClass
#
# Specify application object. This is the object that serves as the top-level
# UI object in the application.
#
appobj	TrayAppsApp
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
resource AppResource object
resource Templates object

export	TrayAppsApplicationClass
export  TrayAppsInteractionClass
export  GenGeodeTokenTriggerClass

