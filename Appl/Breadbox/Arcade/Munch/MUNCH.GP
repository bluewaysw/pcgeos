##############################################################################
#
#
# MODULE:       Muncher's TNT
# FILE:         munch.gp
#
# DESCRIPTION:  This file contains Geode definitions for Muncher's TNT
#
##############################################################################
#
# Permanent name: This is required by Glue to set the permanent name
# and extension of the geode. The permanent name of a library is what
# goes in the imported library table of a client geode (along with the
# protocol number). It is also what Swat uses to name the patient.
#
name munch.app
#
# Long filename: this name can displayed by GeoManager. "EC " is prepended to
# this when the error-checking version is linked by Glue.
#
longname "Muncher's TNT"
#
# Token: The four-letter name is used by GeoManager to locate the
# icon for this application in the token database.
#
tokenchars "Mun1"
tokenid 16431
#
# Specify geode type: This geode is an application, and will have its
# own process (thread).
#
type    appl, process, single
#
# Specify class name for application thread. Messages sent to the application
# thread (aka "process" when specified as the output of a UI object) will be
# handled by the HelloProcessClass, which is defined in hello.goc.
#
class   MunchProcessClass
#
# Specify application object. This is the object that serves as the top-level
# UI object in the application.
#
appobj  MunchApp

platform geos201
#platform gpc12

heapspace 3k

library geos
library ui
library math
library sound
library color
library game

exempt color
exempt game
exempt math
exempt sound
exempt borlandc

#
# Resources: list all resource blocks which are used by the application whose
# allocation flags can't be inferred by Glue. Usually this is needed only for
# object blocks, fixed code resources, or data resources that are read-only.
# Standard discardable code resources do not need to be mentioned.
#
resource APPRESOURCE object
resource INTERFACE object
#resource SOUNDOPTIONSINTERFACE object
resource ENDEINTERFACE object
resource APPMONIKERRESOURCE ui-object #war: data read-only
resource SPRITERESOURCE data read-only
resource GEGNERRESOURCE data read-only
resource GEGNERRESOURCE2 data read-only
resource KASTENRESOURCE data read-only
#resource POINTERRESOURCE data read-only
resource HINTERGRRESOURCE data read-only
resource MOREBILDERRESOURCE data read-only
resource EXTRASRESOURCE data read-only
#resource NAMEINTERFACE object
#resource SCORESINTERFACE object
resource MUELLINTERFACE object
resource QTIPSRESOURCE object
