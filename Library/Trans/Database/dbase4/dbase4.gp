##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	dbase IV
# FILE:		dbase4.gp
#
# AUTHOR:	Ted, 10/26/92
#
#
# Parameters file for: dbase4.geo
#
#	$Id: dbase4.gp,v 1.1 97/04/07 11:43:45 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name dbase4.lib
#
# Long name
#
longname "dBase IV Translator"
# DB Token
#
tokenchars "TLSS"
tokenid 0
#
#
# Specify geode type
#
type	library, single
#
#define entry point
#
entry	TransLibraryEntry
#
# Import library routine definitions
#
library	geos
library	ui
library impex
library	ssmeta
#
nosort
resource ResidentCode	code read-only shared
resource CommonCode	code read-only shared
resource TransCommonCode	code read-only shared
resource Import 	code read-only shared
resource Export 	code read-only shared
resource ImportUI	ui-object read-only
resource ExportUI	ui-object read-only
resource FormatStrings	lmem shared read-only
resource Strings	lmem shared read-only
#
# Define resources other than standard discardable code
#
export	TransGetImportUI
export	TransGetExportUI
export  TransInitImportUI
export  TransInitExportUI
export	TransGetImportOptions
export	TransGetExportOptions
export	TransImport
export	TransExport
export  TransGetFormat

export	ImpexMappingControlClass
