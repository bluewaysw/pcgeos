##############################################################################
#
#	Copyright (c) GlobalPC 1999 -- All Rights Reserved
#
# PROJECT:	WAV-file Player Application
# MODULE:	Geode Parameters file
# FILE:		wavplay.gp
#
# AUTHOR:	Don Reeves -- November 5, 1999
#
# DESCRIPTION:
#
# RCS STAMP:
#	$Id: $
#
##############################################################################
#
name wavplay.app
#
longname "WAV-file Player"
#
type	appl, process, single
#
stack	2000
#
class	WavPlayProcessClass
#
appobj	WavPlayApp
#
tokenchars "WVPL"
tokenid 17
#
heapspace 2000
#
library	geos
library	ui
library ansic
library wav
#
# Define resources other than standard discardable code
#
resource AppResource ui-object
resource Interface ui-object
resource AppMonikerResource lmem read-only shared
#
# Define exported entry points (for object saving)
#
export WavPlayApplicationClass
