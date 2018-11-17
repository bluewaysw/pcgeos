##############################################################################
#
#	Copyright (c) GeoWorks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Kernel
# FILE:		bboxui.gp
#
# AUTHOR:	Tony, 10/89
#
#
# Parameters file for: bboxui.geo
#
#	$Id: bboxui.gp,v 1.1 97/04/07 11:03:18 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name bboxui.spui
#
# Specify geode type
#
type	library, single
#
# Define library entry point
#
entry	LibraryEntry
#
# Import kernel routine definitions
#
library	geos
library	ui
library	text
#
# Desktop-related things
#
longname	"Breadbox Specific UI"
tokenchars	"SPUI"
tokenid		0

#
# Define resources other than standard discardable code
#
nosort
resource Resident fixed read-only code
resource Init read-only shared code discard-only preload
resource Build read-only code shared
resource Utils read-only code shared
resource CommonFunctional read-only code shared
resource ListGadgetCommon read-only code shared
resource ItemCommon read-only code shared
resource ItemVeryCommon read-only code shared
resource GadgetCommon read-only code shared
resource DrawColor read-only code shared
resource Geometry read-only code shared
resource ButtonCommon read-only code shared
resource HighCommon read-only code shared
resource DrawBW read-only code shared
resource MDIInit read-only code shared
resource MDICommon read-only code shared
resource WinClasses read-only code shared
resource WinCommon read-only code shared
resource Unbuild read-only code shared
resource AppCommon read-only code shared
resource ActionObscure read-only code shared
resource KbdNavigation read-only code shared
resource GeometryObscure read-only code shared
resource MenuBarBuild read-only code shared
resource MenuBarCommon read-only code shared
resource ViewBuild read-only code shared
resource ViewUncommon read-only code shared
resource ViewCommon read-only code shared
resource Popout read-only code shared
resource WinMethods read-only code shared
resource InstanceObscure read-only code shared
resource SpinGadgetCommon read-only code shared
resource Slider read-only code shared
resource GadgetBuild read-only code shared
resource ItemGeometry read-only code shared
resource ExtendedCommon read-only code shared
resource ScrItemCommon read-only code shared
resource DocInit read-only code shared
resource DocExit read-only code shared
resource DocCommon read-only code shared
resource DocMisc read-only code shared
resource DocNewOpen read-only code shared
resource DocNew read-only code shared
resource DocSaveAsClose read-only code shared
resource DocObscure read-only code shared
resource DocDialog read-only code shared
resource DocError read-only code shared
resource AppAttach read-only code shared
resource AppDetach read-only code shared
resource StandardDialog read-only code shared
resource HighUncommon read-only code shared
resource FileSelector read-only code shared
resource Obscure read-only code shared
resource ViewGeometry read-only code shared
resource ViewScale read-only code shared
resource ScrollbarCommon read-only code shared
resource ScrollbarBitmaps10 read-only code shared
resource ScrollbarBitmaps12 read-only code shared
resource ScrollbarBitmaps8 read-only code shared
resource WinDialog read-only code shared
resource MDIAction read-only code shared
resource WinIconCode read-only code shared
resource WinUncommon read-only code shared
resource Exit read-only code shared
resource FieldBGDraw read-only code shared
resource FieldBG read-only code shared
resource Interface lmem
resource GCMResource lmem
resource StandardDialogUI read-only shared object
resource StandardWindowMenuResource read-only shared object
resource DisplayWindowMenuResource read-only shared object
resource ExpressMenuResource ui-object shared
resource StandardMonikers read-only shared lmem
resource StringsUI read-only shared lmem
resource FileSelectorUI read-only shared object
resource PopoutUI read-only shared object
resource AppTCMonikerResource read-only shared lmem
resource AppTMMonikerResource read-only shared lmem
resource AppTCGAMonikerResource read-only shared lmem
resource OLDocumentControlUI read-only shared object
resource OLDocumentControlToolboxUI read-only shared object
resource ControlStrings read-only shared lmem
resource DocumentDialogUI read-only shared ui-object
resource DocumentNewUI read-only shared ui-object
resource DocumentOpenUI read-only shared ui-object
resource DocumentUseTemplateUI read-only shared ui-object
resource DocumentSaveAsUI read-only shared ui-object
resource DocumentCopyToUI read-only shared ui-object
resource DocumentTypeUI read-only shared ui-object
resource DocumentGetPasswordUI read-only shared ui-object
resource DocumentPasswordUI read-only shared ui-object
resource DocumentQuickBackupUI read-only shared ui-object
resource DocumentProtoProgressUI read-only shared ui-object
resource DrawBitmapOptrSMResource read-only shared lmem
resource DrawBitmapOptrSCGAResource read-only shared lmem
resource DocumentConfirmSaveUI object
resource DocumentUserNotesUI read-only shared ui-object
resource DocumentRenameUI read-only shared ui-object
resource DocumentStringsUI read-only shared lmem
resource AppSCMonikerResource read-only shared lmem
resource AppSMMonikerResource read-only shared lmem
resource AppSCGAMonikerResource read-only shared lmem
resource MonikerExpandUI read-only shared lmem
resource DrawBitmapOptrSCResource read-only shared lmem
resource AppFileSCMonikerResource read-only shared lmem
resource AppFileSMMonikerResource read-only shared lmem
resource AppFileSCGAMonikerResource read-only shared lmem
resource PointerImages read-only shared lmem
resource WinOther code read-only shared
resource AppYMMonikerResource read-only shared lmem
resource LowDiskUI object
resource CtrlBuild read-only code shared
resource MenuSepQuery read-only code shared
resource LessUsedGeometry read-only code shared
resource MenuBuild read-only code shared
resource SListBuild read-only code shared
resource DocDiskFull read-only code shared
resource ViewScroll read-only code shared

resource VisKeyboardCode read-only code shared
resource GenPenInputControlCode	code read-only shared
resource CharTableCode read-only code shared
resource HWRGridCode read-only code shared
resource GenPenInputControlUI object read-only shared
resource GenPenInputControlToolboxUI object read-only shared
resource CharTableStrings lmem read-only shared

ifdef	GP_FULL_EXECUTE_IN_PLACE
resource DrawColorRegions read-only shared
resource DrawBWRegions	read-only shared
resource RegionResourceXIP read-only shared
resource ControlInfoXIP read-only shared
endif
resource CommonUIClassStructures fixed read-only shared

#
# Export routines called by UI, by offset (*must* be first)
#
export OLBuildTrigger
export OLBuildDisplay
export OLBuildApplication
export OLBuildField
export OLBuildScreen
export OLBuildSystem
export OLBuildPane
export OLBuildInteraction
export OLBuildGlyphDisplay
export OLBuildText
export OLBuildDisplayControl
export OLBuildPrimary
export OLBuildGadget
export OLBuildContent
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

skip 1
skip 1      # To skip SysTrayInteractionClass
#export SysTrayInteractionClass

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
