##############################################################################
#
#	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Lotus 123 Translation Library
# FILE:		lot123ss.gp
#
# AUTHOR:	Cheng, 10/18/91
#
#
# Parameters file for: Lotus123.geo
#
#	$Id: lot123ss.gp,v 1.1 97/04/07 11:42:03 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name lot123ss.lib
#
# Long name
#
longname "Lotus 123 Translator"
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
library	ansic
library impex
library math
library ssmeta
#
nosort
resource ResidentCode	read-only code shared
resource CommonCode	read-only code shared
resource ImportCode	read-only code shared
#1994-08-09(Tue)TOK ----------------
ifndef DO_PIZZA
resource ExportCode	read-only code shared
endif
#----------------
resource TransCommonCode	read-only code shared
#1994-08-09(Tue)TOK ----------------
ifdef DO_PIZZA
resource FormatStrings		lmem
else
resource ImpexLmemResource	lmem
resource FormatStrings		lmem shared read-only
endif
#----------------
resource ImportUI	ui-object read-only
resource ExportUI	ui-object read-only
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
export  TransGetFormat

