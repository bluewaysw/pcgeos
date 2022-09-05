##############################################################################
#
#	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Kernel
# FILE:		ol.gp
#
# AUTHOR:	Tony, 10/89
#
#
# Parameters file for: ol.geo
#
#	$Id: ol.gp,v 1.1 97/04/07 10:56:31 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name openlook.spui
#
# Specify geode type
#
type	library, single
#
# Import kernel routine definitions
#
library	geos
library	ui
#library	dbase
#
# Desktop-related things
#
longname	"Open Look \xa8 Specific UI"
tokenchars	"SPUI"
tokenid		0
#
# Define resources other than standard discardable code
#
#resource AppLCMonikerResource ui-object
#resource AppLMMonikerResource ui-object
resource AppSCMonikerResource ui-object
resource AppSMMonikerResource ui-object
resource Init code read-only shared discard-only
resource Resident fixed code read-only
#resource DocumentUI ui-object
resource FileSelectorUI ui-object
resource Interface ui-object
resource WindowMenuResource ui-object
resource PopupMenuResource ui-object
resource GCMResource ui-object
#resource MDIMenuResource ui-object
resource ExpressMenuResource ui-object
resource StandardDialogUI ui-object
#resource DialogStringUI read-only shared lmem
#resource PointerData read-only shared lmem
resource StringsUI read-only shared lmem
resource FileSelectorUI read-only shared object
resource CommonUIClassStructures fixed read-only shared

#
# Export routines (must be in same order as ollib.temp?)
#
export OLBuildTrigger
#export OLBuildDataTrigger
export OLBuildDisplay
export OLBuildApplication
export OLBuildField
export OLBuildScreen
export OLBuildSystem
export OLBuildPane
#export OLBuildPortGroup
#export OLBuildPort
#export OLBuildRange
export OLBuildInteraction
export OLBuildGlyphDisplay
#export OLBuildList
#export OLBuildTextDisplay
#export OLBuildTextEdit
export OLBuildText
#export OLBuildListEntry
export OLBuildDisplayControl
export OLBuildPrimary
export OLBuildGadget
export OLBuildContent
#export OLBuildSpinGadget
export OLBuildUIDocumentControl
export OLBuildAppDocumentControl
export OLBuildDocument
export OLBuildFileSelector
export OLBuildBooleanGroup
export OLBuildItemGroup
export OLBuildDynamicList
export OLBuildItem
export OLBuildBoolean
export OLBuildValue

#
# exported routines to do specific UI stuff
#
export SpecGetTextKbdBindings
export SpecGetTextPointerImage
export SpecGetDisplayScheme
export SpecDrawTextCursor
export SpecGetDocControlOptions
export SpecGetWindowOptions

#
# Other things the specific UI needs to export
#
export ToolAreaClass
export OLFSDynamicListClass
# see /staff/pcgeos/Include/Internal/specUI.def for why this skip is here
skip 2

#
# This comes after four classes are exported, so the SpecificUIRoutine enum
# defined in ./Include/Internal/specUI.def has to jump four values to
# account for these.  Also, we should (in a fit of common courtesy) define
# unused enums for the classes exported after OLBuildPenInputControl, so
# anyone adding new .gp file entries after us will not have to think about
# this stuff.
#
export OLBuildPenInputControl
# these must be exported because they are in the ui resource built out
# for the PenInputControl.
export NotifyEnabledStateGenViewClass
export VisKeyboardClass
export VisCharTableClass
export VisHWRGridClass
export HWRGridContextTextClass

ifdef PRODUCT_REDWOOD
# Not externally available, so I won't do an incminor, I'll just use the 
# available "skip 1" left over from the keyboard changes.  -cbh
export LauncherInteractionClass
else
skip 1
endif

#
# READ ME:
#
# *DO NOT* use "incminor" in the specific UI's.
# Instead, use the SPUI_PROTO_* constants found in
# Include/Internal/specUI.def. See the explanation there.
#
# If you are adding anything to this .gp file, make the addition
# before this comment, which should remain at the end of the
# file for maximum visibility.
#

#
# XIP-enabled
#
