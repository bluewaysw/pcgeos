##############################################################################
#
#	Copyright (c) GeoWorks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Bitmap library
# FILE:		bitmap.gp
#
# AUTHOR:	Jon Witort
#
# DESCRIPTION:
#
# RCS STAMP:
#$Id: bitmap.gp,v 1.1 97/04/04 17:43:25 newdeal Exp $
#
##############################################################################
#
# Permanent name: is required by Glue to set the permanent name and extension
# of the geode. The permanent name of a library is what goes in the imported
# library table of a geode (along with the protocol number). It is also
# what Swat uses to name the patient.
#
name bitmap.lib
#
# Long filename: this name can displayed by geoManager, and is used to identify
# the application for inter-application communication.
#
longname "Bitmap Library"
tokenchars	"BMAP"
tokenid		0
#
# Specify geode type: is a library
#
type	library, single
#
#
# Libraries: list which libraries are used by the application.
#
library	geos
library	ui
#library text
#
#
entry BitmapEntry
#
#
#
# Specify alternate resource flags for anything non-standard
#
nosort

resource BitmapBasicCode 			read-only code shared
resource BitmapEditCode				read-only code shared
resource BitmapObscureEditCode			read-only code shared
resource BitmapSelectionCode			read-only code shared
resource BitmapToolCodeResource 		read-only code shared
resource VisBitmapUIControllerCode 		read-only code shared

resource BitmapTCMonikerResource 		ui-object read-only shared
resource BitmapTMMonikerResource 		ui-object read-only shared
resource BitmapTCGAMonikerResource 		ui-object read-only shared

resource Bitmap_C read-only 			code shared
resource VisBitmapToolControlToolboxUI 		ui-object read-only shared
resource VisBitmapControlUIStrings 		lmem data read-only shared
resource VisBitmapFormatControlUI 		ui-object read-only shared
resource FatbitsInteractionAndViewTemplate 	ui-object read-only shared
resource FatbitsAndContentTemplate 		object read-only shared
resource BitmapUndoStrings 			lmem read-only shared	
resource PointerImages 				read-only shared lmem
resource BitmapClassStructures			fixed read-only shared

ifdef GP_FULL_EXECUTE_IN_PLACE
resource BitmapControlInfoXIP			read-only shared
endif

#
# Export classes: list classes which are defined by the library here.
#
export VisBitmapClass
export BitmapBackupProcessClass
#export VisTextForBitmapsClass
export ToolClass
export DragToolClass
export LineToolClass
export RectToolClass
export DrawRectToolClass
export EllipseToolClass
export DrawEllipseToolClass
export PencilToolClass
export EraserToolClass
export FloodFillToolClass
#export TextToolClass
export SelectionToolClass
export VisFatbitsClass
export FatbitsToolClass

export VisBitmapToolControlClass
export VisBitmapToolItemClass
export VisBitmapFormatControlClass

#
#	Routines
#
export ToolGrabMouse
export ToolSendAllPtrEvents
export ToolReleaseMouse
export ToolCallBitmap

export DrawBitmapToGState

# added some new stuff, lets hear it for backwards compatibility
incminor

# lets publish these babies so all platforms get this wonderful functionaliy
publish TOOLGRABMOUSE
publish TOOLSENDALLPTREVENTS
publish TOOLRELEASEMOUSE
#publish TOOLCALLBITMAP NOT SUPPORTED
publish DRAWBITMAPTOGSTATE
#
# XIP-enabled
#





