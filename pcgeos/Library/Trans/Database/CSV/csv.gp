##############################################################################
#
#	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Comma Separated Value Translation Library
# FILE:		csv.gp
#
# AUTHOR:	Ted, 3/25/92
#
#
# Parameters file for: csv.geo
#
#	$Id: csv.gp,v 1.1 97/04/07 11:42:55 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name csv.lib
#
# Long name
#
longname "CSV Translator"
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
resource Import		code read-only shared
resource Export		code read-only shared
resource ImportUI	ui-object read-only
resource ExportUI	ui-object read-only
resource FormatStrings	lmem read-only shared
resource Strings	lmem read-only shared
#
# Define resources other than standard discardable code
#
export	TransGetImportUI
export	TransGetExportUI
export	TransInitImportUI
export	TransInitExportUI
export	TransGetImportOptions
export	TransGetExportOptions
export	TransImport
export	TransExport
export	TransGetFormat

export	ImpexMappingControlClass
