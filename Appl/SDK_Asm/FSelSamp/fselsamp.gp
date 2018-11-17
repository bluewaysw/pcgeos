##############################################################################
#
#	Copyright (c) Geoworks 1990-1994 -- All Rights Reserved
#
# PROJECT:	GEOS
# MODULE:	FSelSamp (File Selector Sample GEOS application)
# FILE:		fselsamp.gp
#
# AUTHOR:	brianc, 3/91
#
# DESCRIPTION:	This file contains Geode definitions for the "FSelSamp" sample
#		application. This file is read by the GLUE linker to
#		build this application.
#
# RCS STAMP:
#	$Id: fselsamp.gp,v 1.1 97/04/04 16:32:38 newdeal Exp $
#
##############################################################################
#
# Permanent name: is required by Glue to set the permanent name and extension
# of the geode. The permanent name of a library is what goes in the imported
# library table of a geode (along with the protocol number). It is also
# what Swat uses to name the patient.
#
name fselsamp.app
#
# Long filename: this name can displayed by geoManager, and is used to identify
# the application for inter-application communication.
#
longname "File Selector Sample App"
#
# Specify geode type: is an application, will have its own process (thread),
# and is not multi-launchable.
#
type	appl, process
#
# Specify class name for application process. Methods sent to the Application's
# process will be handled by the FSelSampProcessClass, which is defined
# in hello.asm.
#
class	FSelSampProcessClass
#
# Specify application object. This is the object in the .ui file which serves
# as the top-level UI object in the application. See fselsamp.ui.
#
appobj	FSelSampApp
#
# Token: this four-letter name is used by geoManager to locate the icon for this
# application in the database.
#
tokenchars "SAMP"
tokenid 8
#
# Libraries: list which libraries are used by the application.
#
library	geos
library	ui
#
# Resources: list all resource blocks which are used by the application.
# (standard discardable code resources do not need to be mentioned).
#
resource AppResource ui-object
resource Interface ui-object
resource MenuResource ui-object
