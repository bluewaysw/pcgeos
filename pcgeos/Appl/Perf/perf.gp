##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC/GEOS
# MODULE:	Perf (Performance Meter application)
# FILE:		perf.gp
#
# AUTHOR:	Tony Requist, Adam de Boor, Eric E. Del Sesto (1990, 1991)
#
# DESCRIPTION:	This file contains Geode definitions for the Perf application.
#		This file is read by the GLUE linker to build this application.
#
#IMPORTANT:
#	This example is written for the PC/GEOS V1.0 API. For the V2.0 API,
#	we NEED new ObjectAssembly and Object-C versions.
#
# RCS STAMP:
#	$Id: perf.gp,v 1.1 97/04/04 16:26:55 newdeal Exp $
#
##############################################################################
#
# Permanent name: is required by Glue to set the permanent name and extension
# of the geode. The permanent name of a library is what goes in the imported
# library table of a geode (along with the protocol number). It is also
# what Swat uses to name the patient.
#
name perf.app
#
# Long filename: this name can displayed by geoManager, and is used to identify
# the application for inter-application communication.
#
longname "Perf"
#
# Specify geode type: is an application, will have its own process (thread),
# and IS multi-launchable.
#
type	appl, process
#
# Specify class name for application process. Methods sent to the Application's
# process will be handled by the PerfProcessClass, which is defined
# in perf.asm.
#
class	PerfProcessClass
#
# Specify application object. This is the object in the .ui file which serves
# as the top-level UI object in the application. See perf.ui.
#
appobj	PerfApp
#
# Token: this four-letter name is used by geoManager to locate the icon for this
# application in the database.
#
tokenchars "PERF"
tokenid 0
#
# Libraries: list which libraries are used by the application.
#
library	geos
library	ui
library color
#
# Code Resources: these are all read-only and sharable by multiple instances
# of this application. The PerfInitCode resource is marked as discard-only,
# so that it will be discarded rather than swapped to XMS/EMS memory.
#
resource PerfInitCode		code read-only shared discard-only
resource PerfFixedCommonCode	code read-only shared
resource PerfDrawCode		code read-only shared
resource PerfCalcStatCode	code read-only shared
resource PerfUIHandlingCode	code read-only shared
#
# Data resources: PerfProcStrings will be locked by the Perf thread,
# and PerfUIStrings will be locked by the UI thread.
#
#NEED TO CHANGE ATTRIBUTES ON THIS RESOURCE?
resource PerfProcStrings	lmem data read-only shared

#SEEMS OK AS IS:
resource PerfUIStrings		ui-object read-only shared
#
# UI Resources:
#
resource AppResource		ui-object
resource Interface		ui-object
resource SettingsResource	ui-object

resource AppSCMonikerResource	read-only shared lmem
resource AppSMMonikerResource	read-only shared lmem
resource AppLCMonikerResource	read-only shared lmem
resource AppLMMonikerResource	read-only shared lmem
resource AppLCGAMonikerResource	read-only shared lmem
resource AppSCGAMonikerResource	read-only shared lmem

