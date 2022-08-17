##############################################################################
#
#	Copyright (c) Geoworks 1993 -- All Rights Reserved
#
# PROJECT:	GEOS
# MODULE:	Serial (Sample GEOS application)
# FILE:		serial.gp
#
# AUTHOR:	John D. Mitchell
#
# REVISION HISTORY:
#       Name    Date            Description
#       ----    ----            -----------
#       JDM		??		        Initial version
#		RainerB	4/27/2022		Resource names adjusted for Watcom compatibility
#
# DESCRIPTION:	This file contains Geode definitions for the "Serial" sample
#		application. This file is read by the GLUE linker to
#		build this application.
#
# RCS STAMP:
#	$Id: serial.gp,v 1.1 97/04/04 16:36:21 newdeal Exp $
#
##############################################################################
#
# Permanent name: is required by Glue to set the permanent name and extension
# of the geode. The permanent name of a library is what goes in the imported
# library table of a geode (along with the protocol number). It is also
# what Swat uses to name the patient.
#
name serial.app
#
# Long filename: this name can displayed by geoManager, and is used to identify
# the application for inter-application communication.
#
longname "C Serial Demo"
#
# Specify geode type: is an application, will have its own process (thread),
# and is not multi-launchable.
#
type	appl, process, single
#
# Specify class name for application process. Methods sent to the Application's
# process will be handled by the SerialProcessClass, which is defined
# in serial.asm.
#
class	SerialDemoProcessClass
#
# Specify application object. This is the object in the .ui file which serves
# as the top-level UI object in the application. 
#
appobj	SerialDemoApp
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
library ansic
library	streamc
#
# Resources: list all resource blocks which are used by the application.
# (standard discardable code resources do not need to be mentioned).
#
resource AppResource	ui-object
resource Interface	ui-object
resource ConstantData	shared, lmem, read-only
#
# Exported Classes
#
export SerialTextDisplayClass

