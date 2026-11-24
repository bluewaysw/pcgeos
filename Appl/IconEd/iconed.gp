##############################################################################
#
# PROJECT:      Icon Editor
# FILE:         iconed.gp
#
#
# AUTHOR:	Steve Yegge, Sep  2, 1992
#		Ported to GOC and enhanced by RABE-Soft, July 2025 - November 2026
#
##############################################################################


# *************** Information for Glue *************** #

name        iconed.app
type        appl, process, single

# Make the program as downward compatible as possible
platform    geos201

class       IconProcessClass
appobj      IconApp

longname    "Icon Editor"
tokenchars  "ICON"
tokenid     0
usernotes   "Icon Editor - Version 7.0 - English"


# *************** Libraries *************** #

library	geos
library	ansic
library	ui
library	impex
library	grobj
library bitmap

library	bmptools
exempt	bmptools

library	rsftool
exempt	rsftool

library	icmtool
exempt	icmtool



# *************** Resources *************** #

resource	AppResource 	ui-object
resource	Interface 	ui-object
resource	MenuResource 	ui-object
resource	Controllers 	ui-object
resource	Controllers2 	ui-object
resource	DialogResource  ui-object
resource	DialogResource2  ui-object
resource	DialogResource3  ui-object
resource	DialogResource4  ui-object
resource	DialogResource5  ui-object
resource	DialogResource6  ui-object
resource	AddISetDialogResource  		ui-object
resource	TokenImportDialogResource	ui-object
resource	PreviewResource		ui-object
resource	ResizeDialogResource	ui-object

resource	ToolOnlyToolNameString 	lmem read-only shared

resource 	IconEditControlToolUI 	ui-object read-only shared
resource	IconBitmapControlToolUI	ui-object read-only shared

resource	DataResource 	lmem read-only shared
resource	MonikerResource	lmem read-only shared
resource	GraphicResource	lmem read-only shared

resource	DocumentUI 	object
resource	DisplayUI 	object shared read-only


# *************** Exported Classes and Routines *************** #

export  IconApplicationClass
export  IconDBDocumentClass
export	IconDBViewerClass
export  VisISetClass
export	VisIconClass
export	IconViewerClass
export	FatbitsClass
export	OtherContentClass
export  MousePtrViewClass
export  ToolOnlyControlClass
export	PaletteColorItemGroupClass
export 	VisListItemClass
export	VisListContentClass
export	CropContentClass
export  VisResizePreviewClass


# *********** end of file iconed.gp *******************


