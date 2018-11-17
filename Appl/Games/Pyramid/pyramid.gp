##############################################################################
#
#	Copyright (c) GeoWorks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Pyramid
# FILE:		pyramid.gp
#
# AUTHOR:	Jon Witort
#
# DESCRIPTION:
#
# RCS STAMP:
#$Id: pyramid.gp,v 1.1 97/04/04 15:15:08 newdeal Exp $
#
##############################################################################
#
# Permanent name: is required by Glue to set the permanent name and extension
# of the geode. The permanent name of a library is what goes in the imported
# library table of a geode (along with the protocol number). It is also
# what Swat uses to name the patient.
#
name pyramid.app
#
# Long filename: this name can displayed by geoManager, and is used to identify
# the application for inter-application communication.
#
longname "Pyramid"
#
# Specify geode type: is an application, will have its own process (thread),
# and is not multi-launchable.
#
type	appl, process, single
#
# Specify heapspace requirement
#
heapspace 3832
#
# Specify class name for application process. Methods sent to the Application's
# process will be handled by the YodaProcessClass, which is defined in yoda.asm.
#
class	PyramidProcessClass
#
# Specify application object. This is the object in the .ui file which serves
# as the top-level UI object in the application. See yoda.ui.
#
appobj	PyramidApp
#
# Token: this four-letter name is used by geoManager to locate the icon for this
# application in the database.
#
tokenchars "PYR!"
tokenid 0
#
# Libraries: list which libraries are used by the application.
#
library	geos
library	ui
library cards
#
# Resources: list all resource blocks which are used by the application.
# (standard discardable code resources can be ommitted).
#
resource AppResource ui-object
resource StuffResource object
resource Interface ui-object

#resource AppLCMonikerResource ui-object read-only shared
#resource AppLMMonikerResource ui-object read-only shared
#resource AppSCMonikerResource ui-object read-only shared
#resource AppSMMonikerResource ui-object read-only shared
#resource AppYCMonikerResource ui-object read-only shared
#resource AppYMMonikerResource ui-object read-only shared
#resource AppSCGAMonikerResource ui-object read-only shared

resource AppMonikerResource ui-object read-only shared

#
# Export classes: list classes which are defined by the application here.
#
export PyramidClass
export PyramidDeckClass
