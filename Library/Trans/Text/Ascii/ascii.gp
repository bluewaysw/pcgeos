##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	GEOS
# MODULE:	Ascii Translation Library
# FILE:		ascii.gp
#
# AUTHOR: 	Jenny Greenwood, 2 September 1992
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jenny	9/2/92		Initial version
#
# Parameters file for: ascii.geo
#
#	$Id: ascii.gp,v 1.1 97/04/07 11:40:55 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name ascii.lib
#
# Long name
#
longname "Ascii Translator"
#
# DB Token
#
tokenchars "TLTX"
tokenid 0
#
# Specify geode type
#
type	library, single
#
# Define entry point
#
entry	TransLibraryEntry
#
# Import library routine definitions
#
library	geos
library	ui
library	text
#
# Define resources other than standard discardable code
#
nosort
resource ResidentCode	read-only code shared
resource ExportCode	read-only code shared
resource ImportCode	read-only code shared
resource TransCommonCode	read-only code shared
resource FormatStrings	lmem shared read-only
# Define exported entry points
#
export	TransGetImportUI
export	TransGetExportUI
export	TransInitImportUI
export	TransInitExportUI
export	TransGetImportOptions
export	TransGetExportOptions
export	TransImport
export	TransExport
export 	TransGetFormat
