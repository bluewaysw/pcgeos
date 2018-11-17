##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC/GEOS
# MODULE:	Hello4 (Sample Asm UI/C implementation)
# FILE:		hello4.gp
#
# AUTHOR:	John D. Mitchell
#
# DESCRIPTION:	This file contains Geode definitions for the "Hello" sample
#		application. This file is read by the GLUE linker to
#		build this application.
#
# RCS STAMP:
#	$Id: hello4.gp,v 1.1 97/04/04 16:38:06 newdeal Exp $
#
##############################################################################
#
# Permanent name: is required by Glue to set the permanent name and extension
# of the geode. The permanent name of a library is what goes in the imported
# library table of a client geode (along with the protocol number). It is also
# what Swat uses to name the patient.
#
name hello.app
#
# Long filename: this name can displayed by GeoManager. "EC " is prepended to
# this when the error-checking version is linked by Glue.
#
longname "Hello ASM UI/C"
#
# Specify geode type: is an application, and will have its own thread started
# for it by the kernel.
#
type	appl, process
#
# Specify class name for application thread. Messages sent to the application
# thread (aka "process" when specified as the output of a UI object) will be
# handled by the HelloProcessClass, which is defined in hello.goc.
#
class	HelloProcessClass
#
# Specify application object. This is the object in the .ui file which serves
# as the top-level UI object in the application. See helloUI.ui.
#
appobj	HelloApp
#
# Token: this four-letter+integer name is used by GeoManager to locate the icon
# for this application in the token database. A tokenid of 0 is known symbolicly
# as MANUFACTURER_ID_GEOWORKS
#
tokenchars "HELO"
tokenid 0
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
resource AppResource ui-object
resource Interface ui-object
