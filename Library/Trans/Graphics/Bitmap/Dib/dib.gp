##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	
# FILE:		dib.gp
#
# AUTHOR:	Maryann Simmons, Feb 24, 1992
#
#
# 
#
#	$Id: dib.gp,v 1.1 97/04/07 11:29:11 newdeal Exp $
#
##############################################################################
#
#
# Permanent name
#
name dib.lib
#
# Long name
#
longname "Bitmap Metafile Converter"
# DB Token
#
tokenchars "TLD0"
tokenid 0
#
#
# Specify geode type
#
type	library, single
#
#define entry point
#
	
#
# Import library routine definitions
#
library	geos
library	ui
library	ansic
library impex


# Define resources other than standard discardable code
#
nosort
resource ExportCode	read-only code shared
resource ImportCode	read-only code shared
resource DIBCustomErrorStrings	lmem data read-only shared

export ImpexImportGraphicsConvertToTransferItem
export ImpexExportGraphicsConvertToDIBMetafile







