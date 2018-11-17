name htmlimpx.lib

longname "HTML Translator"
tokenchars "TLTX"
tokenid 0

platform geos20
exempt htmlpars

type library, single

entry LibraryEntry

library	geos
library ui
library impex
library text
library ansic
library htmlpars

export TransGetImportUI
export TransGetExportUI
export TransInitImportUI
export TransInitExportUI
export TransGetImportOptions
export TransGetExportOptions
export TransImport
export TransExport
export TransGetFormat

