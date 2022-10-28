##############################################################################
#
#	Copyright (c) Geoworks 1993 -- All Rights Reserved
#
# PROJECT:	Sample Applications
# FILE:		icontest.gp
#
# AUTHOR:	Tom Lester, Dec 27, 1993
#
# REVISION HISTORY:
#       Name    Date            Description
#       ----    ----            -----------
#       TL	12/27/93	Initial version
#	RainerB	4/27/2022	Resource names adjusted for Watcom compatibility
#
# DESCRIPTION:
#
# RCS STAMP
#	$Id: icontest.gp,v 1.1 97/04/04 16:38:26 newdeal Exp $
#
##############################################################################
#
# Permanent name: is required by Glue to set the permanent name and extension
# of the geode. The permanent name of a library is what goes in the imported
# library table of a client geode (along with the protocol number). It is also
# what Swat uses to name the patient.
#
name icontest.app
#
# Long filename: this name can displayed by GeoManager. "EC " is prepended to
# this when the error-checking version is linked by Glue.
#
longname "C Icon Tester"
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
class	IconTestProcessClass
#
# Specify application object. This is the object that serves as the top-level
# UI object in the application. See iconTest.goc.
#
appobj	IconTestApp
#
# Token: this four-letter+integer name is used by GeoManager to locate the icon
# for this application in the token database. A tokenid of 0 is known symbolicly
# as MANUFACTURER_ID_GEOWORKS
#
tokenchars "IcTe"
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
resource AppResource object
resource Interface object
resource IconResource lmem read-only shared
