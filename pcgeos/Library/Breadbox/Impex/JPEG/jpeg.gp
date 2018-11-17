name jpeg.lib

longname "Breadbox Jpeg Translator"
tokenchars "TLGR"
tokenid 0

type library, single

entry LibraryEntry

library	geos
library ui
library impex
library ansic
library ijgjpeg

resource ExportInterface object
resource ASM_FIXED code read-only shared fixed

export TransGetImportUI
export TransGetExportUI
export TransInitImportUI
export TransInitExportUI
export TransGetImportOptions
export TransGetExportOptions
export TransImport
export TransExport
export TransGetFormat

usernotes "Copyright 1994-2002  Breadbox Computer Company LLC  All Rights Reserved"

