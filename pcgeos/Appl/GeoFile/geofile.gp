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
resource APPLICATIONUI ui-object
resource INTERFACE ui-object
resource FILEEDITVIEWMENUUI ui-object
resource MENUUI ui-object
resource TOOLUI ui-object
resource FIELDNAVIGATIONORDERUI ui-object
resource RECORDSIZEUI ui-object
resource QUICKSORTUI ui-object
resource ADVANCEDSORTUI ui-object
# resource CONTROLLERUI ui-object
# resource ICONAREARESOURCE ui-object
resource DOCUMENTRESOURCE object
resource TEMPLATEUI object read-only shared
resource DISPLAYRESOURCE ui-object read-only shared
resource GROBJATTRMANAGER object read-only shared
resource GROBJBODY object read-only shared
resource HEAD object
resource APPICONAREACMONIKERRESOURCE lmem read-only shared
resource AppIconAreaAsmMonikerResource lmem read-only shared
resource APPICONAREARNOCMONIKERRESOURCE lmem read-only shared
resource APPLCMONIKERRESOURCE lmem read-only shared
resource APPLMMONIKERRESOURCE lmem read-only shared
resource APPYCMONIKERRESOURCE lmem read-only shared
resource APPYMMONIKERRESOURCE lmem read-only shared
resource APPSCMONIKERRESOURCE lmem read-only shared
resource APPSMMONIKERRESOURCE lmem read-only shared
resource APPSCGAMONIKERRESOURCE lmem read-only shared
resource MODIFYINTERFACE ui-object
resource MODIFYMENUUI ui-object
resource MARKMENUUI ui-object
resource CONTROLSTRINGS shared, lmem, read-only
resource MARKINTERFACE	ui-object
resource OPTIONSMENUUI	ui-object
resource USERLEVELUI	ui-object
resource LAYOUTINTERFACE ui-object
resource LAYOUTMENUUI	ui-object
resource CHOOSELAYOUTDIALOGUI	ui-object
resource EDITLAYOUTNOTESINTERACTIONUI	ui-object
resource RENAMELAYOUTDIALOGUI	ui-object
resource RECORDNAVIGATIONORDERBOXUI ui-object
resource MARKOPTIONSDIALOGUI	ui-object
resource QUICKMARKDIALOGUI	ui-object

#exported classes
export	GeoFileDocumentClass
export	GeoFileDocControlClass
export	GeoFileFlatFileClass
export	GeoFileApplicationClass
export	TitledGenItemClass
export	GeoFileFieldOrganizerClass
