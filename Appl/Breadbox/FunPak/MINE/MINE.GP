##############################################################################
#
#       Copyright (c) GeoWorks 1990 -- All Rights Reserved
#
# PROJECT:      PC/GEOS
# MODULE:       Hello (Sample PC/GEOS application)
# FILE:         hello.gp
#
# AUTHOR:       Eric E. Del Sesto, 11/90
#
# DESCRIPTION:  This file contains Geode definitions for the "Hello" sample
#               application. This file is read by the Glue linker to
#               build this application.
#
# RCS STAMP:
#       $Id: hello.gp,v 1.7 92/07/31 22:35:37 adam Exp $
#
##############################################################################
#
# Permanent name: is required by Glue to set the permanent name and extension
# of the geode. The permanent name of a library is what goes in the imported
# library table of a client geode (along with the protocol number). It is also
# what Swat uses to name the patient.
#
name mine.app
#
# Long filename: this name can displayed by GeoManager. "EC " is prepended to
# this when the error-checking version is linked by Glue.
#
longname "Mine Field"
#
# Specify geode type: is an application, and will have its own thread started
# for it by the kernel.
#
type    appl, process, single
#
# Specify class name for application thread. Messages sent to the application
# thread (aka "process" when specified as the output of a UI object) will be
# handled by the HelloProcessClass, which is defined in hello.goc.
#
class   MineProcessClass
#
# Specify application object. This is the object that serves as the top-level
# UI object in the application. See hello.goc.
#
appobj  MineApp
#
# Token: this four-letter+integer name is used by GeoManager to locate the icon
# for this application in the token database. A tokenid of 0 is known symbolicly
# as MANUFACTURER_ID_GEOWORKS
#
tokenchars "MFld"
tokenid 16431
#
# Libraries: list which libraries are used by the application.
#
library geos
library ui
library ansic
#
# Resources: list all resource blocks which are used by the application whose
# allocation flags can't be inferred by Glue. Usually this is needed only for
# object blocks, fixed code resources, or data resources that are read-only.
# Standard discardable code resources do not need to be mentioned.
#
resource APPRESOURCE object
resource INTERFACE object
resource BOOMMONIKERRESOURCE object
resource SNIPMONIKERRESOURCE object
resource INTERFACEDIALOGS1 object
resource INTERFACEDIALOGS2 object
resource INTERFACEDIALOGS3 object
resource INTERFACEVIEWMENU object
resource INTERFACEOPTIONSMENU object
resource INTERFACEDENSITY object
resource INTERFACEFLAGS object
resource INTERFACESCORES object
resource INTERFACEABOUT object
resource STRINGSRESOURCE lmem shared discardable read-only

export MineProcessClass
export MineViewClass
export MineContentClass
export MineTimerClass
export MinePrimaryClass
