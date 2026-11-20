name webp.lib

longname "WebP Translator"

tokenchars "TLGR"
tokenid 0

type library, single

entry LibraryEntry

library geos
library impex
library webplib

export TransGetImportUI
export TransGetExportUI
export TransInitImportUI
export TransInitExportUI
export TransGetImportOptions
export TransGetExportOptions
export TransImport
export TransExport
export TransGetFormat
