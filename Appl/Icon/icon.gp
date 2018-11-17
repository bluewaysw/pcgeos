##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	
# FILE:		icon.gp
#
# AUTHOR:	Steve Yegge, Sep  2, 1992
#
#
# 
#
#	$Id: icon.gp,v 1.1 97/04/04 16:06:41 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name icon.app
#
# Long name
#
longname "Icon Editor"
#
# DB Token
#
tokenchars "ICON"
tokenid 0
#
# Specify geode type
#
type	appl, process
#
# Specify class name for process
#
class	IconProcessClass
#
# Specify application object
#
appobj	IconApp

heapspace 50k
#
# Import library routine definitions
# Any new libraries must be added at the end so that unrelocated class info
# in existing documents will be invalidated.
#
library geos
library ui

#
# Define resources other than standard discardable code
#

# General UI -- UI thread
resource IconAppResource 	ui-object
resource PrimaryUI		ui-object
resource FileMenuUI		ui-object
resource EditMenuUI		ui-object
resource OptionsMenuUI		ui-object
resource PreviewDialogUI 	ui-object
resource TokenViewerUI		ui-object
resource ChangeIconUI		ui-object
resource GraphicsMenuUI		ui-object
resource IconStrings		shared lmem data read-only
resource SourceStrings		shared lmem data read-only

resource AppLCMonikerResource ui-object read-only shared
resource AppLMMonikerResource ui-object read-only shared
resource AppSCMonikerResource ui-object read-only shared
resource AppSMMonikerResource ui-object read-only shared
resource AppSCGAMonikerResource ui-object read-only shared
resource AppYCMonikerResource ui-object read-only shared
resource AppYMMonikerResource ui-object read-only shared
resource AppTMMonikerResource ui-object read-only shared
resource AppTCGAMonikerResource ui-object read-only shared

# General UI -- app thread
resource DocUI 			object

# Templates to duplicate -- UI thread
resource DisplayTempUI		ui-object shared read-only

# Templates to duplicate -- app thread
resource DocumentTempUI		object	shared	read-only

# exported classes
export IconBitmapClass
export IconFatbitsClass
export IconApplicationClass
export BMOContentClass
export FormatContentClass
export ColorTriggerClass
export ColorListItemClass
export AddIconInteractionClass
export SmartTextClass
export VisFormatClass
export VisIconClass
export DBViewerClass
export TransformDisplayClass
export TransformFormatDialogClass
export FormatViewInteractionClass
export StopImportTriggerClass
export BMOVisContentClass
export TokenValueClass
export ImportValueClass

