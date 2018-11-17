##############################################################################
#
#	Copyright (c) GeoWorks 1990, 1991 -- All Rights Reserved
#
# PROJECT:	PC/GEOS
# MODULE:	Bounce (Bouncing balls demo)
# FILE:		bounce.gp
#
# AUTHOR:	Tony Requist, Adam de Boor, Eric E. Del Sesto (1990, 1991)
#
# DESCRIPTION:	This file contains Geode definitions for the Bounce application.
#		This file is read by the GLUE linker to build this application.
#
#IMPORTANT:
#	This example is written for the PC/GEOS V1.0 API. For the V2.0 API,
#	we NEED new ObjectAssembly and Object-C versions.
#
# RCS STAMP:
#	$Id: bounce.gp,v 1.1 97/04/04 14:40:59 newdeal Exp $
#
##############################################################################
#
# Permanent name: is required by Glue to set the permanent name and extension
# of the geode. The permanent name of a library is what goes in the imported
# library table of a geode (along with the protocol number). It is also
# what Swat uses to name the patient.
#
name bounce.app
#
# Long filename: this name can displayed by geoManager, and is used to identify
# the application for inter-application communication.
#
longname "Bounce"
#
# Specify geode type: is an application, will have its own process (thread),
# and IS multi-launchable.
#
type	appl, process
#
# Bigger stack for one-thread model
#
stack 3000
#
#
# Specify class name for application process. Methods sent to the Application's
# process will be handled by the BounceProcessClass, which is defined
# in bounce.asm.
#
class	BounceProcessClass
#
# Specify application object. This is the object in the .ui file which serves
# as the top-level UI object in the application. See bounce.ui.
#
appobj	BounceApp
#
# Token: this four-letter name is used by geoManager to locate the icon for this
# application in the database.
#
tokenchars "BONC"
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
resource Interface object
#resource AppSCMonikerResource read-only shared lmem
#resource AppSMMonikerResource read-only shared lmem
#resource AppLCMonikerResource read-only shared lmem
#resource AppLMMonikerResource read-only shared lmem
#resource AppLCGAMonikerResource read-only shared lmem
#resource AppSCGAMonikerResource read-only shared lmem
#
# Define exported entry points (for object saving)
#
