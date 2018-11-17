##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Draw
# FILE:		geodraw.gp
#
# AUTHOR:	Steve Scholl
#
#
# Parameters file for: draw.geo
#
#	$Id: draw.gp,v 1.3 98/07/20 19:32:33 joon Exp $
#
##############################################################################
#
# Permanent name
#
name draw.app
#
# Long name
#
longname "Artist"
#
# DB Token
#
tokenchars "DP00"
tokenid 0
#
# Large stack (for now)
#
stack 3000
#
# Specify geode type
#
type	appl, process
#
# Specify class name for process
#
class	DrawProcessClass
#
# Specify application object
#
appobj	DrawApp
#
# Import library routine definitions
# Any new libraries must be added at the end or unrelocated class info
# in existing documents will be invalidated.
#
library	ui
library grobj
library spool
library	geos	
library ruler
library bitmap
library spline
library text
library spell
library	convert	noload

# Testing the scan library

#
# Define resources other than standard discardable code
#
resource StringsUI			lmem read-only shared
resource Interface			ui-object
resource FileMenuUI			ui-object
resource EditMenuUI			ui-object
resource OptionsMenuUI			ui-object
resource GeometryMenuUI			ui-object
resource AttributeMenuUI		ui-object
resource PolylineMenuUI			ui-object
resource TextMenuUI			ui-object
resource UserLevelUI			ui-object
resource ToolBarsUI			ui-object
resource DrawAppResource 		ui-object
resource DrawDocumentGroupRes		object
resource DrawDocumentRulerContentResTemp read-only shared object
resource DrawMainResTemp 		read-only shared ui-object	
resource DrawBodyRulerGOAMResTemp 	read-only shared object
resource TemplateWizardUI		read-only shared ui-object
resource DrawHeadRes			object
resource AppLCMonikerResource 		read-only shared lmem
resource AppLMMonikerResource 		read-only shared lmem
resource AppSCMonikerResource 		read-only shared lmem
resource AppSMMonikerResource 		read-only shared lmem
resource AppYCMonikerResource 		read-only shared lmem
resource AppYMMonikerResource 		read-only shared lmem
resource AppSCGAMonikerResource  	read-only shared lmem
resource AppTCMonikerResource 		lmem read-only shared
resource AppTMMonikerResource 		lmem read-only shared
resource AppTCGAMonikerResource 	lmem read-only shared
resource WizardHeaderUI			lmem read-only shared
resource CommonCode                     code shared fixed read-only

#
# Classes stored in document
#

export	DrawGrObjBodyClass
export	DrawApplicationClass


#
# Classes not stored in document
#

export DrawDocumentClass
export DrawDisplayClass
export SubclassedDuplicateControlClass
export SubclassedPasteInsideControlClass
export DrawImportControlClass
export DrawExportControlClass
export DrawTemplateWizardClass
export DrawTemplateImageClass
export DrawTemplateFieldTextClass
export DrawGenDocumentControlClass

