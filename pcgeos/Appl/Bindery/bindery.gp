##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Studio
# FILE:		studio.gp
#
# AUTHOR:	Tony, 3/92
#
#
# Parameters file for: studio.geo
#
#	$Id: bindery.gp,v 1.1 97/04/04 14:40:55 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name bindery.app
#
# Long name
#
longname "Bindery"
#
# DB Token
#
tokenchars "ST00"
tokenid 0
usernotes	""

heapspace 36393
stack 4000

#
# Condo is based on Ensemble 2.01, but will be shipped with a new
# text library and grobj library.  Exempt hyperlink and hotspot because
# they are new.
#
#platform upgrade
#exempt text
#exempt hyprlnk
#exempt hotspot
platform geos201
exempt text
exempt hyprlnk
exempt hotspot
#
# Specify geode type
#
type	appl, process, single
#
# Specify class name for process
#
class	StudioProcessClass
#
# Specify application object
#
appobj	StudioApp
#
# Import library routine definitions
#
# libraries that contain objects that are saved
#
library	geos
library	ui
library text
library grobj
library ruler
library bitmap
library hyprlnk
library hotspot
#
# libraries that do not contain objects that are saved
#
library	spool
library impex
library spell
library ssmeta  noload
library convert noload
library compress noload

#
# Define resources other than standard discardable code
#

# Icons
resource AppLCMonikerResource lmem read-only shared
#resource AppLMMonikerResource lmem read-only shared
resource AppSCMonikerResource lmem read-only shared
#resource AppSMMonikerResource lmem read-only shared
#resource AppYCMonikerResource lmem read-only shared
#resource AppYMMonikerResource lmem read-only shared
#resource AppSCGAMonikerResource lmem read-only shared

resource AppTCMonikerResource lmem read-only shared
resource AppTMMonikerResource lmem read-only shared
resource AppTCGAMonikerResource lmem read-only shared

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
resource PlatformUI ui-object

# General UI -- app thread
resource AppDCUI object

# Templates to duplicate -- UI thread
resource DisplayTempUI ui-object read-only shared
resource MPDisplayTempUI ui-object read-only shared
resource HelpTempUI ui-object read-only shared

# Templates to duplicate -- app thread
resource DocumentTempUI object read-only shared
resource MasterPageContentUI object read-only shared
resource BodyRulerTempUI object read-only shared
resource ArticleTempUI object read-only shared
resource MasterPageTempUI object read-only shared

# Templates to duplicate -- data
resource MapBlockTemp lmem read-only shared
resource CharAttrElementTemp lmem read-only shared
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

#
# Our classes
#
# Classes stored in a document
#
export FlowRegionClass
export StudioArticleClass
export StudioGrObjBodyClass
export StudioMasterPageGrObjBodyClass
export StudioHdrFtrGuardianClass
export StudioHdrFtrClass
export StudioGrObjAttributeManagerClass
export WrapFrameClass
#
# Classes not stored in a document
#
export StudioGrObjHeadClass
export StudioDocumentGroupClass
export StudioDocumentClass
export StudioApplicationClass
export StudioDisplayClass
export StudioMainDisplayClass
export StudioMasterPageDisplayClass
export StudioMasterPageContentClass
export StudioLocalPageNameControlClass
