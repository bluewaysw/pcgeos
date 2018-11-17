##############################################################################
#
#	Copyright (c) Geoworks 1991 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Audio CD Player
# FILE:		cdplayer.gp
#
# AUTHOR:	Fred Crimi, 5/91
#
# DESCRIPTION:	This file contains Geode definitions for the CD Play
#		application. This file is read by the GLUE linker to
#		build this application.
#
# RCS STAMP:
#	$Id: cdplayer.gp,v 1.1 97/04/04 14:42:33 newdeal Exp $
#
##############################################################################
#
# Permanent name: is required by Glue to set the permanent name and extension
# of the geode. The permanent name of a library is what goes in the imported
# library table of a geode (along with the protocol number). It is also
# what Swat uses to name the patient.
#
name cdplay.app
#
# Long filename: this name can displayed by geoManager, and is used to identify
# the application for inter-application communication.
#
longname "CD Player"
#
# Specify geode type: is an application, will have its own process (thread),
# and is not multi-launchable.
#
type	appl, process, single
#
# Specify class name for application process. Methods sent to the Application's
# process will be handled by the CDProcessClass, which is defined in test.asm.
#
class	CDProcessClass
#
# Specify application object. This is the object in the .ui file which serves
# as the top-level UI object in the application. See cdrom.ui.
#
appobj	CDApp
#
# Token: this four-letter name is used by geoManager to locate the icon for this
# application in the database.
#
tokenchars "CDR0"
tokenid 0
#
# Libraries: list which libraries are used by the application.
#
library	geos
library	ui
library	cdrom
#
# Resources: list all resource blocks which are used by the application.
# (standard discardable code resources can be ommitted).
#
resource AppLCMonikerResource ui-object read-only shared
resource AppLMMonikerResource ui-object read-only shared
resource AppSCMonikerResource ui-object read-only shared
resource AppSMMonikerResource ui-object read-only shared
resource AppLCGAMonikerResource ui-object read-only shared
resource AppSCGAMonikerResource ui-object read-only shared

resource AppResource ui-object
resource Interface ui-object

# Export classes: list classes which are defined by the application here.
#
#example: export MyTriggerClass
