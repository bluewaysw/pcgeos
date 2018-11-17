##############################################################################
#
#	Copyright (c) GeoWorks 1991 - All Rights Reserved
#
# PROJECT:	
# MODULE:	amateur
# FILE:		amateur.gp
#
# AUTHOR:	Chris Boyke, 2/91
#
#
# Parameters file for: amateur.geo
#
#	$Id: amateur.gp,v 1.1 97/04/04 15:12:17 newdeal Exp $
#
#
#
#
##############################################################################
#
# Permanent name
#
name amateur.app
#
# Long name
#
longname "Amateur Night"
#
# DB Token
#
tokenchars "AMAT"
tokenid 0
#
# Specify geode type
#
type	appl, process, single
#
# Specify class name for process
#
class	AmateurProcessClass
#
# Specify application object
#
appobj	ScudApp
#
# Import library routine definitions
#
library	geos
library	ui
library sound
library game

#
# Define resources other than standard discardable code
#
resource Interface ui-object
resource GameObjects object
resource StringsUI lmem

resource AppSMMonikerResource lmem read-only shared
resource AppLMMonikerResource lmem read-only shared
resource AppSCMonikerResource lmem read-only shared
resource AppLCMonikerResource lmem read-only shared
resource AppSCGAMonikerResource lmem read-only shared
resource AppTCMonikerResource lmem read-only shared


resource ClownLCResource	lmem read-only shared
resource ClownLMResource	lmem read-only shared
resource ClownCGAResource	lmem read-only shared

resource BlasterLCResource	lmem read-only shared
resource BlasterLMResource	lmem read-only shared
resource BlasterCGAResource	lmem read-only shared


# export classes

export AmateurProcessClass
export AmateurContentClass
export ClownClass
export MovableObjectClass
export AmateurPelletClass
export AmateurPeanutClass
export TomatoClass 
export AmateurCloudClass
export BitmapClass
export BlasterClass


