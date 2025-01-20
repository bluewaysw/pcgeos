name htmlimpx.lib

longname "HTML Translator"
tokenchars "TLTX"
tokenid 0

type library, single

entry LibraryEntry

library	geos
library ui
library impex
library text
library ansic
library html4par

export TransGetImportUI
export TransGetExportUI
export TransInitImportUI
export TransInitExportUI
export TransGetImportOptions
export TransGetExportOptions
export TransImport
export TransExport
export TransGetFormat

