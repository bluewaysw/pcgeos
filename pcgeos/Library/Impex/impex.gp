##############################################################################
#
#	Copyright (c) GeoWorks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Kernel
# FILE:		impex.gp
#
# AUTHOR:	jimmy, 3/91	
#
#
# Parameters file for: impex.geo
#
#	$Id: impex.gp,v 1.1 97/04/05 00:50:33 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name impex.lib
#
# Long name
#
longname "Impex Library"
tokenchars	"IMPX"
tokenid		0
#
# Specify geode type
#
type	library, single
#
# Define library entry point
#
entry	ImpexLibraryEntry
#
# Import library definitions
#
library	geos
library ui
#
# Define resources other than standard discardable code
#
nosort
resource ResidentCode		code shared fixed read-only
resource ProcessCode		code read-only shared
resource ImpexUICode		code read-only shared
resource ImpexCode		code read-only shared
resource ErrorCode		code read-only shared
resource MapControlCode		code read-only shared
resource FormatListCode		code read-only shared
resource Strings 		lmem data read-only shared		 
resource ControllerStrings	lmem data read-only shared


resource TransErrorStrings	lmem shared read-only
resource ImpexMapControlUI 	ui-object read-only shared 

resource ExportNotifyUI		ui-object read-only shared
resource ImportNotifyUI		ui-object read-only shared

resource ImportControlUI	ui-object read-only shared
resource ImportToolboxUI	ui-object read-only shared
resource ExportControlUI	ui-object read-only shared
resource ExportToolboxUI	ui-object read-only shared

#resource DefaultMonikerUI	lmem data read-only shared

resource ImpexClassStructures	code shared fixed read-only 

ifdef GP_FULL_EXECUTE_IN_PLACE
resource ImpexControlInfoXIP               read-only shared
endif

#
# Exported routines (and classes)
#
export 	ImpexThreadProcessClass
export  FormatListClass
export	ImportExportClass
export	ImportControlClass
export	ExportControlClass
export	ImpexMapControlClass

export  ImpexCreateTempFile
export  ImpexDeleteTempFile
export  ImpexImportFromMetafile
export  ImpexExportToMetafile
export	ImpexUpdateImportExportStatus
export	ImpexImportExportCompleted
#
# Export C routines
#
export	IMPEXCREATETEMPFILE
export	IMPEXDELETETEMPFILE
export	IMPEXIMPORTFROMMETAFILE
export	IMPEXEXPORTTOMETAFILE
export	IMPEXUPDATEIMPORTEXPORTSTATUS
export	IMPEXIMPORTEXPORTCOMPLETED
#
# Post 2.0 release
#
incminor 
export	MaskTextClass

#
# XIP-enabled
#

#
# MSG_IMPORT_EXPORT_OPERATION_COMPLETED	addition
#
# Also added MSG_IMPORT_CONTROL_AUTO_DETECT_FILE_FORMAT and
# ATTR_IMPORT_EXPORT_HIDE_ERRORS -dhunter 10/13/00
#
incminor ImpexOpCompleted
