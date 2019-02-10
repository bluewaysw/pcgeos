##############################################################################
#
#	Copyright (c) GeoWorks 1990 -- All Rights Reserved
#
# PROJECT:	GEOS
# MODULE:	GeoFile
# FILE:		geofile.gp
#
# AUTHOR:	Eric E. Del Sesto, 11/90
#
# DESCRIPTION:	This file contains Geode definitions for the "GeoFile" sample
#		application. This file is read by the GLUE linker to
#		build this application.
#
# RCS STAMP:
#	$Id: geofile.gp,v 1.2 97/07/02 10:24:10 newdeal Exp $
#
##############################################################################
#
# Permanent name: is required by Glue to set the permanent name and extension
# of the geode. The permanent name of a library is what goes in the imported
# library table of a geode (along with the protocol number). It is also
# what Swat uses to name the patient.
#
name geofile.app
#
# Long filename: this name can displayed by geoManager, and is used to identify
# the application for inter-application communication.
#
longname "GeoFile"
#
# Specify geode type: is an application, and will have its own process
# (thread).  By the way, it's multi-launchable...
#
type	appl, process
#
# Specify class name for application process. Methods sent to the Application's
# process will be handled by the GeoFileProcessClass, which is defined
# in geofile.asm.
#
class	GeoFileProcessClass
#
# This being a C app, we need more stack space.  Also, we use the
# VERY stack-intensive spreadsheet library, so we need even more.
#
stack	14512

heapspace	40200
#
# Specify application object. This is the object in the .ui file which serves
# as the top-level UI object in the application.
#
appobj	GeoFileApp
#
# Token: this four-letter name is used by geoManager to locate the icon for this
# application in the database.
#
tokenchars "GFIL"
tokenid 0
#
# Libraries: list which libraries are used by the application.
#
library	geos
library	ui
library grobj
library spool
library parse
library cell
library ruler
library spline
library math
library	ssheet
library	text
library	ansic
library bitmap
library ffile
library	impex
#
# Resources: list all resource blocks which are used by the application.
# (standard discardable code resources do not need to be mentioned).
#
resource ApplicationUI ui-object
resource Interface ui-object
resource FileEditViewMenuUI ui-object
resource MenuUI ui-object
resource ToolUI ui-object
resource FieldNavigationOrderUI ui-object
resource RecordSizeUI ui-object
resource QuickSortUI ui-object
resource AdvancedSortUI ui-object
# resource CONTROLLERUI ui-object
# resource ICONAREARESOURCE ui-object
resource DocumentResource object
resource TemplateUI object read-only shared
resource DisplayResource ui-object read-only shared
resource GrObjAttrManager object read-only shared
resource GrObjBody object read-only shared
resource Head object
resource AppIconAreaCMonikerResource lmem read-only shared
resource AppIconAreaAsmMonikerResource lmem read-only shared
resource AppIconAreaRNOCMonikerResource lmem read-only shared
resource APPLCMONIKERRESOURCE lmem read-only shared
resource APPLMMONIKERRESOURCE lmem read-only shared
resource APPYCMONIKERRESOURCE lmem read-only shared
resource APPYMMONIKERRESOURCE lmem read-only shared
resource APPSCMONIKERRESOURCE lmem read-only shared
resource APPSMMONIKERRESOURCE lmem read-only shared
resource APPSCGAMONIKERRESOURCE lmem read-only shared
resource ModifyInterface ui-object
resource ModifyMenuUI ui-object
resource MarkMenuUI ui-object
resource ControlStrings shared, lmem, read-only
resource MarkInterface	ui-object
resource OptionsMenuUI	ui-object
resource UserLevelUI	ui-object
resource LayoutInterface ui-object
resource LayoutMenuUI	ui-object
resource ChooseLayoutDialogUI	ui-object
resource EditLayoutNotesInteractionUI	ui-object
resource RenameLayoutDialogUI	ui-object
resource RecordNavigationOrderBoxUI ui-object
resource MarkOptionsDialogUI	ui-object
resource QuickMarkDialogUI	ui-object

#exported classes
export	GeoFileDocumentClass
export	GeoFileDocControlClass
export	GeoFileFlatFileClass
export	GeoFileApplicationClass
export	TitledGenItemClass
export	GeoFileFieldOrganizerClass
