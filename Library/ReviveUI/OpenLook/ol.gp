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
library	dbase
#
# Desktop-related things
#
longname	"Open Look \xa8 Specific UI"
tokenchars	"SPUI"
tokenid		0
#
# Define resources other than standard discardable code
#
resource AppLCMonikerResource ui-object
resource AppLMMonikerResource ui-object
resource AppSCMonikerResource ui-object
resource AppSMMonikerResource ui-object
resource Init code read-only shared discard-only
resource Resident fixed code read-only
resource DocumentUI ui-object
resource FileSelectorUI ui-object
resource Interface ui-object
resource WindowMenuResource ui-object
resource PopupMenuResource ui-object
resource GCMResource ui-object
resource MDIMenuResource ui-object
resource ExpressMenuResource ui-object
resource StandardDialogUI ui-object
resource DialogStringUI read-only shared lmem
resource PointerData read-only shared lmem
#
# Export routines (must be in same order as ollib.temp?)
#
export OLBuildTrigger
export OLBuildDataTrigger
export OLBuildDisplay
export OLBuildApplication
export OLBuildField
export OLBuildScreen
export OLBuildSystem
export OLBuildPane
export OLBuildPortGroup
export OLBuildPort
export OLBuildRange
export OLBuildInteraction
export OLBuildGlyphDisplay
export OLBuildList
export OLBuildTextDisplay
export OLBuildTextEdit
export OLBuildListEntry
export OLBuildDisplayControl
export OLBuildPrimary
export OLBuildGadget
export OLBuildContent
export OLBuildSpinGadget
export OLBuildUIDocumentControl
export OLBuildAppDocumentControl
export OLBuildDocument
export OLBuildFileSelector
