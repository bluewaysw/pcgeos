name xjpeg.lib

longname "XJpeg Translator"
tokenchars "TLGR"
tokenid 0

type library, single

entry LibraryEntry

library	geos
library ui
library impex
library ansic
library fjpeg

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

