##############################################################################
#
# PROJECT:	GEOS
# MODULE:	GeoNoid
# FILE:	noid.gp
#
# DESCRIPTION:	This file contains Geode definitions for GeoNoid
#
##############################################################################
#
# Permanent name: This is required by Glue to set the permanent name
# and extension of the geode. The permanent name of a library is what
# goes in the imported library table of a client geode (along with the
# protocol number). It is also what Swat uses to name the patient.
#
name noid.app
#
# Long filename: this name can displayed by GeoManager. "EC " is prepended to
# this when the error-checking version is linked by Glue.
#
longname "GeoNoid"
#
# Token: The four-letter name is used by GeoManager to locate the
# icon for this application in the token database.
#
tokenchars "NOID"
tokenid 16431
#
# Specify geode type: This geode is an application, and will have its
# own process (thread).
#
type	appl, process, single
#
# Specify class name for application thread. Messages sent to the application
# thread (aka "process" when specified as the output of a UI object) will be
# handled by the HelloProcessClass, which is defined in hello.goc.
#
class	NoidProcessClass
#
# Specify application object. This is the object that serves as the top-level
# UI object in the application.
#
appobj	NoidApp

platform gpc12

library	geos
library	ui
library	sound
library game
library color
library ansic

exempt	sound
exempt game
exempt color

#
# Resources: list all resource blocks which are used by the application whose
# allocation flags can't be inferred by Glue. Usually this is needed only for
# object blocks, fixed code resources, or data resources that are read-only.
# Standard discardable code resources do not need to be mentioned.
#
resource AppResource		object
resource Interface		object
resource OptionsInterface	object
resource AppMonikerResource	object
resource BallResource		data read-only
resource OpponentResource	data read-only
resource ScoreBrickResource	data read-only
resource FeatureBrickResource	data read-only
resource StringResource		lmem read-only shared
