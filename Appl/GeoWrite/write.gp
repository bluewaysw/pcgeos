##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	GeoWrite
# FILE:		geowrite.gp
#
# AUTHOR:	
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	Tony	3/92		Initial version
#	RainerB	12/2023		Renamed to GeoWrite
#
#
# Parameters file for: write.geo
#
#	$Id: write.gp,v 1.4 98/02/17 03:34:29 gene Exp $
#
##############################################################################
#
# Permanent name
#
name write.app
#
# Long name
#
longname "GeoWrite"
#
# DB Token
#
tokenchars "WP00"
tokenid 0
usernotes ""

heapspace 30807
#
# Specify geode type
#
type	appl, process
#
# Specify class name for process
#
class	WriteProcessClass
#
# Specify application object
#
appobj	WriteApp
#
# Import library routine definitions
#
# Any new libraries must be added at the end or unrelocated class info
# in existing documents will be invalidated.
#
library	geos
library	ui
library text
library grobj
library ruler
library bitmap
library spool
library impex
library spell
library styles
library spline
library color

#
# Additional libraries
#

library ssmeta  noload
library convert noload
library compress noload

ifdef _FAX_SUPPORT or _LIMITED_FAX_SUPPORT
library mailbox
endif


#
# Define resources other than standard discardable code
#

# Icons
resource AppLCMonikerResource lmem read-only shared
resource AppLMMonikerResource lmem read-only shared
resource AppSCMonikerResource lmem read-only shared
resource AppSMMonikerResource lmem read-only shared
resource AppYCMonikerResource lmem read-only shared
resource AppYMMonikerResource lmem read-only shared
resource AppSCGAMonikerResource lmem read-only shared

resource AppTCMonikerResource lmem read-only shared
resource AppTMMonikerResource lmem read-only shared
resource AppTCGAMonikerResource lmem read-only shared

resource GeoWriteClassStructures	code shared fixed read-only

# General UI -- UI thread
resource ApplicationUI ui-object
resource PrimaryUI ui-object
resource GraphicToolsUI ui-object
resource GraphicBarUI ui-object
resource FunctionBarUI ui-object
resource StyleBarUI ui-object
resource FileMenuUI ui-object
resource EditMenuUI ui-object
resource ViewMenuUI ui-object
resource OptionsMenuUI ui-object
resource LayoutMenuUI ui-object
resource GraphicsMenuUI ui-object
resource ParagraphMenuUI ui-object
resource CharacterMenuUI ui-object
resource PageSetupUI ui-object
resource PrintUI ui-object
resource LayoutDialogUI ui-object
resource UserLevelUI ui-object
resource PrintUI ui-object
resource HelpEditUI ui-object
resource EditDialogUI ui-object

# General UI -- app thread
resource AppDCUI object

# Templates to duplicate -- UI thread
resource DisplayTempUI ui-object read-only shared
resource MPDisplayTempUI ui-object read-only shared
resource TemplateWizardUI ui-object read-only shared

# Templates to duplicate -- app thread
resource DocumentTempUI object read-only shared
resource MasterPageContentUI object read-only shared
resource BodyRulerTempUI object read-only shared
resource ArticleTempUI object read-only shared
resource MasterPageTempUI object read-only shared

# Templates to duplicate -- data
resource MapBlockTemp lmem read-only shared
resource CharAttrElementTemp lmem read-only shared
resource CharAttrElementTVTemp lmem read-only shared
resource ParaAttrElementUSTemp lmem read-only shared
resource ParaAttrElementMetricTemp lmem read-only shared
resource GraphicElementTemp lmem read-only shared
resource TextStyleTemp lmem read-only shared
resource LineAttrElementTemp lmem read-only shared
resource AreaAttrElementTemp lmem read-only shared
resource GraphicStyleTemp lmem read-only shared
# Templates for Help Editor -- data
resource TypeElementTemp lmem read-only shared
resource NameElementTemp lmem read-only shared

# General data
resource StringsUI lmem read-only shared
resource WizardHeaderUI lmem read-only shared

ifdef DO_PIZZA
#
# pizza resources
#
resource FixedSpacingControlUI ui-object read-only shared
resource RowColumnControlToolboxUI ui-object read-only shared
resource ControlStringUI lmem read-only shared
endif

ifdef	GP_FULL_EXECUTE_IN_PLACE
resource UsabilityTableSeg lmem read-only shared
endif

#
# NewUI resources
#
ifdef  GP_SUPER_IMPEX
resource WriteDCExtraSaveAsUI ui-object
endif

resource WriteCommonCode code shared fixed read-only

#
# Our classes
#
# Classes stored in a document
#
export FlowRegionClass
export WriteArticleClass
export WriteGrObjBodyClass
export WriteMasterPageGrObjBodyClass
export WriteHdrFtrGuardianClass
export WriteHdrFtrClass
export WriteGrObjAttributeManagerClass
export WrapFrameClass
#
# Classes not stored in a document
#
export WriteGrObjHeadClass
export WriteDocumentClass
export WriteApplicationClass
export WriteDisplayClass
export WriteMainDisplayClass
export WriteMasterPageDisplayClass
export WriteMasterPageContentClass
ifdef GPC
export WSpellControlClass
export WSearchReplaceControlClass
endif

ifdef DO_PIZZA
#
#  Controllers for pizza: Fixed spacing controller and Row/Column dislpay:
#
export FixedCharLinePageControlClass
export RowColumnDisplayControlClass
endif

#
# XIP-enabled
#

#
# For the Wizard behavior
#
export WriteDocumentCtrlClass
export WriteTemplateWizardClass
export WriteTemplateImageClass

#
# RTF Batching behavior
#
export WriteTemplateFieldTextClass
ifdef BATCH_RTF
export SuperImpexExportControlClass
export SuperImpexImportControlClass
endif
