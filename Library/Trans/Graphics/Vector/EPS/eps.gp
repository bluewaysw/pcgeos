##############################################################################
#
#	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Graphics Translation Library
# FILE:		eps.gp
#
# AUTHOR:	Jim, 2/91
#
#
# Parameters file for: eps.geo
#
#	$Id: eps.gp,v 1.1 97/04/07 11:26:00 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name eps.lib
#
# Long name
#
longname "PostScript Translation Library"
#
# DB Token
#
tokenchars "TLPS"
tokenid 0
#
# Specify geode type
#
type	library, single
#
# Define library entry point
#
entry	TransLibraryEntry
#
# Import kernel routine definitions
#
library	geos
library ui
# library impex

#
nosort
resource FontMapping	read-only code shared
resource ImportCode	read-only code shared
resource ExportCode	read-only code shared
resource ExportText	read-only code shared
resource ExportType3Font	read-only code shared
resource ExportBitmap	read-only code shared
resource ExportArc	read-only code shared
resource ExportPath	read-only code shared
resource ExportUtils	read-only code shared
resource StandardFonts	read-only code shared
resource MoreFonts	read-only code shared
resource PSProlog	read-only code shared
resource PSType3	read-only code shared
resource PSCode		read-only code shared
resource ResidentCode	read-only code shared
resource FormatStrings  lmem shared read-only
# Exported routines (and classes)
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

export	EPSExportLow
export	EPSExportRaw
export	EPSExportHeader
export	EPSExportTrailer
export	EPSExportBeginPage
export	EPSExportEndPage
export	EPSNormalizeFilename

incminor PrintDirectlyToPort

export	EPSExportBitmap
