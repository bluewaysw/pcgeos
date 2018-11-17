##############################################################################
#
#	Copyright (c) GeoWorks 1990 -- All Rights Reserved
#
# PROJECT:	PC/GEOS
# MODULE:	VisWinSamp
# FILE:		visSamp.gp
#
# AUTHOR:	Chris Hawley 8/20/91
#
# DESCRIPTION:	This file contains Geode definitions for the "VisWinSamp" sample
#		application. This file is read by the GLUE linker to
#		build this application.
#
#IMPORTANT:
#	This example is written for the PC/GEOS V2.0 API. 
#
# RCS STAMP:
#	$Id: viswinsamp.gp,v 1.1 97/04/04 16:38:12 newdeal Exp $
#
##############################################################################
#
# Permanent name: is required by Glue to set the permanent name and extension
# of the geode. The permanent name of a library is what goes in the imported
# library table of a geode (along with the protocol number). It is also
# what Swat uses to name the patient.
#
name viswinsamp.app
#
# Long filename: this name can displayed by geoManager, and is used to identify
# the application for inter-application communication.
#
longname "VisWinSamp"
#
# Specify geode type: is an application, will have its own process (thread),
# and is not multi-launchable.
#
type	appl, process, single
#
# Specify class name for application process. Methods sent to the Application's
# process will be handled by the VisProcessClass, which is defined
# in visSamp.asm.
#
class	VisWinSampProcessClass
#
# Specify application object. This is the object in the .ui file which serves
# as the top-level UI object in the application. See hello.ui.
#
appobj	VisWinSampApp
#
# Token: this four-letter name is used by geoManager to locate the icon for this
# application in the database.
#
tokenchars "VSMP"
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
resource APPRESOURCE ui-object
resource INTERFACE ui-object

#
# Other classes
#
export	VisWinSampNumberClass
export 	VisWinSampCompClass
export 	VisWinSampContentClass
export	VisWinSampWinClass
