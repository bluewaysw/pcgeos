##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	Impex
# MODULE:	Template Translation Library
# FILE:		geodename.gp
#
# AUTHOR: 	Jenny Greenwood, 2 September 1992
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jenny	9/2/92		Initial version
#
# Parameters file for: geodename.geo
#
#	$Id: template.gp,v 1.1 97/04/07 11:40:33 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name geodename.lib
#
# Long name
#
longname "Template Translator"
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
library	ansic
library impex
library msmfile
#
# Define resources other than standard discardable code
#
# Define exported entry points
#
export	TransGetImportUI
export	TransGetExportUI
export	TransGetImportOptions
export	TransGetExportOptions
export	TransImport
export	TransExport
export 	TransGetFormat
