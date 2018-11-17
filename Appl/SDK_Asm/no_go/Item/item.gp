##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC/GEOS
# MODULE:	Item (Sample PC/GEOS application)
# FILE:		item.gp
#
# AUTHOR:	Eric E. Del Sesto, 11/90
#
# DESCRIPTION:	This file contains Geode definitions for the "Item" sample
#		application. This file is read by the GLUE linker to
#		build this application.
#
# RCS STAMP:
#	$Id: item.gp,v 1.1 97/04/04 16:34:29 newdeal Exp $
#
##############################################################################
#
# Permanent name: is required by Glue to set the permanent name and extension
# of the geode. The permanent name of a library is what goes in the imported
# library table of a geode (along with the protocol number). It is also
# what Swat uses to name the patient.
#
name item.app
#
# Long filename: this name can displayed by geoManager, and is used to identify
# the application for inter-application communication.
#
longname "Item"
#
# Specify geode type: is an application, will have its own process (thread),
# and is multi-launchable.
#
type	appl, process
#
# Specify class name for application process. Methods sent to the Application's
# process will be handled by the ItemProcessClass, which is defined
# in item.asm.
#
class	ItemGenProcessClass
#
# Specify application object. This is the object in the .ui file which serves
# as the top-level UI object in the application. See item.ui.
#
appobj	ItemApp
#
# Token: this four-letter name is used by geoManager to locate the icon for this
# application in the database.
#
tokenchars "ILNK"
tokenid 0
#
# Libraries: list which libraries are used by the application.
#
library	geos
library	ui
#
# Code Resources: these are all read-only and sharable by multiple instances
# of this application. The PerfInitCode resource is marked as discard-only,
# so that it will be discarded rather than swapped to XMS/EMS memory.
#
#resource ItemInitCode		code read-only shared discard-only
resource ItemCommonCode		code read-only shared
#
# Resources: list all resource blocks which are used by the application.
# (standard discardable code resources do not need to be mentioned).
#
resource AppResource ui-object
resource Interface ui-object
