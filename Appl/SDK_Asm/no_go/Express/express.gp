##############################################################################
#
#	Copyright (c) GeoWorks 1990 -- All Rights Reserved
#
# PROJECT:	PC/GEOS
# MODULE:	Express (Express menu sample PC/GEOS application)
# FILE:		express.gp
#
# AUTHOR:	brianc, 3/91
#
# DESCRIPTION:	This file contains Geode definitions for the "Express" sample
#		application. This file is read by the GLUE linker to
#		build this application.
#
# RCS STAMP:
#	$Id: express.gp,v 1.1 97/04/04 16:34:16 newdeal Exp $
#
##############################################################################
#
# Permanent name: is required by Glue to set the permanent name and extension
# of the geode. The permanent name of a library is what goes in the imported
# library table of a geode (along with the protocol number). It is also
# what Swat uses to name the patient.
#
name express.app
#
# Long filename: this name can displayed by geoManager, and is used to identify
# the application for inter-application communication.
#
longname "Express Menu Sample App"
#
# Specify geode type: is an application, will have its own process (thread),
# and is not multi-launchable.
#
type	appl, process
#
# Specify class name for application process. Methods sent to the Application's
# process will be handled by the ExpressProcessClass, which is defined
# in hello.asm.
#
class	ExpressProcessClass
#
# Specify application object. This is the object in the .ui file which serves
# as the top-level UI object in the application. See express.ui.
#
appobj	ExpressApp
#
# Token: this four-letter name is used by geoManager to locate the icon for this
# application in the database.
#
tokenchars "EXPR"
tokenid 0
#
# Libraries: list which libraries are used by the application.
#
library	geos
library	ui
#
# Resources: list all resource blocks which are used by the application.
# (standard discardable code resources do not need to be mentioned).
#
resource AppResource object
resource Interface object read-only shared
resource Strings lmem read-only shared
