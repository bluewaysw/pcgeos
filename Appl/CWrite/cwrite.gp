##############################################################################
#
#	Copyright (c) Breadbox Computer Company LLC 2004 -- All Rights Reserved
#
# PROJECT:	GEOS32
# MODULE:	CWriter
# FILE:		cwrite.gp
#
# AUTHOR:	jfh, 6/04
#
#
#
##############################################################################
#
# Permanent name
#
name cwrite.app
#
# Long name
#
longname "CWriter"
#
# DB Token
#
tokenchars "WP00"
tokenid 16431

#heapspace 30807
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
#library bitmap
#library spool
#library impex
#library spell
#library styles
#library spline
#library color

#
# Additional libraries
#

#library ssmeta  noload
#library convert noload
#library compress noload


#
# Define resources other than standard discardable code
#

# Icons
#resource AppLCMonikerResource lmem read-only shared
#resource AppTCMonikerResource lmem read-only shared

#resource GeoWriteClassStructures	code shared fixed read-only

# General UI -- UI thread
resource APPLICATIONUI ui-object
resource PRIMARYUI ui-object
resource GRAPHICTOOLSUI ui-object
resource GRAPHICBARUI ui-object
resource FUNCTIONBARUI ui-object
resource STYLEBARUI ui-object
resource FILEMENUUI ui-object
#resource EditMenuUI ui-object
resource VIEWMENUUI ui-object
#resource OptionsMenuUI ui-object
#resource LayoutMenuUI ui-object
#resource GraphicsMenuUI ui-object
#resource ParagraphMenuUI ui-object
#resource CharacterMenuUI ui-object
#resource PageSetupUI ui-object
#resource PrintUI ui-object
#resource LayoutDialogUI ui-object
#resource UserLevelUI ui-object
#resource PrintUI ui-object
#resource HelpEditUI ui-object
#resource EditDialogUI ui-object

# General UI -- app thread
resource APPDCUI object

# Templates to duplicate -- UI thread
resource DISPLAYTEMPUI ui-object read-only shared
#resource MPDisplayTempUI ui-object read-only shared
#resource TemplateWizardUI ui-object read-only shared

# Templates to duplicate -- app thread
resource DOCUMENTTEMPUI object read-only shared
#resource MasterPageContentUI object read-only shared
resource BODYRULERTEMPUI object read-only shared
#resource ArticleTempUI object read-only shared
#resource MasterPageTempUI object read-only shared

# Templates to duplicate -- data
#resource MapBlockTemp lmem read-only shared
#resource CharAttrElementTemp lmem read-only shared
#resource CharAttrElementTVTemp lmem read-only shared
#resource ParaAttrElementUSTemp lmem read-only shared
#resource ParaAttrElementMetricTemp lmem read-only shared
#resource GraphicElementTemp lmem read-only shared
#resource TextStyleTemp lmem read-only shared
#resource LineAttrElementTemp lmem read-only shared
#resource AreaAttrElementTemp lmem read-only shared
#resource GraphicStyleTemp lmem read-only shared

# Templates for Help Editor -- data
#resource TypeElementTemp lmem read-only shared
#resource NameElementTemp lmem read-only shared

# General data
#resource StringsUI lmem read-only shared
#resource WizardHeaderUI lmem read-only shared

#
# NewUI resources
#
#ifdef  GP_SUPER_IMPEX
#resource WriteDCExtraSaveAsUI ui-object
#endif

#resource WriteCommonCode code shared fixed read-only

#
# Our classes
#
# Classes stored in a document
#
#export FlowRegionClass
#export WriteArticleClass
export WriteGrObjBodyClass
#export WriteMasterPageGrObjBodyClass
#export WriteHdrFtrGuardianClass
#export WriteHdrFtrClass
export WriteGrObjAttributeManagerClass
#export WrapFrameClass
#
# Classes not stored in a document
#
#export WriteGrObjHeadClass
export WriteDocumentClass
export WriteApplicationClass
export WriteDisplayClass
export WriteMainDisplayClass
export WriteMasterPageDisplayClass
#export WriteMasterPageContentClass

#
# For the Wizard behavior
#
#export WriteDocumentCtrlClass
#export WriteTemplateWizardClass
#export WriteTemplateImageClass

#
# RTF Batching behavior
#
#export WriteTemplateFieldTextClass
#ifdef BATCH_RTF
#export SuperImpexExportControlClass
#export SuperImpexImportControlClass
#endif

usernotes "Copyright 1994-2004  Breadbox Computer Company LLC  All Rights Reserved"


