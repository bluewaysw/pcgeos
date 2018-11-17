##############################################################################
#
#	Copyright (c) Geoworks 1990-1994 -- All Rights Reserved
#
# PROJECT:	GEOS
# MODULE:	SubUI
# FILE:		subui.gp
#
# AUTHOR:	Eric E. Del Sesto, June 10, 1991
#
# DESCRIPTION:	This file contains Geode definitions for the "SubUI" sample
#		application. This file is read by the GLUE linker to
#		build this application.
#
#IMPORTANT:
#	This example is written for the GEOS V1.0 API. For the V2.0 API,
#	we have new ObjectAssembly and Object-C versions.
#
# RCS STAMP:
#	$Id: subui.gp,v 1.1 97/04/04 16:32:50 newdeal Exp $
#
##############################################################################
#
# Permanent name: is required by Glue to set the permanent name and extension
# of the geode. The permanent name of a library is what goes in the imported
# library table of a geode (along with the protocol number). It is also
# what Swat uses to name the patient.
#
name subui.app
#
# Long filename: this name can displayed by geoManager, and is used to identify
# the application for inter-application communication.
#
longname "SubUI"
#
# Specify geode type: is an application, will have its own process (thread),
# and is not multi-launchable.
#
type	appl, process
#
# Specify class name for application process. Methods sent to the Application's
# process will be handled by the SubUIGenProcessClass, which is defined
# in subui.asm.
#
class	SubUIGenProcessClass
#
# Specify application object. This is the object in the .ui file which serves
# as the top-level UI object in the application. See subui.ui.
#
appobj	SubUIApp
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
#
# Here we must export our class definition. Basically, this is very similar
# to exporting a library entry point. This is necessary so that when this
# application is shut-down, and its UI objects are saved to a state file,
# the kernel can "unrelocate" any MyTriggerClass class pointers.
#
# Remember, in this application, class pointers are actually far pointers into
# the idata segment. Since this application's idata segment might be at
# a different physical address from session to session, the class pointer
# will also be different from session to session.
#
# So when shutting down this application, the kernel will save any
# MyTriggerClass object in such a way that its class pointer is not a
# far pointer but actually a value which will be relocated when the
# application is restarted.
#
export MyTriggerClass
